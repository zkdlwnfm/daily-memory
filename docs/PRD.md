# DailyMemory - Product Requirements Document (v3)

## 1. 앱 개요

### 한 줄 정의
> **"기록은 내가, 기억은 AI가"** - 일상을 기록하면 AI가 대신 기억해주는 개인 기억 비서

### 핵심 가치
- 빠르게 기록하면 AI가 자동으로 정리
- 자연어로 질문하면 관련 기억을 찾아서 답변
- 잊기 전에 맥락에 맞는 리마인더 제공
- 관계별 히스토리와 인사이트 제공

### 타겟 사용자
- 바쁜 직장인 (미팅, 약속, 인맥 관리)
- 기억력 보조가 필요한 사람
- 인간관계를 소중히 여기는 사람
- 일상을 기록하고 싶지만 정리가 귀찮은 사람

---

## 2. 핵심 기능

### 2.1 빠른 기록 (Quick Capture)

**음성/텍스트 입력**
- 음성 버튼 한 번으로 바로 녹음 → STT 변환
- 텍스트 직접 입력도 가능
- 최소한의 UI로 빠른 기록

**AI 자동 추출**
```
입력: "오늘 철수랑 강남에서 점심 먹었는데 다음 달 결혼한다고 함. 축의금 30만원"

AI 자동 추출:
├─ 인물: 철수
├─ 장소: 강남
├─ 날짜: 오늘 (2024-03-23)
├─ 이벤트: 결혼 (다음 달)
├─ 금액: 30만원 (축의금)
└─ 카테고리: 약속/이벤트
```

**수동 보정**
- AI 추출 결과 확인/수정 가능
- 인물 새로 추가 또는 기존 인물 연결
- 카테고리, 중요도 조정

---

### 2.2 원터치 위젯 (Quick Widget) ⭐ NEW

**홈 화면 위젯**
- 탭 한 번으로 음성 녹음 즉시 시작
- 앱 실행 없이 바로 기록 가능
- 기록 마찰을 최소화하는 핵심 기능

**위젯 유형**
```
[Android]
├─ 1x1: 음성 버튼만 (원터치 녹음)
├─ 2x2: 음성 + 텍스트 + 최근 기록 1개
└─ 4x2: 오늘의 리마인더 + 빠른 기록

[iOS]
├─ Small: 음성 버튼
├─ Medium: 음성 + 오늘 요약
└─ Lock Screen: 음성 녹음 바로가기
```

**알림창 빠른 입력**
- 상시 알림으로 빠른 접근 (선택 옵션)
- 알림에서 바로 텍스트 입력 가능

---

### 2.3 사진 기록 (Photo Memory) ⭐ NEW

**사진 첨부**
- 기록에 사진 추가 가능
- 갤러리에서 선택 또는 직접 촬영
- 여러 장 첨부 가능

**AI 사진 분석**
```
사진 업로드 시 AI 자동 분석:
├─ 인물 인식: "사진에 2명이 있네요"
├─ 장소 추정: "카페로 보여요"
├─ 상황 파악: "식사 중인 것 같아요"
└─ 추천 태그: #카페 #점심 #모임

예시:
[사진: 철수와 카페에서 찍은 사진]
AI: "철수님과 카페에서 찍은 사진이네요.
     '철수와 카페에서 만남'으로 기록할까요?"
```

**사진 검색**
- "작년에 엄마랑 찍은 사진" → 관련 기록 + 사진 표시
- 사진 속 인물로 검색

---

### 2.5 AI 기억 탐색 (Memory Query)

**자연어 질문**
```
Q: "철수 결혼 언제야?"
A: "철수님 결혼은 4월입니다. 3월 23일 기록에 따르면
    축의금 30만원 예정이시네요."

Q: "작년에 엄마랑 뭐 했지?"
A: "2025년 엄마 관련 기록 5건:
    • 5월 12일 - 생신 (선물: 안마기)
    • 8월 3일 - 가족여행 (속초, 2박3일)
    • 12월 25일 - 크리스마스 식사
    ..."

Q: "김과장한테 빌린 거 있어?"
A: "네, 2월 3일 점심값 15,000원 빌리셨어요."

Q: "지난달 회사 미팅 정리해줘"
A: "3월 회사 미팅 기록 3건:
    • 3월 5일 - A사 미팅 (프로젝트 제안)
    • 3월 12일 - 팀 회의 (Q2 목표 설정)
    • 3월 20일 - B사 계약 미팅
    ..."
```

