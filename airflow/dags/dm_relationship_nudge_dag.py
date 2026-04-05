"""
DailyMemory - Relationship Nudge DAG
Detects stale relationships and sends push notifications
Schedule: Daily 09:00 UTC
"""
import sys
sys.path.insert(0, '/opt/airflow')

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

WARN_DAYS = 30
CRITICAL_DAYS = 60
MAX_NUDGES_PER_DAY = 2


def check_relationships():
    from modules.dailymemory.db import (
        get_firestore, fetch_user_ids, fetch_user_persons, send_push,
    )

    db = get_firestore()
    user_ids = fetch_user_ids()
    now = datetime.utcnow()

    for user_id in user_ids:
        try:
            persons = fetch_user_persons(db, user_id)
            stale = []

            for p in persons:
                name = p.get('name', '')
                last_meeting = p.get('lastMeetingDate')
                relationship = p.get('relationship', 'OTHER')

                if not last_meeting:
                    continue

                # Convert Firestore timestamp
                if hasattr(last_meeting, 'timestamp'):
                    last_dt = last_meeting.replace(tzinfo=None) if hasattr(last_meeting, 'replace') else datetime.utcnow()
                else:
                    last_dt = last_meeting

                try:
                    days_since = (now - last_dt.replace(tzinfo=None)).days
                except:
                    continue

                if days_since >= WARN_DAYS:
                    # Priority: FAMILY > FRIEND > others
                    priority = {
                        'FAMILY': 3, 'FRIEND': 2, 'COLLEAGUE': 1,
                    }.get(relationship, 0)

                    stale.append({
                        'name': name,
                        'days': days_since,
                        'relationship': relationship,
                        'priority': priority,
                        'critical': days_since >= CRITICAL_DAYS,
                    })

            # Sort by priority (family first) then by days
            stale.sort(key=lambda x: (-x['priority'], -x['days']))

            # Send max N nudges per user
            for person in stale[:MAX_NUDGES_PER_DAY]:
                if person['critical']:
                    title = f"Missing {person['name']}"
                    body = f"It's been {person['days']} days since you last met {person['name']}. Reach out today?"
                else:
                    title = f"Catch up with {person['name']}?"
                    body = f"You haven't seen {person['name']} in {person['days']} days."

                send_push(user_id, title, body)

            if stale:
                print(f"User {user_id[:8]}...: {len(stale)} stale, sent {min(len(stale), MAX_NUDGES_PER_DAY)} nudges")

        except Exception as e:
            print(f"Error for user {user_id[:8]}...: {e}")
            continue


with DAG(
    'dm_relationship_nudge',
    default_args=default_args,
    description='DailyMemory - Daily relationship nudge notifications',
    schedule='0 9 * * *',  # Daily 09:00 UTC
    start_date=datetime(2026, 4, 6),
    catchup=False,
    tags=['dailymemory'],
) as dag:

    task = PythonOperator(
        task_id='check_relationships',
        python_callable=check_relationships,
    )
