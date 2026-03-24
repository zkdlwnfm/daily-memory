# DailyMemory

> **"기록은 내가, 기억은 AI가"**
>
> 일상을 기록하면 AI가 대신 기억해주는 개인 기억 비서 앱

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **앱 이름** | DailyMemory |
| **플랫폼** | Android (Kotlin) + iOS (Swift) - Native |
| **백엔드** | Firebase (Firestore, Auth, Functions) |
| **AI** | OpenAI GPT-4 / Claude API |
| **상태** | ✅ 기획 완료, ✅ 디자인 완료, → 개발 준비 |

---

## 핵심 기능

1. **빠른 기록** - 음성/텍스트 입력 → AI가 인물, 장소, 날짜, 금액 자동 추출
2. **원터치 위젯** - 홈 화면에서 탭 한 번으로 녹음 시작
3. **사진 + AI 분석** - 사진 첨부 → AI가 상황/인물 분석
4. **AI 기억 탐색** - "철수 결혼 언제야?" → AI가 관련 기록 찾아서 답변
5. **스마트 리마인더** - 맥락 파악해서 적절한 타이밍에 알림
6. **관계 인사이트** - 인물별 만남 횟수, 주요 이벤트, 관계 트렌드
7. **프라이버시 모드** - 로컬/클라우드 선택, 개별 기록 잠금

---

## 기술 스택

### 클라이언트
| | Android | iOS |
|---|---------|-----|
| 언어 | Kotlin | Swift |
| UI | Jetpack Compose | SwiftUI |
| 아키텍처 | MVVM + Clean | MVVM + Clean |
| 로컬 DB | Room | Core Data |
| DI | Hilt | Factory Pattern |

### 백엔드
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- FCM (Push)

### AI/ML
- LLM: OpenAI GPT-4 / Claude API
- Embedding: OpenAI Embeddings
- Vision: GPT-4 Vision (사진 분석)

---

## 문서 구조

```
DailyMemory/
├── README.md              ← 프로젝트 개요
├── PROGRESS.md            ← 진행 상황 추적
├── NEXT_SESSION_PROMPT.md ← 다음 세션용 프롬프트
│
├── docs/
│   ├── PRD.md             ← 제품 요구사항 정의서 (v3)
│   ├── ARCHITECTURE.md    ← 아키텍처 설계
│   ├── WIREFRAME.md       ← 와이어프레임 (기본)
│   ├── UI_DETAIL.md       ← UI 상세 설계
│   ├── STITCH_PROMPTS.md  ← 디자인 프롬프트 (영어)
│   └── stitch/            ← 디자인 에셋 (12개 화면)
│       ├── home_dailymemory/
│       ├── home_empty_state/
│       ├── record_*/
│       ├── search_*/
│       ├── people_*/
│       ├── settings/
│       └── memory_detail/
│
├── android/               ← (예정) Android 프로젝트
└── ios/                   ← (예정) iOS 프로젝트
```

---

## 개발 로드맵

| Phase | 기간 | 내용 | 상태 |
|-------|------|------|------|
| 0 | - | 기획 & 설계 | ✅ 완료 |
| 0.5 | - | UI 디자인 (Stitch) | ✅ 완료 |
| 1 | Week 1-2 | 기본 기록 + 위젯 | → 다음 |
| 2 | Week 3-4 | 음성 + AI 추출 | ⏳ 대기 |
| 3 | Week 5-6 | 사진 + AI 분석 | ⏳ 대기 |
| 4 | Week 7-8 | AI 검색 | ⏳ 대기 |
| 5 | Week 9-10 | 리마인더 | ⏳ 대기 |
| 6 | Week 11-12 | 클라우드 + 프라이버시 | ⏳ 대기 |
| 7 | Week 13-14 | 폴리싱 + 출시 | ⏳ 대기 |

---

## 시작하기

### 다음 단계
1. Figma 디자인 작업
2. Android/iOS 프로젝트 세팅
3. Phase 1 개발 시작

### 개발 환경 요구사항
- Android Studio (최신)
- Xcode 15+
- Firebase 프로젝트
- OpenAI API Key

---

## 참고 자료

- [PRD 문서](docs/PRD.md) - 전체 기능 정의
- [아키텍처](docs/ARCHITECTURE.md) - 기술 구조
- [와이어프레임](docs/WIREFRAME.md) - 화면 구성
- [UI 상세](docs/UI_DETAIL.md) - 상태별 UI, 인터랙션

---

## 라이선스

Private Project
