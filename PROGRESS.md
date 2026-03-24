# DailyMemory - 진행 상황

> 마지막 업데이트: 2026-03-24

---

## 현재 상태: Phase 1 진행 중

```
[✅ 완료] Phase 0: 기획 & 설계
[✅ 완료] Phase 0.5: UI 디자인 (Stitch)
[✅ 완료] Phase 0.6: 프로젝트 세팅 (Android + iOS)
[→ 진행] Phase 1: 기본 기록 + 위젯
[ ] Phase 2: 음성 + AI 추출
[ ] Phase 3: 사진 + AI 분석
[ ] Phase 4: AI 검색
[ ] Phase 5: 리마인더
[ ] Phase 6: 클라우드 + 프라이버시
[ ] Phase 7: 폴리싱 + 출시
```

---

## 완료된 작업

### 1. 아이디어 검증 ✅
- [x] 유사 앱 시장 조사 (Day One, Diarium, Monica, Dex 등)
- [x] 시장 규모 확인 ($5.1B, CAGR 9.5~11.5%)
- [x] 차별화 포인트 정의: "검색이 아닌 대화로 기억 찾기"

### 2. 컨셉 확정 ✅
- [x] 슬로건: "기록은 내가, 기억은 AI가"
- [x] 앱 이름: DailyMemory
- [x] 핵심 가치 정의
  - AI가 자동으로 정리
  - 자연어로 질문하면 답변
  - 맥락 기반 리마인더
  - 관계 인사이트

### 3. 기술 스택 결정 ✅
- [x] 프레임워크: Native (Kotlin + Swift)
- [x] 백엔드: Firebase
- [x] AI: OpenAI GPT-4 / Claude API
- [x] 음성: 기기 내장 STT
- [x] 저장: 로컬 + 클라우드 선택 가능

### 4. PRD 작성 (v3) ✅
- [x] 핵심 기능 8가지 정의
- [x] 데이터 모델 설계
- [x] 개발 로드맵 (14주)
- [x] 수익 모델 (Freemium)
- [x] 성공 지표 (KPI)

### 5. 아키텍처 설계 ✅
- [x] Clean Architecture 구조
- [x] 프로젝트 디렉토리 구조
- [x] 데이터 흐름 정의
- [x] Firebase 구조 설계

### 6. UI/UX 설계 ✅
- [x] 와이어프레임 (기본)
- [x] 컬러 시스템
- [x] 모든 화면 상세 설계
  - 홈 (5가지 상태)
  - 기록 (음성/텍스트/AI 분석)
  - 검색 (5가지 상태)
  - 인물 (목록/상세/편집)
  - 설정
  - 기록 상세
- [x] 위젯 디자인 (4종)
- [x] 인터랙션 & 애니메이션 정의
- [x] 다크 모드
- [x] 접근성 체크리스트

### 7. Stitch 디자인 생성 ✅
- [x] 디자인 프롬프트 영어로 작성
- [x] Google Stitch로 화면 생성
- [x] 12개 화면 완료:
  - home_dailymemory (홈 기본)
  - home_empty_state (홈 빈 상태)
  - record_voice_idle (녹음 대기)
  - record_voice_recording (녹음 중)
  - record_ai_result (AI 분석 결과)
  - record_text_mode (텍스트 모드)
  - search_initial_state (검색 초기)
  - search_ai_response (검색 AI 응답)
  - people_list (인물 목록)
  - people_detail (인물 상세)
  - settings (설정)
  - memory_detail (기록 상세)
- [x] 각 화면별 screen.png + code.html 저장

### 8. 프로젝트 세팅 ✅ NEW
- [x] **Android 프로젝트 생성**
  - Kotlin + Jetpack Compose 프로젝트
  - Gradle (Kotlin DSL) + Version Catalog
  - Clean Architecture 폴더 구조
  - Hilt 의존성 주입 설정
  - Material3 테마 구성

- [x] **iOS 프로젝트 생성**
  - Swift + SwiftUI 프로젝트
  - Clean Architecture 폴더 구조
  - 커스텀 테마 색상 시스템

- [x] **공통 데이터 모델 구현**
  - Memory (기록) - 사진, AI 추출, 동기화 상태
  - Person (인물) - 관계 유형, 통계
  - Photo (사진) - AI 분석 결과
  - Reminder (알림) - 반복 유형

- [x] **로컬 데이터베이스 설정**
  - Android: Room Database + DAOs
  - iOS: Core Data + Managed Objects

---

## 결정된 사항