**검색 방식**
- 의미 기반 검색 (Vector Embedding)
- 키워드 + 필터 검색 (기존 방식 병행)
- 인물별, 기간별, 카테고리별 필터

---

### 2.6 스마트 리마인더 (Smart Remind)

**맥락 기반 자동 알림**
```
• "내일 철수님 결혼식이에요. 축의금 30만원 준비하셨나요?"
• "오늘 엄마 생신이에요. 작년엔 안마기 드렸어요."
• "김과장님 만난 지 2주 됐어요. 점심값 갚으실 건가요?"
• "다음 주 A사 미팅이에요. 지난 미팅 내용 확인할까요?"
```

**리마인더 유형**
- 이벤트 알림 (생일, 기념일, 약속)
- 관계 리마인더 (연락 안 한 지 N일)
- 할 일 리마인더 (빌린 돈, 약속한 일)
- 회고 알림 ("1년 전 오늘" 같은)

**사용자 설정**
- 알림 시간대 설정
- 알림 빈도 조절
- 특정 카테고리 알림 ON/OFF

---

### 2.7 관계 인사이트 (Relationship Insight)

**인물별 대시보드**
```
[철수] 프로필
├─ 관계: 친구 (대학 동기)
├─ 만남 횟수: 12회 (2024년)
├─ 최근 만남: 3월 23일 (강남 점심)
├─ 다가오는 이벤트: 결혼 (4월)
│
├─ 주요 기록
│   • 축의금 30만원 예정
│   • 작년 생일 선물: 와인
│
└─ 관계 트렌드: 연락 빈도 ↑ (최근 3개월)
```

**관계 타임라인**
- 특정 인물과의 모든 기록을 시간순 표시
- 중요 이벤트 하이라이트

**전체 인사이트**
- 이번 달 가장 많이 만난 사람
- 오래 연락 안 한 사람 리스트
- 다가오는 이벤트 캘린더

---

### 2.8 프라이버시 모드 (Privacy Mode) ⭐ NEW

**저장 방식 선택**
```
[설정 > 데이터 저장]

○ 로컬 전용 모드
  - 모든 데이터를 기기에만 저장
  - 클라우드 업로드 없음
  - AI 기능은 온디바이스 또는 익명 처리

● 클라우드 동기화 모드 (기본값)
  - Firebase에 암호화하여 저장
  - 기기 간 동기화 가능
  - 자동 백업
```

**개별 기록 보안**
- 민감한 기록은 개별 잠금 설정 가능
- 앱 내 별도 비밀번호/생체 인증
- 잠긴 기록은 AI 분석에서 제외 옵션

**데이터 제어**
- 전체 데이터 내보내기 (JSON, PDF)
- 계정 삭제 시 모든 데이터 완전 삭제
- AI 학습에 데이터 사용 안 함 (기본값)

---

## 3. 화면 구성

### 3.1 메인 탭 (4개)
```
[홈] [기록] [검색] [인물]
```

1. **홈**: 오늘의 요약 + AI 추천 리마인더 + 최근 기록
2. **기록**: 새 기록 작성 (음성/텍스트) - 메인 CTA
3. **검색**: AI 질문 + 필터 검색
4. **인물**: 인물 목록 + 관계 인사이트

### 3.2 주요 화면 Flow

