"""
DailyMemory - On This Day DAG
Finds memories from exactly 1, 2, 3... years ago and sends push
Schedule: Daily 07:00 UTC
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


def find_on_this_day():
    from modules.dailymemory.db import (
        get_firestore, fetch_user_ids, send_push, store_report,
    )

    db = get_firestore()
    user_ids = fetch_user_ids()
    today = datetime.utcnow()

    for user_id in user_ids:
        try:
            memories_ref = db.collection('users').document(user_id).collection('memories')
            found_memories = []

            # Check 1-5 years ago
            for years_ago in range(1, 6):
                target_date = today.replace(year=today.year - years_ago)
                start = target_date.replace(hour=0, minute=0, second=0)
                end = target_date.replace(hour=23, minute=59, second=59)

                docs = (memories_ref
                        .where('recordedAt', '>=', start)
                        .where('recordedAt', '<=', end)
                        .stream())

                for doc in docs:
                    data = doc.to_dict()
                    data['id'] = doc.id
                    data['yearsAgo'] = years_ago
                    found_memories.append(data)

            if not found_memories:
                continue

            # Pick the best one (prefer with photos, then most recent year)
            best = sorted(found_memories, key=lambda m: (
                len(m.get('photos', [])) > 0,  # has photos first
                -m['yearsAgo'],  # most recent year first
            ), reverse=True)[0]

            content = best.get('content', '')[:100]
            years = best['yearsAgo']
            year_text = f"{years} year{'s' if years > 1 else ''} ago"

            # Store for app to display
            store_report(db, user_id, 'on_this_day', {
                'memoryId': best['id'],
                'yearsAgo': years,
                'content': content,
                'date': today.isoformat(),
            })

            # Send push
            send_push(
                user_id,
                f'On This Day ({year_text})',
                content + '...' if len(best.get('content', '')) > 100 else content,
            )

            print(f"User {user_id[:8]}...: found {len(found_memories)} memories on this day")

        except Exception as e:
            print(f"Error for user {user_id[:8]}...: {e}")
            continue


with DAG(
    'dm_on_this_day',
    default_args=default_args,
    description='DailyMemory - On This Day memory notifications',
    schedule='0 7 * * *',  # Daily 07:00 UTC
    start_date=datetime(2026, 4, 6),
    catchup=False,
    tags=['dailymemory'],
) as dag:

    task = PythonOperator(
        task_id='find_on_this_day',
        python_callable=find_on_this_day,
    )