### 글로벌 서비스 ⭐ NEW
- **타겟 시장**: 글로벌 (전 세계)
- **기본 언어**: 영어
- **다국어 지원**: 한국어, 일본어, 중국어, 유럽어 등 (추후)
- **디자인 원칙**:
  - 유연한 텍스트 너비 (독일어 30-40% 더 김)
  - RTL 레이아웃 지원 (아랍어/히브리어)
  - 로케일 기반 날짜/시간/통화 포맷
  - 글로벌하게 이해되는 아이콘/이모지

### 핵심 기능 (MVP)
| 기능 | 포함 여부 | 비고 |
|------|----------|------|
| 음성/텍스트 기록 | ✅ | 핵심 |
| AI 자동 추출 | ✅ | 핵심 |
| 원터치 위젯 | ✅ | 기록 마찰 최소화 |
| 사진 + AI 분석 | ✅ | 맥락 강화 |
| AI 질문 응답 | ✅ | 차별화 |
| 스마트 리마인더 | ✅ | 가치 제공 |
| 관계 인사이트 | ✅ | 가치 제공 |
| 프라이버시 모드 | ✅ | 신뢰 확보 |

### 프라이버시
- 로컬/클라우드 **선택 가능**
- 개별 기록 잠금 기능
- AI 분석 제외 옵션
- 데이터 내보내기 지원

### 수익 모델
- **무료**: 월 30개 기록, 기본 검색
- **프리미엄** ($4.99/월): 무제한 + AI 기능 + 클라우드

---

## 다음 단계 (TODO)

### 즉시 진행: Phase 1 UI 구현
1. [ ] **Firebase 프로젝트 생성**
   - Firebase 콘솔에서 프로젝트 생성
   - Android/iOS 앱 등록
   - google-services.json / GoogleService-Info.plist 설정

2. [x] **기록 CRUD 구현** ✅
   - [x] Android: MemoryRepository + UseCase
   - [x] iOS: MemoryRepository + UseCase

