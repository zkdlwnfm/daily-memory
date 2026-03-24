# 다음 세션 프롬프트

아래 프롬프트를 복사해서 새 세션에서 붙여넣으세요.

---

## 옵션 1: Android 개발 시작

```
DailyMemory 앱 Android 개발을 시작하자.

프로젝트 위치: /Users/sy2024091401/Documents/side/DailyMemory

현재 상태:
- 기획/설계 완료 (docs/PRD.md, docs/ARCHITECTURE.md)
- UI 디자인 완료 (docs/stitch/ 폴더에 화면별 PNG + HTML)
- Phase 1 시작 준비됨

진행할 작업:
1. Android Studio 프로젝트 생성 (Kotlin + Jetpack Compose)
2. Clean Architecture 폴더 구조 설정
3. 의존성 추가 (Room, Hilt, Navigation 등)
4. 데이터 모델 구현 시작

기술 스택:
- Kotlin + Jetpack Compose
- MVVM + Clean Architecture
- Room (로컬 DB)
- Hilt (DI)
- Coroutines + Flow

먼저 PROGRESS.md 읽고 상황 파악한 다음 프로젝트 세팅 시작해줘.
```

---

## 옵션 2: iOS 개발 시작

```
DailyMemory 앱 iOS 개발을 시작하자.

프로젝트 위치: /Users/sy2024091401/Documents/side/DailyMemory

현재 상태:
- 기획/설계 완료 (docs/PRD.md, docs/ARCHITECTURE.md)
- UI 디자인 완료 (docs/stitch/ 폴더에 화면별 PNG + HTML)
- Phase 1 시작 준비됨

진행할 작업:
1. Xcode 프로젝트 생성 (Swift + SwiftUI)
2. Clean Architecture 폴더 구조 설정
3. SPM 의존성 설정
4. 데이터 모델 구현 시작

기술 스택:
- Swift + SwiftUI
- MVVM + Clean Architecture
- Core Data (로컬 DB)
- Swift Concurrency (async/await)

먼저 PROGRESS.md 읽고 상황 파악한 다음 프로젝트 세팅 시작해줘.
```

---

## 옵션 3: Android + iOS 동시 세팅

```
DailyMemory 앱 Android와 iOS 프로젝트를 둘 다 세팅하자.

프로젝트 위치: /Users/sy2024091401/Documents/side/DailyMemory

현재 상태:
- 기획/설계 완료
- UI 디자인 완료 (docs/stitch/)
- Phase 1 시작 준비됨

진행할 작업:
1. Android 프로젝트 생성 (android/ 폴더)
2. iOS 프로젝트 생성 (ios/ 폴더)
3. 공통 데이터 모델 구조 정의
4. 각 플랫폼 기본 설정

먼저 PROGRESS.md와 ARCHITECTURE.md 읽고 프로젝트 세팅 시작해줘.
```

---

## 옵션 4: 특정 화면 구현

```
DailyMemory 앱의 [홈 화면 / 기록 화면 / 검색 화면] 구현을 시작하자.

프로젝트 위치: /Users/sy2024091401/Documents/side/DailyMemory

디자인 참고:
- docs/stitch/home_dailymemory/screen.png (디자인)
- docs/stitch/home_dailymemory/code.html (HTML 참고)
- docs/UI_DETAIL.md (상세 스펙)

[Android / iOS] 플랫폼으로 구현해줘.

먼저 해당 화면의 디자인 파일과 UI_DETAIL.md 읽고 구현 시작해줘.
```

---

## 프로젝트 구조 참고

```
DailyMemory/
├── README.md              # 프로젝트 개요
├── PROGRESS.md            # 진행 상황 (필독!)
├── NEXT_SESSION_PROMPT.md # 이 파일
│
├── docs/
│   ├── PRD.md             # 제품 요구사항
│   ├── ARCHITECTURE.md    # 기술 아키텍처
│   ├── WIREFRAME.md       # 와이어프레임
│   ├── UI_DETAIL.md       # UI 상세 스펙
│   ├── STITCH_PROMPTS.md  # 디자인 프롬프트
│   └── stitch/            # 디자인 에셋 (PNG + HTML)
│       ├── home_dailymemory/
│       ├── home_empty_state/
│       ├── record_voice_idle/
│       ├── record_voice_recording/
│       ├── record_ai_result/
│       ├── record_text_mode/
│       ├── search_initial_state/
│       ├── search_ai_response/
│       ├── people_list/
│       ├── people_detail/
│       ├── settings/
│       └── memory_detail/
│
├── android/               # (생성 예정) Android 프로젝트
└── ios/                   # (생성 예정) iOS 프로젝트
```

---

## 핵심 정보 요약

**앱 이름**: DailyMemory
**슬로건**: "기록은 내가, 기억은 AI가"
**타겟**: 글로벌 (영어 기본)

**핵심 기능**:
1. 음성/텍스트 기록 + AI 자동 추출
2. 원터치 위젯
3. 사진 + AI 분석
4. AI 기억 탐색 (자연어 질문)
5. 스마트 리마인더
6. 관계 인사이트
7. 프라이버시 모드 (로컬/클라우드 선택)

**기술 스택**:
- Android: Kotlin + Jetpack Compose + Room + Hilt
- iOS: Swift + SwiftUI + Core Data
- Backend: Firebase (Auth, Firestore, Functions)
- AI: OpenAI GPT-4 / Claude API
