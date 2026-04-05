# DailyMemory - Airflow 기반 고도화 계획

> 기존 Airflow 인프라 (VM 103, 192.168.50.4) 활용
> DB: shared-db (192.168.50.201) - dailymemory database
> OpenAI API: NestJS 서버 (192.168.50.214) 또는 직접 호출

---

## 1. Weekly Life Report (주간 라이프 리포트)

**우선순위: 높음**
**스케줄: 매주 일요일 09:00 UTC**

### 개요
Morning Brief가 뉴스를 요약하듯, 사용자의 한 주를 AI가 정리하여 푸시 알림으로 전달.

### 출력 예시
```
이번 주 요약 (3/31 - 4/6):
- 5개 기억 기록
- 만난 사람: Jake, Sarah, Shion
- 주요 장소: Brooklyn, Gangnam
- 지출: $15 (커피), $2M (Jake 스타트업 소식)
- 다가오는 이벤트: Jake 스타트업 축하 (금요일)
- 오래 연락 안 한 사람: Mom (42일), David (35일)
- AI 인사이트: "이번 주는 친구들과 많은 시간을 보냈네요!"
```

### DAG 구조
```
weekly_life_report_dag.py
├── Task 1: fetch_weekly_memories
│   - Firestore에서 이번 주 memories 조회
│   - 또는 PostgreSQL dailymemory DB에 Firestore 동기화 데이터 활용
├── Task 2: fetch_persons_stats
│   - 이번 주 언급된 사람, 만남 횟수
│   - 30일 이상 미연락 사람 목록
├── Task 3: generate_report
│   - OpenAI GPT-4o-mini로 자연어 요약 생성
│   - 프롬프트: 주간 기억 데이터 → 친근한 톤의 요약문
├── Task 4: send_push_notification
│   - Firebase Cloud Messaging (FCM) 으로 푸시 발송
│   - 또는 앱 내 "Weekly Report" 섹션에 저장
```

### 필요 작업
- [ ] DAG 파일 작성 (`/opt/airflow/dags/weekly_life_report_dag.py`)
- [ ] Firestore 또는 PostgreSQL에서 사용자별 메모리 조회 쿼리
- [ ] OpenAI 요약 프롬프트 설계
- [ ] FCM 푸시 알림 연동 (또는 Firestore에 report 문서 저장)
- [ ] iOS 앱에 Weekly Report 표시 UI (Home 탭 또는 별도 섹션)

### 예상 소요: 1-2일

---

## 2. Relationship Nudge (관계 관리 알림)

**우선순위: 높음**
**스케줄: 매일 09:00 UTC**

### 개요
장기간 연락하지 않은 사람을 감지하여 "만나보세요" 푸시 알림 전송.

### 로직
```python
# 임계값
WARN_DAYS = 30      # 경고
CRITICAL_DAYS = 60  # 심각

for person in all_persons:
    days_since = (today - person.last_meeting_date).days
    if days_since >= CRITICAL_DAYS:
        send_nudge(f"It's been {days_since} days since you met {person.name}. Reach out?")
    elif days_since >= WARN_DAYS:
        send_nudge(f"You haven't seen {person.name} in a while ({days_since} days)")
```

### DAG 구조
```
relationship_nudge_dag.py
├── Task 1: fetch_all_persons
│   - 사용자별 persons 조회
│   - lastMeetingDate, meetingCount 확인
├── Task 2: detect_stale_relationships
│   - 30일/60일 임계값 기준 필터
│   - 우선순위 정렬 (가족 > 친구 > 동료)
├── Task 3: send_nudge_notifications
│   - FCM 푸시 또는 인앱 알림 생성
│   - 하루 최대 2-3개 (알림 피로 방지)
```

### 필요 작업
- [ ] DAG 파일 작성
- [ ] 사용자별 person 데이터 조회 (Firestore 또는 PostgreSQL)
- [ ] FCM 연동
- [ ] 알림 빈도 제어 (하루 최대 N개)

### 예상 소요: 0.5일

---

## 3. Promise Tracker (약속 추적기)