```
[홈]
 ├─ 오늘의 리마인더 카드
 ├─ 최근 기록 리스트
 └─ "1년 전 오늘" 회고

[기록] ← 메인 기능
 ├─ 음성 녹음 버튼 (중앙, 크게)
 ├─ 텍스트 입력 옵션
 ├─ AI 추출 결과 확인
 └─ 저장

[검색]
 ├─ AI 질문 입력창
 ├─ 질문 예시 (처음 사용자용)
 ├─ AI 답변 카드
 └─ 관련 기록 리스트

[인물]
 ├─ 인물 리스트 (최근 순/이름 순)
 ├─ 인물 프로필 상세
 └─ 인물별 타임라인
```

---

## 4. 데이터 모델

### 4.1 Memory (기록)
```typescript
Memory {
  id: string
  content: string           // 원본 텍스트

  // 사진 (NEW)
  photos: Photo[]           // 첨부된 사진들

  // AI 추출 데이터
  extractedPersons: string[]   // 추출된 인물 이름
  extractedLocation: string?
  extractedDate: Date?         // 언급된 날짜 (이벤트 날짜)
  extractedAmount: number?     // 금액
  extractedTags: string[]

  // 사용자 확정 데이터
  personIds: string[]       // 연결된 인물 ID
  category: Category
  importance: 1-5

  // 보안 (NEW)
  isLocked: boolean         // 개별 잠금 여부
  excludeFromAI: boolean    // AI 분석 제외 여부

  // 임베딩 (검색용)
  embedding: number[]       // Vector embedding

  // 메타데이터
  recordedAt: Date          // 기록한 시점
  recordedLocation: GeoPoint? // 기록 위치 (NEW)
  createdAt: Date
  updatedAt: Date
  syncStatus: SyncStatus
}

Photo {
  id: string
  url: string               // 로컬 또는 클라우드 URL
  thumbnailUrl: string
  aiAnalysis: string?       // AI 분석 결과
  createdAt: Date
}

enum Category {
  EVENT       // 이벤트, 기념일
  PROMISE     // 약속, 할 일
  MEETING     // 미팅, 만남
  FINANCIAL   // 금전 관계
  GENERAL     // 일반 기록
}
```

### 4.2 Person (인물)
```typescript
Person {
  id: string
  name: string
  nickname: string?
  relationship: Relationship

  // 연락처 (선택)
  phone: string?
  email: string?

  // AI 생성 요약
  summary: string?          // AI가 생성한 관계 요약

  // 통계 (자동 계산)
  meetingCount: number
  lastMeetingDate: Date?

  // 메타데이터
  profileImageUrl: string?
  memo: string?
  createdAt: Date
  updatedAt: Date
}

enum Relationship {
  FAMILY
  FRIEND
  COLLEAGUE
  BUSINESS
  ACQUAINTANCE
  OTHER
}
```

### 4.3 Reminder (알림)
```typescript
Reminder {
  id: string
  memoryId: string?         // 연결된 기록 (선택)
  personId: string?         // 연결된 인물 (선택)

  title: string
  body: string

  scheduledAt: Date
  repeatType: RepeatType

  isActive: boolean
  isAutoGenerated: boolean  // AI 자동 생성 여부

  triggeredAt: Date?
}

enum RepeatType {
  NONE
  DAILY
  WEEKLY
  MONTHLY
  YEARLY
}
```

---

## 5. 기술 스택

### 클라이언트

| 구분 | Android | iOS |
|------|---------|-----|
| 언어 | Kotlin | Swift |
| UI | Jetpack Compose | SwiftUI |
| 아키텍처 | MVVM + Clean | MVVM + Clean |
| 로컬 DB | Room | Core Data |
| DI | Hilt | Factory Pattern |
| 비동기 | Coroutines + Flow | async/await |

### 백엔드 (Firebase)
- **Auth**: Firebase Authentication (이메일, 소셜 로그인)
- **DB**: Cloud Firestore
- **Storage**: Firebase Storage (프로필 이미지)
- **Functions**: Cloud Functions (AI 처리, 알림 스케줄링)
- **Messaging**: FCM (푸시 알림)

### AI/ML
- **LLM**: OpenAI GPT-4 또는 Claude API
  - 엔티티 추출 (인물, 장소, 날짜, 금액)
  - 자연어 질문 응답
  - 리마인더 메시지 생성