3. [x] **UI 화면 구현 (Stitch 디자인 참고)** ✅
   - [x] 홈 화면 (Today's Reminders, Recent Memories) ✅
   - [x] 기록 화면 (5가지 상태 모두) ✅
   - [x] 인물 목록/상세 ✅

### Phase 1 작업 목록 (Week 1-2)
- [x] 데이터 모델 구현 (Room / Core Data) ✅
- [ ] 기록 CRUD (로컬)
- [ ] 인물 CRUD (로컬)
- [x] 기본 UI 구현 (Stitch 디자인 참고) ✅
  - [x] 홈 화면 ✅ (기본 상태 + 빈 상태)
  - [x] 기록 화면 ✅ (5가지 상태: 음성 대기/녹음 중/텍스트/AI 처리/AI 결과)
  - [x] 인물 목록/상세 ✅ (목록 + 상세 + 타임라인)
  - [x] 검색 화면 ✅ (초기/검색중/AI응답/빈결과 상태)
  - [x] 설정 화면 ✅ (계정/데이터/알림/보안/AI/앱정보)
- [x] 홈 화면 위젯 ✅

### 디자인 에셋
- 경로: `docs/stitch/`
- 각 화면별 `screen.png` (디자인), `code.html` (참고용)

---

## 주요 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| PRD | `docs/PRD.md` | 제품 요구사항 정의서 (v3) |
| 아키텍처 | `docs/ARCHITECTURE.md` | 기술 구조 |
| 와이어프레임 | `docs/WIREFRAME.md` | 화면 구성 (기본) |
| UI 상세 | `docs/UI_DETAIL.md` | 상태별 UI, 인터랙션, 애니메이션 |
| Stitch 프롬프트 | `docs/STITCH_PROMPTS.md` | 디자인 생성용 프롬프트 (영어) |
| **디자인 에셋** | `docs/stitch/` | 화면별 PNG + HTML 코드 |

---

## 아이디어 백로그 (향후)

우선순위 낮음, 나중에 검토:
- [ ] Apple Watch / Wear OS 앱
- [ ] 캘린더 연동 (Google, Apple)
- [ ] 통화 후 자동 프롬프트
- [ ] 연간 관계 리포트
- [ ] 스레드 기록 (연속 사건 묶기)
- [ ] 공유 기록 (커플/가족 모드)
- [ ] AI 기반 감정 분석
- [ ] 위치 기반 트리거

---

## 세션 기록

### 2024-03-23 (첫 세션)
**진행한 내용:**
1. 앱 아이디어 논의 및 발전
2. 시장 조사 및 경쟁 분석
3. 컨셉 확정 (A안 + B안 결합)
4. 기술 스택 결정
5. PRD v3 작성
6. 아키텍처 설계
7. UI/UX 와이어프레임
8. UI 상세 설계 (전체 화면)

**결정 사항:**
- 앱 이름: DailyMemory
- Native 개발 (Kotlin + Swift)
- Firebase 백엔드
- MVP에 위젯, 사진 AI 분석, 프라이버시 모드 포함

**다음 세션에서 할 일:**
- ~~Figma 디자인 또는 개발 시작~~ ✅
- Android/iOS 프로젝트 세팅

### 2024-03-24 (두 번째 세션)
**진행한 내용:**
1. 글로벌 서비스 결정 - 영어 기본, 다국어 지원
2. Stitch 프롬프트 영어로 전체 재작성
3. i18n/글로벌 디자인 가이드라인 추가
4. Google Stitch로 12개 화면 디자인 생성
5. 디자인 에셋 정리 (docs/stitch/)

**결정 사항:**
- 글로벌 서비스 타겟
- 유연한 레이아웃 (텍스트 길이 대응)
- RTL 레이아웃 지원 고려
- 로케일 기반 포맷 (날짜/시간/통화)

**다음 세션에서 할 일:**
- ~~Android 프로젝트 세팅 및 Phase 1 개발 시작~~ ✅
- ~~iOS 프로젝트 세팅~~ ✅

### 2024-03-24 (세 번째 세션)
**진행한 내용:**
1. Android 프로젝트 생성 (Kotlin + Jetpack Compose)
   - Gradle 설정 (Version Catalog 사용)
   - Hilt DI 설정
   - Material3 테마 구성
   - 기본 Navigation 설정
2. iOS 프로젝트 생성 (Swift + SwiftUI)
   - Clean Architecture 폴더 구조
   - 커스텀 테마 색상 시스템
   - 기본 Tab Navigation 설정
3. 공통 데이터 모델 구현
   - Memory, Person, Photo, Reminder
   - Category, Relationship, RepeatType, SyncStatus enums
4. 로컬 데이터베이스 설정
   - Android: Room Database + DAOs + Type Converters
   - iOS: Core Data Model + Managed Objects + Stores

**결정 사항:**
- Version Catalog 사용 (libs.versions.toml)
- 오프라인 우선 아키텍처 (SyncStatus 필드)
- 기록별 AI 제외 옵션 (excludeFromAI)

**다음 세션에서 할 일:**
- ~~홈 화면 UI 구현 (Stitch 디자인 참고)~~ ✅
- Repository + UseCase 패턴 구현
- Firebase 프로젝트 설정

### 2024-03-24 (네 번째 세션)
**진행한 내용:**
1. 홈 화면 UI 구현 (Android + iOS)
   - Greeting 섹션 (시간대별 인사)
   - Reminder 카드 (오렌지 배경, Done/Snooze 버튼)
   - Recent Memories 섹션 (메모리 카드, 태그 칩)
   - On This Day 섹션 (1년 전 기억, 사진 카드)
   - Empty State (첫 사용자용 화면)
2. ViewModel 구조 설정
   - HomeViewModel (Android: Hilt, iOS: ObservableObject)
   - UI 상태 모델 정의

**다음 세션에서 할 일:**
- ~~기록 화면 UI 구현~~ ✅
- Repository + UseCase 패턴 구현
- 로컬 데이터 CRUD 연동

### 2024-03-24 (다섯 번째 세션)
**진행한 내용:**
1. 기록 화면 UI 구현 (Android + iOS)
   - 5가지 상태 구현:
     - Voice Idle (녹음 대기)
     - Voice Recording (녹음 중 + 실시간 트랜스크립션)
     - Text Mode (텍스트 입력)
     - AI Processing (AI 분석 중)
     - AI Result (AI 분석 결과)
   - RecordViewModel 상태 관리
   - 시뮬레이션된 음성 인식 및 AI 분석
   - AI 추출 정보 편집 기능 (사람, 카테고리)

**구현된 화면 컴포넌트:**
- Android: RecordScreen.kt, RecordViewModel.kt
- iOS: RecordView.swift (ViewModel 포함)
- VoiceIdleView, VoiceRecordingView, TextModeView
- AIProcessingView, AIResultView
- PersonChipView, CategoryChipView

**다음 세션에서 할 일:**
- ~~인물 목록/상세 화면 구현~~ ✅
- Repository + UseCase 패턴 구현
- 로컬 데이터 CRUD 연동

### 2026-03-24 (여섯 번째 세션)
**진행한 내용:**
1. 인물 화면 UI 구현 (Android + iOS)
   - **인물 목록 화면 (PersonListScreen / PersonListView)**
     - 헤더 (타이틀 + Add 버튼)
     - 검색바 (실시간 필터링)
     - 정렬 탭 (Recent, A-Z, Frequent)
     - 인물 카드 (아바타, 이름, 관계, 마지막 만남, 메모리 수)
     - 특별 표시 (생일 알림, 연락 안함 경고)
     - 빈 상태 화면
   - **인물 상세 화면 (PersonDetailScreen / PersonDetailView)**
     - 프로필 섹션 (아바타, 이름, 관계)
     - 관계 요약 카드 (만남 횟수, 마지막 만남, 첫 기억)
     - 다가오는 이벤트 카드 (결혼식 등)
     - 타임라인 섹션 (연도별 그룹핑)
     - "메모리 추가" FAB 버튼

**구현된 화면 컴포넌트:**
- Android: PeopleViewModel.kt, PersonListScreen.kt, PersonDetailScreen.kt
- iOS: PersonListView.swift (ViewModel 포함), PersonDetailView.swift
- 네비게이션 연동 (목록 → 상세 이동)

**다음 세션에서 할 일:**
- ~~검색 화면 구현~~ ✅
- Repository + UseCase 패턴 구현
- 로컬 데이터 CRUD 연동

### 2026-03-24 (일곱 번째 세션)
**진행한 내용:**
1. 검색 화면 UI 구현 (Android + iOS)
   - **4가지 상태 구현:**
     - Initial (초기): 검색바, 필터 버튼, 추천 질문, 최근 검색
     - Searching (검색중): 로딩 표시
     - Result (AI 응답): AI 답변 카드, 관련 메모리, 후속 질문
     - Empty (빈 결과): 결과 없음 화면
   - **SearchViewModel** 상태 관리
   - 시뮬레이션된 AI 검색 응답

**구현된 화면 컴포넌트:**
- Android: SearchViewModel.kt, SearchScreen.kt
- iOS: SearchView.swift (ViewModel 포함)
- SearchBar, FilterButton, SuggestionsSection
- AIAnswerCard, RelatedMemoriesSection, FollowUpSection
- RecentSearchesSection, EmptyResultContent

**다음 세션에서 할 일:**
- ~~설정 화면 구현~~ ✅
- Repository + UseCase 패턴 구현
- 로컬 데이터 CRUD 연동

### 2026-03-24 (여덟 번째 세션)
**진행한 내용:**
1. 설정 화면 UI 구현 (Android + iOS)
   - **6가지 섹션 구현:**
     - Account (프로필, 프리미엄 상태)
     - Data (저장소, 동기화, 내보내기/가져오기)
     - Notifications (리마인더, 데일리 프롬프트, 방해금지, On this day)
     - Privacy & Security (앱 잠금, 잠긴 기록 표시)
     - AI Features (자동 분석, 스마트 리마인더)
     - About (버전, 개인정보처리방침, 이용약관, 문의, 평가)
   - Sign Out 버튼
   - 토글 스위치 상태 관리

**구현된 화면 컴포넌트:**
- Android: SettingsViewModel.kt, SettingsScreen.kt
- iOS: SettingsView.swift (ViewModel 포함)
- 네비게이션 하단 탭에 Settings 추가

**Phase 1 UI 완료!**
- 홈 화면 ✅
- 기록 화면 ✅
- 인물 화면 ✅
- 검색 화면 ✅
- 설정 화면 ✅

**다음 세션에서 할 일:**
- Repository + UseCase 패턴 구현
- 로컬 데이터 CRUD 연동
- ~~홈 화면 위젯 구현~~ ✅

### 2026-03-24 (아홉 번째 세션)
**진행한 내용:**
1. 홈 화면 위젯 구현 (Android + iOS)
   - **Android 위젯 (Jetpack Glance)**
     - Small (1x1): 원터치 음성 녹음 버튼
     - Medium (2x2): 최근 메모리 + Voice/Text 버튼
     - Large (4x2): 날짜, 메모리 수, 리마인더, Voice/Text 버튼
     - Glance 의존성 추가 (androidx.glance)
     - AndroidManifest 위젯 리시버 등록
     - 위젯 프리뷰 drawable 생성
   - **iOS 위젯 (WidgetKit)**
     - QuickRecordWidget (Small): 원터치 음성 녹음
     - DailyMemoryWidget (Medium): 날짜, 리마인더, Voice/Text
     - LockScreenWidget (iOS 16+): 잠금화면 위젯 (Circular, Rectangular, Inline)
     - Widget Extension 생성
     - Deep Link 처리 (dailymemory://record?mode=voice/text)

**구현된 파일:**
- Android:
  - `presentation/widget/SmallWidget.kt`
  - `presentation/widget/MediumWidget.kt`
  - `presentation/widget/LargeWidget.kt`
  - `presentation/widget/WidgetColors.kt`
  - `res/xml/widget_*_info.xml` (3개)
  - `res/drawable/widget_*_preview.xml` (3개)
  - `res/drawable/ic_mic.xml`, `ic_edit.xml`, `ic_bell.xml`
- iOS:
  - `DailyMemoryWidget/DailyMemoryWidgetBundle.swift`
  - `DailyMemoryWidget/QuickRecordWidget.swift`
  - `DailyMemoryWidget/DailyMemoryWidget.swift`
  - `DailyMemoryWidget/LockScreenWidget.swift`
  - `DailyMemoryWidget/WidgetProvider.swift`
  - `DailyMemoryWidget/WidgetEntry.swift`
  - `DailyMemoryWidget/WidgetColors.swift`

**Phase 1 UI + 위젯 완료!**
- 홈 화면 ✅
- 기록 화면 ✅
- 인물 화면 ✅
- 검색 화면 ✅
- 설정 화면 ✅
- 위젯 ✅

**다음 세션에서 할 일:**
- ~~Repository + UseCase 패턴 구현~~ ✅
- 로컬 데이터 CRUD 연동
- Firebase 프로젝트 설정
- Phase 2: 음성 인식 + AI 추출 기능

### 2026-03-24 (열 번째 세션)
**진행한 내용:**
1. Repository + UseCase 패턴 구현 (Android + iOS)
   - **Repository 인터페이스 (Domain Layer)**
     - MemoryRepository: 메모리 CRUD, 검색, 필터링
     - PersonRepository: 인물 CRUD, 정렬, 검색
     - ReminderRepository: 알림 CRUD, 날짜 조회, 액션
   - **Repository 구현체 (Data Layer)**
     - MemoryRepositoryImpl: Room DAO / Core Data Store 래핑
     - PersonRepositoryImpl: Room DAO / Core Data Store 래핑
     - ReminderRepositoryImpl: Room DAO / Core Data Store 래핑
   - **UseCase 클래스들 (Domain Layer)**
     - Memory: Save, Update, Delete, Get, GetRecent, Search
     - Person: Save, Update, Delete, Get, GetAll
     - Reminder: Save, Update, Delete, GetToday, GetUpcoming, Complete, Snooze
   - **DI 모듈**
     - Android: RepositoryModule (Hilt @Binds)
     - iOS: DIContainer (Singleton pattern)

**구현된 파일 (Android):**
- `domain/repository/MemoryRepository.kt`
- `domain/repository/PersonRepository.kt`
- `domain/repository/ReminderRepository.kt`
- `data/repository/MemoryRepositoryImpl.kt`
- `data/repository/PersonRepositoryImpl.kt`
- `data/repository/ReminderRepositoryImpl.kt`
- `domain/usecase/memory/*.kt` (6개)
- `domain/usecase/person/*.kt` (5개)
- `domain/usecase/reminder/*.kt` (7개)
- `di/RepositoryModule.kt`

**구현된 파일 (iOS):**
- `Domain/Repository/MemoryRepository.swift`
- `Domain/Repository/PersonRepository.swift`
- `Domain/Repository/ReminderRepository.swift`
- `Data/Repository/MemoryRepositoryImpl.swift`
- `Data/Repository/PersonRepositoryImpl.swift`
- `Data/Repository/ReminderRepositoryImpl.swift`
- `Domain/UseCase/Memory/*.swift` (6개)
- `Domain/UseCase/Person/*.swift` (5개)
- `Domain/UseCase/Reminder/*.swift` (7개)
- `Core/DI/DIContainer.swift`

**Clean Architecture 완성!**
- Domain Layer: 비즈니스 로직 (UseCase, Repository Interface)
- Data Layer: 데이터 접근 (Repository Implementation, DAO/Store)
- Presentation Layer: UI (ViewModel, View)

**다음 세션에서 할 일:**
- ViewModel에 UseCase 연동
- Firebase 프로젝트 설정
- Phase 2: 음성 인식 + AI 추출 기능

---

## 연락처 / 메모

- 프로젝트 시작일: 2024-03-23
- 예상 완료: 약 14주 (3.5개월)