**우선순위: 높음**
**스케줄: 매일 08:00 UTC**

### 개요
"PROMISE" 카테고리 메모리 중 완료되지 않은 건을 추적하여 리마인더 자동 생성.

### 로직
```python
# PROMISE 카테고리 메모리 중 리마인더가 없는 건 탐색
promises = fetch_memories(category="PROMISE", has_reminder=False)

for promise in promises:
    # AI로 약속 내용에서 기한 추출
    deadline = extract_deadline(promise.content)
    
    if deadline and deadline < today + timedelta(days=3):
        create_reminder(
            title=f"Promise: {promise.summary}",
            body=promise.content[:100],
            scheduled_at=deadline - timedelta(hours=12)
        )
```

### DAG 구조
```
promise_tracker_dag.py
├── Task 1: fetch_unfulfilled_promises
│   - category=PROMISE, triggeredAt=null인 메모리 조회
├── Task 2: analyze_deadlines
│   - OpenAI로 각 약속의 기한 추출
│   - "next Friday", "by end of month" 등 자연어 해석
├── Task 3: create_reminders
│   - 기한 3일 전 리마인더 자동 생성
│   - 중복 생성 방지 (기존 리마인더 확인)
```

### 예상 소요: 1일

---

## 4. Monthly Insight Report (월간 인사이트)

**우선순위: 높음**
**스케줄: 매월 1일 09:00 UTC**

### 개요
한 달간의 기억을 분석하여 통계 + AI 인사이트 제공.

### 출력 예시
```
4월 인사이트:
📊 통계
- 총 23개 기억 기록 (지난 달 대비 +15%)
- 가장 많이 만난 사람: Jake (5회)
- 가장 많이 간 장소: Brooklyn (3회)
- 총 지출 언급: $2,015

🧠 AI 인사이트
- "이번 달은 사회적 활동이 많았습니다. 특히 Jake와의 만남이 잦았네요."
- "금전 관련 기록이 3건 있었습니다. 정리해보시겠어요?"

📈 트렌드
- 기록 빈도: 주 5.75회 (꾸준함!)
- 카테고리 분포: Meeting 40%, Event 25%, General 20%, Financial 15%

👥 관계 변화
- 새로 만난 사람: 2명
- 가장 오래 연락 안 한 사람: Mom (45일)
```

### DAG 구조
```
monthly_insight_dag.py
├── Task 1: aggregate_monthly_stats
│   - 기억 수, 카테고리별 분포, 인물별 빈도
│   - 장소별 빈도, 금액 합계
├── Task 2: compare_with_last_month
│   - 전월 대비 증감 계산
├── Task 3: generate_ai_insight
│   - OpenAI로 통계 기반 인사이트 생성
│   - 트렌드 분석, 제안사항
├── Task 4: store_and_notify
│   - Firestore에 monthly_reports 컬렉션 저장
│   - 푸시 알림 발송
```

### 예상 소요: 1-2일

---

## 5. On This Day (오늘의 추억)

**우선순위: 중간**
**스케줄: 매일 07:00 UTC**

### 개요
1년 전, 2년 전 오늘의 기억을 찾아 아침 푸시 알림으로 전달.

### DAG 구조
```
on_this_day_dag.py
├── Task 1: find_memories_on_this_day
│   - 1년 전, 2년 전... 같은 날짜의 메모리 조회
│   - 사진이 있는 메모리 우선
├── Task 2: format_notification
│   - "1년 전 오늘, Brooklyn에서 Jake와 커피를 마셨네요 ☕"
├── Task 3: send_push
│   - FCM 푸시 발송
│   - 앱 내 "On This Day" 카드에도 저장
```

### 예상 소요: 0.5일

---

## 6. Memory Re-indexing (임베딩 재인덱싱)

**우선순위: 중간**
**스케줄: 매주 토요일 02:00 UTC**

### 개요
미인덱싱된 메모리의 벡터 임베딩을 배치로 생성/갱신. Off-peak 시간에 실행하여 API 비용 최적화.