- **Embedding**: OpenAI Embeddings 또는 오픈소스
- **Vector DB**: Pinecone 또는 Firebase Extensions

### 음성 인식
- Android: SpeechRecognizer API
- iOS: Speech Framework
- (옵션) Whisper API for 더 높은 정확도

---

## 6. 개발 로드맵

### Phase 1: 기본 기록 (Week 1-2)
- [ ] 프로젝트 세팅 (Android + iOS)
- [ ] 데이터 모델 구현
- [ ] 기록 CRUD (로컬)
- [ ] 인물 CRUD (로컬)
- [ ] 기본 UI (홈, 기록, 인물)
- [ ] **홈 화면 위젯 (원터치 녹음)** ⭐

### Phase 2: 음성 + AI 추출 (Week 3-4)
- [ ] 음성 인식 구현 (STT)
- [ ] AI 엔티티 추출 연동
- [ ] 추출 결과 확인/수정 UI
- [ ] 인물 자동 연결 로직

### Phase 3: 사진 + AI 분석 (Week 5-6) ⭐
- [ ] 사진 첨부 기능
- [ ] 사진 AI 분석 연동 (GPT-4 Vision / Claude)
- [ ] 사진 기반 자동 태깅
- [ ] 갤러리 뷰

### Phase 4: AI 검색 (Week 7-8)
- [ ] Vector Embedding 구현
- [ ] AI 질문 응답 연동
- [ ] 검색 UI (자연어 + 필터)
- [ ] 사진 포함 검색 결과

### Phase 5: 리마인더 (Week 9-10)
- [ ] 로컬 알림 구현
- [ ] AI 자동 리마인더 생성
- [ ] 알림 설정 UI
- [ ] "N년 전 오늘" 회고 기능

### Phase 6: 클라우드 + 프라이버시 (Week 11-12) ⭐
- [ ] Firebase 연동
- [ ] 인증 구현 (이메일, 소셜)
- [ ] **로컬/클라우드 선택 모드**
- [ ] 데이터 동기화 + 오프라인 지원
- [ ] 개별 기록 잠금 기능
- [ ] 데이터 내보내기

### Phase 7: 폴리싱 (Week 13-14)
- [ ] 관계 인사이트 대시보드
- [ ] UI/UX 개선
- [ ] 성능 최적화
- [ ] 베타 테스트
- [ ] 스토어 출시 준비

---

## 7. 수익 모델 (향후)

### Freemium
- **무료**: 월 30개 기록, 기본 검색, 수동 리마인더
- **프리미엄** ($4.99/월):
  - 무제한 기록
  - AI 질문 응답
  - 스마트 리마인더
  - 관계 인사이트
  - 클라우드 동기화

---

## 8. 성공 지표 (KPI)

- DAU/MAU 비율 > 30%
- 평균 기록 수 > 3개/주
- AI 질문 사용률 > 50%
- 리마인더 클릭률 > 40%
- 앱스토어 평점 > 4.5

---

## 9. 경쟁 우위

| vs | DailyMemory 차별점 |
|----|-------------------|
| Day One, Diarium | AI 질문 응답, 자동 엔티티 추출, 원터치 위젯 |
| Monica, Dex | 음성 입력, AI 기억 탐색, 사진 AI 분석 |
| AudioDiary | 관계 인사이트, 스마트 리마인더, 프라이버시 모드 |

**핵심 차별화**:
> "검색"이 아닌 "대화"로 기억을 찾는 경험
> + 기록 마찰 최소화 (원터치 위젯)
> + 사진으로 맥락 강화 (AI 분석)
> + 사용자가 데이터 통제 (프라이버시 모드)

---

## 10. 향후 확장 (v2.0+)

- Apple Watch / Wear OS 앱
- 캘린더 연동 (Google, Apple)
- 통화 후 자동 프롬프트
- 연간 관계 리포트
- 스레드 기록 (연속 사건 묶기)
- 공유 기록 (커플/가족 모드)
