"""
DailyMemory - Shared database utilities for Airflow DAGs
Connects to shared-db (192.168.50.201) PostgreSQL + Redis
"""
import os
import psycopg2
import psycopg2.extras
import redis
import json
from datetime import datetime, timedelta


def get_db_conn():
    return psycopg2.connect(
        host=os.getenv('POSTGRES_HOST', '192.168.50.201'),
        port=int(os.getenv('POSTGRES_PORT', 5432)),
        dbname='dailymemory',
        user=os.getenv('POSTGRES_USER', 'app_user'),
        password=os.getenv('POSTGRES_PASSWORD'),
    )


def get_redis():
    return redis.Redis(
        host=os.getenv('REDIS_HOST', '192.168.50.201'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        password=os.getenv('REDIS_PASSWORD'),
        decode_responses=True,
    )


def get_firestore():
    """Get Firestore client using firebase-admin"""
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        cred_path = os.getenv(
            'FIREBASE_SERVICE_ACCOUNT',
            '/opt/airflow/secrets/firebase-service-account.json'
        )
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

    return firestore.client()


def get_fcm():
    """Get FCM messaging client"""
    from firebase_admin import messaging
    # Ensure firebase is initialized
    get_firestore()
    return messaging


def get_openai():
    """Get OpenAI client"""
    from openai import OpenAI
    return OpenAI(api_key=os.getenv('OPENAI_API_KEY'))


def fetch_user_ids():
    """Fetch all user Firebase UIDs from user_profiles table"""
    conn = get_db_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT firebase_uid FROM user_profiles")
            return [row[0] for row in cur.fetchall()]
    finally:
        conn.close()


def fetch_user_memories(firestore_db, user_id, since_date=None):
    """Fetch memories for a user from Firestore"""
    ref = firestore_db.collection('users').document(user_id).collection('memories')
    query = ref.order_by('recordedAt', direction='DESCENDING')

    if since_date:
        query = query.where('recordedAt', '>=', since_date)

    docs = query.stream()
    memories = []
    for doc in docs:
        data = doc.to_dict()
        data['id'] = doc.id
        memories.append(data)
    return memories


def fetch_user_persons(firestore_db, user_id):
    """Fetch all persons for a user from Firestore"""
    ref = firestore_db.collection('users').document(user_id).collection('persons')
    docs = ref.stream()
    persons = []
    for doc in docs:
        data = doc.to_dict()
        data['id'] = doc.id
        persons.append(data)
    return persons


def fetch_user_reminders(firestore_db, user_id):
    """Fetch active reminders for a user from Firestore"""
    ref = firestore_db.collection('users').document(user_id).collection('reminders')
    query = ref.where('isActive', '==', True)
    docs = query.stream()
    reminders = []
    for doc in docs:
        data = doc.to_dict()
        data['id'] = doc.id
        reminders.append(data)
    return reminders


def send_push(user_id, title, body):
    """Send FCM push notification to a user's topic"""
    fcm = get_fcm()
    # Send to user-specific topic
    message = fcm.Message(
        notification=fcm.Notification(title=title, body=body),
        topic=f'user_{user_id}',
    )
    try:
        fcm.send(message)
        print(f"Push sent to user {user_id[:8]}...: {title}")
    except Exception as e:
        print(f"Push failed for {user_id[:8]}...: {e}")


def store_report(firestore_db, user_id, report_type, content):
    """Store a report in Firestore"""
    ref = firestore_db.collection('users').document(user_id).collection('reports')
    ref.add({
        'type': report_type,
        'content': content,
        'createdAt': datetime.utcnow(),
        'read': False,
    })
