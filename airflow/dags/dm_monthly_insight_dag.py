"""
DailyMemory - Monthly Insight Report DAG
Generates comprehensive monthly analysis with trends and AI insights
Schedule: 1st of every month 09:00 UTC
"""
import sys
sys.path.insert(0, '/opt/airflow')

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from collections import Counter

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}


def generate_monthly_insights():
    from modules.dailymemory.db import (
        get_firestore, get_openai, fetch_user_ids,
        fetch_user_memories, fetch_user_persons,
        store_report, send_push,
    )

    db = get_firestore()
    openai = get_openai()
    user_ids = fetch_user_ids()

    now = datetime.utcnow()
    # Current month stats
    month_start = now.replace(day=1, hour=0, minute=0, second=0)
    # Previous month for comparison
    prev_month_end = month_start - timedelta(seconds=1)
    prev_month_start = prev_month_end.replace(day=1, hour=0, minute=0, second=0)

    for user_id in user_ids:
        try:
            this_month = fetch_user_memories(db, user_id, since_date=prev_month_start)
            persons = fetch_user_persons(db, user_id)

            # Split into current and previous month
            current = [m for m in this_month
                       if m.get('recordedAt') and
                       (m['recordedAt'].replace(tzinfo=None) if hasattr(m['recordedAt'], 'replace') else m['recordedAt']) >= month_start]
            previous = [m for m in this_month if m not in current]

            if not current and not previous:
                continue

            # Stats
            people_counter = Counter()
            location_counter = Counter()
            category_counter = Counter()
            total_amount = 0
            new_persons = []

            for m in current:
                for p in m.get('extractedPersons', []):
                    people_counter[p] += 1
                loc = m.get('extractedLocation')
                if loc:
                    location_counter[loc] += 1
                cat = m.get('category', 'GENERAL')
                category_counter[cat] += 1
                amt = m.get('extractedAmount')
                if amt:
                    total_amount += amt

            # Find newly added persons this month
            for p in persons:
                created = p.get('createdAt')
                if created:
                    try:
                        created_dt = created.replace(tzinfo=None) if hasattr(created, 'replace') else created
                        if created_dt >= month_start:
                            new_persons.append(p.get('name', ''))
                    except:
                        pass

            # Stale relationships
            stale = []
            for p in persons:
                last = p.get('lastMeetingDate')
                if last:
                    try:
                        last_dt = last.replace(tzinfo=None) if hasattr(last, 'replace') else last
                        days = (now - last_dt).days
                        if days >= 30:
                            stale.append(f"{p.get('name', '')} ({days}d)")
                    except:
                        pass

            # Comparison
            change_pct = 0
            if previous:
                change_pct = ((len(current) - len(previous)) / max(len(previous), 1)) * 100

            # Build stats summary
            month_name = prev_month_end.strftime('%B %Y')  # Previous month's name
            stats_text = f"""
Monthly stats for {month_name}:
- Total memories: {len(current)} ({'+' if change_pct >= 0 else ''}{change_pct:.0f}% vs previous month)
- Most mentioned people: {', '.join(f'{k} ({v}x)' for k, v in people_counter.most_common(5))}
- Top locations: {', '.join(f'{k} ({v}x)' for k, v in location_counter.most_common(3))}
- Categories: {', '.join(f'{k}: {v}' for k, v in category_counter.most_common())}
- Financial mentions: ${total_amount:.0f}
- New people met: {', '.join(new_persons) if new_persons else 'none'}
- Longest no-contact: {', '.join(stale[:3]) if stale else 'none'}
- Average: {len(current) / 4:.1f} memories per week
"""

            # Generate AI insight
            response = openai.chat.completions.create(
                model='gpt-4o-mini',
                messages=[{
                    'role': 'user',
                    'content': f"""Generate a monthly life insight report based on these stats.
Include: 1) Overall summary, 2) Highlights, 3) Relationship health, 4) One actionable suggestion.
Keep it under 250 words. Warm, encouraging tone.

{stats_text}"""
                }],
                temperature=0.7,
                max_tokens=500,
            )

            report = response.choices[0].message.content

            # Store
            store_report(db, user_id, 'monthly', {
                'report': report,
                'stats': {
                    'memoryCount': len(current),
                    'previousCount': len(previous),
                    'changePct': change_pct,
                    'topPeople': dict(people_counter.most_common(5)),
                    'topLocations': dict(location_counter.most_common(3)),
                    'categories': dict(category_counter),
                    'totalAmount': total_amount,
                    'newPersons': new_persons,
                    'staleRelationships': stale[:5],
                },
                'month': month_name,
            })

            send_push(user_id, f'{month_name} Insight', report.split('\n')[0][:100])
            print(f"Monthly insight generated for user {user_id[:8]}...")

        except Exception as e:
            print(f"Error for user {user_id[:8]}...: {e}")
            continue


with DAG(
    'dm_monthly_insight',
    default_args=default_args,
    description='DailyMemory - Monthly insight report with trends and AI analysis',
    schedule='0 9 1 * *',  # 1st of month 09:00 UTC
    start_date=datetime(2026, 4, 6),
    catchup=False,
    tags=['dailymemory'],
) as dag:

    task = PythonOperator(
        task_id='generate_monthly_insights',
        python_callable=generate_monthly_insights,
    )