### DAG 구조
```
memory_reindex_dag.py
├── Task 1: find_unindexed_memories
│   - embedding이 null이거나 text_hash가 변경된 메모리
├── Task 2: batch_generate_embeddings
│   - OpenAI API 배치 호출 (20개씩)
│   - pgvector에 저장
├── Task 3: cleanup_orphan_embeddings
│   - 삭제된 메모리의 임베딩 정리
```

### 예상 소요: 0.5일

---

## 7. Photo Batch Analysis (사진 일괄 분석)

**우선순위: 낮음**
**스케줄: 매일 03:00 UTC**

### 개요
미분석 사진을 야간에 일괄 AI 분석. GPT-4o Vision 호출을 off-peak에 집중하여 비용 효율화.

### DAG 구조
```
photo_batch_analysis_dag.py
├── Task 1: find_unanalyzed_photos
│   - aiAnalysis가 null인 사진 조회
├── Task 2: download_and_analyze
│   - Firebase Storage에서 사진 다운로드
│   - GPT-4o Vision으로 분석
│   - 결과를 Firestore에 업데이트
├── Task 3: update_memory_tags
│   - 사진 분석 결과의 태그를 메모리에 반영
```

### 예상 소요: 1일

---

## 구현 우선순위 & 일정

| 순서 | 기능 | 예상 소요 | 의존성 |
|------|------|----------|--------|
| 1 | Weekly Life Report | 1-2일 | FCM 설정 필요 |
| 2 | Relationship Nudge | 0.5일 | FCM |
| 3 | On This Day | 0.5일 | FCM |
| 4 | Promise Tracker | 1일 | - |
| 5 | Monthly Insight | 1-2일 | #1 완료 후 유사 구조 재사용 |
| 6 | Memory Re-indexing | 0.5일 | - |
| 7 | Photo Batch Analysis | 1일 | Firebase Storage 접근 |

**총 예상: 5-7일**

---

## 공통 의존성

### FCM (Firebase Cloud Messaging) 설정
- Firebase Console에서 Cloud Messaging 활성화
- iOS 앱에 APNs 키 등록
- Airflow에서 `firebase-admin` Python SDK로 푸시 발송
- 이미 서버에 `firebase-service-account.json`이 있으므로 재사용 가능

### 데이터 접근 방식
**Option A**: Firestore 직접 접근 (firebase-admin Python SDK)
- 장점: 실시간 데이터
- 단점: Firestore 읽기 비용

**Option B**: PostgreSQL dailymemory DB 활용
- 장점: 비용 없음, SQL 쿼리 유연
- 단점: Firestore와 동기화 지연 가능
- **추천**: 동기화된 데이터가 PostgreSQL에도 있도록 NestJS API에 sync endpoint 추가

### Airflow 환경 설정
```bash
# Airflow VM (192.168.50.4)에 추가 패키지 설치
pip install firebase-admin openai psycopg2-binary

# 환경 변수 (Airflow Variables)
DAILYMEMORY_DB_CONN = postgresql://app_user:<pw>@192.168.50.201:5432/dailymemory
OPENAI_API_KEY = sk-proj-...
FIREBASE_SERVICE_ACCOUNT = /opt/airflow/secrets/firebase-service-account.json
```

---

## 앱 UI 변경사항

### Home 탭 추가 섹션
- **Weekly Report 카드**: 주간 요약 표시 (펼치기/접기)
- **On This Day 카드**: 이미 구현되어 있음 (Airflow가 데이터 준비)
- **Nudge 배너**: "Sarah를 오랜만에 만나보세요" (탭하면 Person 상세로 이동)

### Settings 추가 옵션
- **Weekly Report**: ON/OFF + 수신 요일/시간 설정
- **Relationship Nudge**: ON/OFF + 임계값 일수 설정
- **On This Day**: ON/OFF (이미 있음)

---

## 참고: Morning Brief DAG 패턴 재사용

기존 `/opt/airflow/dags/morning_brief_dag.py`의 구조를 거의 그대로 재사용:
- DB 연결 → 데이터 수집 → OpenAI 요약 → 결과 저장/발송
- 동일한 패턴이므로 빠르게 구현 가능
