"""
DailyMemory - Weekly Life Report DAG
Generates AI-powered weekly summary for each user
Schedule: Every Sunday 09:00 UTC
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
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}


def generate_weekly_reports():
    from modules.dailymemory.db import (
        get_firestore, get_openai, fetch_user_ids,
        fetch_user_memories, fetch_user_persons,
        store_report, send_push,
    )

    db = get_firestore()
    openai = get_openai()
    user_ids = fetch_user_ids()
    week_ago = datetime.utcnow() - timedelta(days=7)

    for user_id in user_ids:
        try:
            memories = fetch_user_memories(db, user_id, since_date=week_ago)
            persons = fetch_user_persons(db, user_id)

            if not memories:
                continue

            # Build stats
            people_mentioned = set()
            locations = set()
            total_amount = 0
            categories = {}

            for m in memories:
                for p in m.get('extractedPersons', []):
                    people_mentioned.add(p)
                loc = m.get('extractedLocation')
                if loc:
                    locations.add(loc)
                amt = m.get('extractedAmount')
                if amt:
                    total_amount += amt
                cat = m.get('category', 'GENERAL')
                categories[cat] = categories.get(cat, 0) + 1

            # Find stale relationships
            stale_persons = []
            for p in persons:
                last_meeting = p.get('lastMeetingDate')
                if last_meeting:
                    if hasattr(last_meeting, 'timestamp'):
                        last_dt = last_meeting
                    else:
                        last_dt = last_meeting
                    days_ago = (datetime.utcnow() - last_dt.replace(tzinfo=None)).days if hasattr(last_dt, 'replace') else 999
                    if days_ago >= 30:
                        stale_persons.append({'name': p.get('name', ''), 'days': days_ago})

            # Generate AI summary
            stats_text = f"""
Weekly stats for this user:
- {len(memories)} memories recorded
- People mentioned: {', '.join(people_mentioned) if people_mentioned else 'none'}
- Locations visited: {', '.join(locations) if locations else 'none'}
- Total amounts mentioned: ${total_amount:.0f}
- Categories: {', '.join(f'{k}: {v}' for k, v in categories.items())}
- People not contacted in 30+ days: {', '.join(f"{p['name']} ({p['days']}d)" for p in stale_persons) if stale_persons else 'none'}

Memory contents (last 5):
"""
            for m in memories[:5]:
                content = m.get('content', '')[:200]
                stats_text += f"- {content}\n"

            response = openai.chat.completions.create(
                model='gpt-4o-mini',
                messages=[{
                    'role': 'user',
                    'content': f"""Generate a friendly, concise weekly life report based on these stats.
Include: summary, highlights, relationship reminders, and one encouraging insight.
Keep it under 200 words. Use a warm, personal tone.

{stats_text}"""
                }],
                temperature=0.7,
                max_tokens=400,
            )

            report = response.choices[0].message.content

            # Store report
            store_report(db, user_id, 'weekly', {
                'report': report,
                'stats': {
                    'memoryCount': len(memories),
                    'peopleMentioned': list(people_mentioned),
                    'locations': list(locations),
                    'totalAmount': total_amount,
                    'categories': categories,
                    'stalePersons': stale_persons,
                },
                'weekStart': (datetime.utcnow() - timedelta(days=7)).isoformat(),
                'weekEnd': datetime.utcnow().isoformat(),
            })

            # Send push
            first_line = report.split('\n')[0][:100]
            send_push(user_id, 'Your Weekly Report', first_line)

            print(f"Weekly report generated for user {user_id[:8]}...")

        except Exception as e:
            print(f"Error for user {user_id[:8]}...: {e}")
            continue


with DAG(
    'dm_weekly_report',
    default_args=default_args,
    description='DailyMemory - Weekly life report with AI summary',
    schedule='0 9 * * 0',  # Sunday 09:00 UTC
    start_date=datetime(2026, 4, 6),
    catchup=False,
    tags=['dailymemory'],
) as dag:

    task = PythonOperator(
        task_id='generate_weekly_reports',
        python_callable=generate_weekly_reports,
    )
