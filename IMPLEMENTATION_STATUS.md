# DailyMemory 앱 구현 현황

> 마지막 업데이트: 2026-04-05

## 전체 진행 상황

```
Phase 0-0.6: ████████████████████ 100% (완료)
Phase 1:     ████████████████████ 100% (완료)
Phase 2:     ████████████████████ 100% (완료)
Phase 3:     ████████████████████ 100% (완료)
Phase 4:     ████████████████████ 100% (완료)
Phase 5:     ████████████████████ 100% (완료)
Phase 6:     ████████████████████ 100% (iOS 완료)
Phase 7:     ░░░░░░░░░░░░░░░░░░░░   0% (미시작)
```

---

## 완료된 항목 (Phase 0-1)

### 아키텍처 & 프로젝트 구조
- [x] Android: Kotlin + Jetpack Compose + Hilt
- [x] iOS: Swift + SwiftUI + DIContainer
- [x] Clean Architecture (Domain/Data/Presentation)
- [x] Gradle Version Catalog 설정
- [x] Material3 테마 시스템

### 로컬 데이터베이스
- [x] Android Room Database (3개 Entity, DAO)
- [x] iOS Core Data (3개 Entity, Store)
- [x] 마이그레이션 지원

### Domain Layer
- [x] 데이터 모델: Memory, Person, Reminder, Photo
- [x] Enum: Category, Relationship, RepeatType, SyncStatus
- [x] Repository 인터페이스 (3개)
- [x] Repository 구현체 (3개)
- [x] UseCase 클래스 (18개)
  - Memory: Save, Update, Delete, Get, GetRecent, Search
  - Person: Save, Update, Delete, Get, GetAll
  - Reminder: Save, Update, Delete, GetToday, GetUpcoming, Complete, Snooze

### UI 화면 (5개)
- [x] HomeScreen/HomeView - 인사말, 리마인더, 최근 메모리, 플래시백
- [x] RecordScreen/RecordView - 음성/텍스트 입력, AI 분석 결과
- [x] PersonListScreen/PersonListView - 검색, 정렬, 카드 목록
- [x] PersonDetailScreen/PersonDetailView - 프로필, 통계, 타임라인
- [x] SearchScreen/SearchView - AI 검색, 제안 질문
- [x] SettingsScreen/SettingsView - 6개 섹션 설정

### 네비게이션
- [x] Android Compose Navigation + Deep Link
- [x] iOS TabView + Sheet + Deep Link

### 위젯
- [x] Android Glance 위젯 (Small/Medium/Large)
- [x] iOS WidgetKit 위젯 (Small/Medium/LockScreen)

### ViewModel UseCase 연동
- [x] HomeViewModel
- [x] RecordViewModel
- [x] PeopleViewModel

---

## 미완료 항목

### Phase 1 잔여 작업 (UI 완성)

#### 높음 우선순위
- [x] **메모리 상세 화면** - 개별 메모리 보기/편집 ✅ 완료
  - Android: `presentation/memory/MemoryDetailScreen.kt`, `MemoryDetailViewModel.kt`
  - iOS: `Presentation/Memory/MemoryDetailView.swift`
  - 기능: 내용 표시, 카테고리/중요도 편집, AI 추출 정보, 연결된 인물, 태그, 사진, 삭제, 잠금

- [x] **Person 추가/편집 화면** ✅ 완료
  - Android: `presentation/person/PersonEditScreen.kt`, `PersonEditViewModel.kt`
  - iOS: `Presentation/Person/PersonEditView.swift`
  - 기능: 이름, 닉네임, 관계, 연락처(전화/이메일), 메모 입력, 프로필 사진 영역

- [x] **에러 핸들링 개선** ✅ 완료
  - Android: `presentation/common/components/StateComponents.kt`
  - iOS: `Presentation/Common/Components/StateViews.swift`
  - 기능: LoadingState, ErrorState (재시도 버튼), NetworkErrorState, EmptyState, SearchEmptyState
  - 미리 정의된 빈 상태: Memories, People, Reminders, Timeline

#### 중간 우선순위
- [x] 이미지 로딩 라이브러리 연동 ✅ 완료
  - Android: Coil (libs.coil.compose) + `ImageComponents.kt`
  - iOS: AsyncImage + `ImageViews.swift`
  - 기능: AsyncImage, AvatarImage, PhotoThumbnail, PhotoGrid
- [x] 사용자 이름 Preference 저장 ✅ 완료
  - Android: `data/local/UserPreferences.kt` (DataStore)
  - iOS: `Data/Local/UserPreferences.swift` (UserDefaults)
  - HomeViewModel에 연동 완료
- [ ] 로딩 스켈레톤 UI (선택 사항)

---

### Phase 2: 음성 인식 & AI 추출

#### 음성 인식 (Speech-to-Text)
- [x] **Android: Google Speech-to-Text API** ✅ 완료
  - 파일: `data/service/SpeechRecognitionService.kt`
  - 권한: `RECORD_AUDIO` (이미 설정됨)
  - 실시간 스트리밍 전사, 부분 결과, 오디오 레벨

- [x] **iOS: Speech Framework** ✅ 완료
  - 파일: `Data/Service/SpeechRecognitionService.swift`
  - 권한: `NSSpeechRecognitionUsageDescription`
  - `SFSpeechRecognizer` + `AVAudioEngine` 사용

#### AI 분석 서비스
- [x] **OpenAI/Claude API 클라이언트** ✅ 완료
  - Android: `data/remote/AIAnalysisService.kt`
  - iOS: `Data/Remote/AIAnalysisService.swift`
  - 기능: 텍스트에서 인물/장소/이벤트/금액/카테고리 추출
  - API 미설정 시 시뮬레이션 모드로 동작

- [x] **AnalyzeMemoryUseCase** ✅ 완료
  - Android: `domain/usecase/ai/AnalyzeMemoryUseCase.kt`
  - iOS: `Domain/UseCase/AI/AnalyzeMemoryUseCase.swift`
  - RecordViewModel에 연동 완료

---

### Phase 3: 사진 관리

- [x] **사진 촬영/선택 UI** ✅ 완료
  - Android: Photo Picker (ActivityResultContracts.PickMultipleVisualMedia) + Camera
  - iOS: PHPicker + Camera (UIImagePickerController)
  - 파일:
    - Android: `presentation/photo/PhotoPickerScreen.kt`, `PhotoPickerViewModel.kt`
    - iOS: `Presentation/Photo/PhotoPickerView.swift`

- [x] **사진 저장소** ✅ 완료
  - 로컬 파일 시스템 저장 (filesDir/photos, filesDir/thumbnails)
  - 썸네일 자동 생성 (300px)
  - FileProvider 설정 완료
  - 파일:
    - Android: `data/service/PhotoService.kt`, `res/xml/file_paths.xml`
    - iOS: `Data/Service/PhotoService.swift`

- [x] **사진 갤러리 뷰** ✅ 완료
  - 그리드 레이아웃 (3열)
  - 전체 화면 뷰어 (Pager + Zoom)
  - 삭제 기능 (확인 다이얼로그)
  - 파일:
    - Android: `presentation/photo/PhotoGalleryScreen.kt`
    - iOS: `Presentation/Photo/PhotoGalleryView.swift`

- [x] **AI 이미지 분석** ✅ 완료
  - OpenAI Vision API (GPT-4o)
  - 객체 인식, 장면 설명, OCR, 얼굴 감지
  - 자동 태그 생성
  - 시뮬레이션 모드 (API 미설정 시)
  - 파일:
    - Android: `data/remote/ImageAnalysisService.kt`, `domain/usecase/photo/AnalyzeImageUseCase.kt`
    - iOS: `Data/Remote/ImageAnalysisService.swift`, `Domain/UseCase/Photo/AnalyzeImageUseCase.swift`
  - RecordViewModel에 연동 완료

---

### Phase 4: 메모리 상세 & AI 검색

- [x] **메모리 상세 화면** ✅ 완료 (Phase 1에서 기본 구현, Phase 4에서 사진 갤러리 연동)
  - 전체 내용 표시
  - 관련 인물 링크
  - 좌표 위치 표시
  - 사진 갤러리 (실제 이미지 로딩, 풀스크린 뷰어)
  - 편집/삭제 기능
  - 카테고리/중요도 수정

- [x] **AI 시맨틱 검색** ✅ 완료
  - OpenAI text-embedding-3-small 벡터 임베딩
  - 코사인 유사도 검색 (VectorSearchEngine)
  - 자연어 질의 처리 (하이브리드 검색: 시맨틱 + 키워드)
  - 시뮬레이션 모드 (API 미설정 시)
  - 파일:
    - Android: `data/remote/EmbeddingService.kt`, `data/local/VectorSearchEngine.kt`, `domain/usecase/search/SemanticSearchUseCase.kt`
    - iOS: `Data/Remote/EmbeddingService.swift`, `Data/Local/VectorSearchEngine.swift`, `Domain/UseCase/Search/SemanticSearchUseCase.swift`
  - SearchViewModel에 연동 완료

- [x] **고급 필터링** ✅ 완료
  - 날짜 범위 (DatePicker)
  - 카테고리 복수 선택
  - 인물 필터
  - 금액 범위
  - 사진 유무, 잠금 상태 필터
  - 파일:
    - Android: `presentation/search/AdvancedFilterScreen.kt`
    - iOS: `Presentation/Search/AdvancedFilterView.swift`
  - SearchViewModel에 필터 적용 로직 구현 완료

- [x] **메모리 내보내기** ✅ 완료
  - JSON 형식 (메모리 + 인물 데이터)
  - CSV 형식 (테이블 형태)
  - 날짜 범위 내보내기
  - 공유 인텐트 지원
  - 파일:
    - Android: `data/service/ExportService.kt`
    - iOS: `Data/Service/ExportService.swift`

---

### Phase 5: 스마트 리마인더

- [x] **리마인더 생성/편집 UI** ✅ 완료
  - 제목, 본문 입력
  - 날짜/시간 선택 (DatePicker, TimePicker)
  - 반복 패턴 설정 (None/Daily/Weekly/Monthly/Yearly)
  - 인물 연결
  - 빠른 시간 설정 (1시간 후, 내일, 다음 주)
  - 파일:
    - Android: `presentation/reminder/ReminderEditScreen.kt`, `ReminderEditViewModel.kt`
    - iOS: `Presentation/Reminder/ReminderEditView.swift`

- [x] **알림 서비스** ✅ 완료
  - Android: AlarmManager + NotificationManager
  - iOS: UNUserNotificationCenter
  - 알림 액션 (완료, 스누즈)
  - 알림 채널 설정
  - 파일:
    - Android: `data/service/NotificationService.kt`
    - iOS: `Data/Service/NotificationService.swift`

- [x] **생일 리마인더** ✅ 완료
  - Person.birthday 기반 자동 생성
  - 매년 반복 (RepeatType.YEARLY)
  - 파일:
    - Android: `domain/usecase/reminder/GenerateSmartRemindersUseCase.kt`
    - iOS: `Domain/UseCase/Reminder/GenerateSmartRemindersUseCase.swift`

- [x] **스마트 제안** ✅ 완료
  - AI 분석 결과 기반 리마인더 제안
  - 키워드 감지: 결혼식, 생일, 미팅, 약속, 금전 거래
  - ReminderSuggestion 모델

- [x] **위치 기반 리마인더** ✅ 완료
  - 지오펜싱 (CoreLocation/Google Geofencing API)
  - 위치 선택 UI (LocationPickerView/Screen)
  - 도착/출발/양쪽 트리거 옵션
  - 반경 설정 (50-500m)
  - 파일:
    - Android: `data/service/GeofenceService.kt`, `presentation/reminder/LocationPickerScreen.kt`
    - iOS: `Data/Service/GeofenceService.swift`, `Presentation/Reminder/LocationPickerView.swift`
  - ReminderEditView/Screen에 통합 완료

---

### Phase 6: 클라우드 동기화 & 인증 (iOS)

#### Firebase 인증
- [x] **로그인/회원가입 화면** ✅ 완료
  - 이메일/비밀번호 로그인 및 회원가입
  - Apple Sign-In (ASAuthorization)
  - Google Sign-In (GoogleSignIn SDK)
  - 비밀번호 재설정
  - "계정 없이 사용" 옵션
  - 파일: `Presentation/Auth/LoginView.swift`

- [x] **인증 서비스** ✅ 완료
  - Firebase Authentication 연동
  - AuthState 관리 (unknown/signedOut/signedIn)
  - 프로필 업데이트 (displayName)
  - 계정 삭제
  - 파일: `Data/Remote/AuthService.swift`

- [x] **사용자 프로필 관리** ✅ 완료
  - UserProfile 모델 (uid, email, displayName, photoURL, isPremium)
  - Firestore에 프로필 저장/조회

#### 클라우드 동기화
- [x] **Firebase Firestore 연동** ✅ 완료
  - Memory, Person, Reminder 컬렉션 (사용자별 분리)
  - 실시간 리스너 (listenToMemories, listenToPersons)
  - 배치 저장 (batchSaveMemories, batchSavePersons)
  - 오프라인 캐시 (persistentCacheSettings)
  - 파일: `Data/Remote/FirestoreService.swift`

- [x] **오프라인 우선 동기화** ✅ 완료
  - SyncManager: 변경사항 큐잉 (JSON 파일 저장)
  - 네트워크 모니터링 (NWPathMonitor) - 온라인 복귀 시 자동 동기화
  - 충돌 해결: 최신 updatedAt 기준 클라우드 우선
  - 동기화 상태 표시 (idle/syncing/synced/error/offline)
  - 초기 전체 동기화 (performInitialSync)
  - 파일: `Data/Remote/SyncManager.swift`

- [x] **Firebase Storage** ✅ 완료
  - 사진/썸네일 업로드/다운로드
  - 프로필 사진 업로드
  - 로컬→클라우드 URL 자동 변환 (syncPhotos)
  - 파일: `Data/Remote/CloudStorageService.swift`

- [ ] **데이터 암호화** (미구현 - 선택사항)
  - E2E 암호화 옵션
  - 잠금 메모리 암호화

#### 앱 통합
- [x] **인증 플로우 통합** ✅ 완료
  - RootView: 인증 상태에 따라 Login/Content 전환
  - Firebase 초기화 (FirebaseApp.configure)
  - SettingsView: 실제 인증/동기화 정보 표시
  - DIContainer: 클라우드 서비스 등록
  - SPM 의존성: FirebaseAuth, Firestore, Storage, GoogleSignIn

---

### Phase 7: 테스트 & 품질

#### 단위 테스트
- [ ] UseCase 테스트
- [ ] ViewModel 테스트
- [ ] Repository 테스트

#### 통합 테스트
- [ ] Database 테스트
- [ ] API 테스트

#### UI 테스트
- [ ] Android: Compose Testing
- [ ] iOS: XCUITest

#### 기타
- [ ] Crashlytics 연동
- [ ] Analytics 연동
- [ ] 성능 최적화
- [ ] 접근성 테스트

---

## 파일 구조 가이드

### Android 신규 파일 위치
```
android/app/src/main/java/com/dailymemory/
├── data/
│   ├── remote/
│   │   ├── AIAnalysisService.kt      # Phase 2
│   │   ├── AuthService.kt            # Phase 6
│   │   └── FirestoreService.kt       # Phase 6
│   └── service/
│       ├── SpeechRecognitionService.kt   # Phase 2
│       └── NotificationService.kt        # Phase 5
├── domain/
│   └── usecase/
│       └── ai/
│           └── AnalyzeMemoryUseCase.kt   # Phase 2
└── presentation/
    ├── memory/
    │   └── MemoryDetailScreen.kt     # Phase 1/4
    ├── person/
    │   └── PersonEditScreen.kt       # Phase 1
    ├── photo/
    │   └── PhotoGalleryScreen.kt     # Phase 3
    ├── reminder/
    │   └── ReminderEditScreen.kt     # Phase 5
    └── auth/
        ├── LoginScreen.kt            # Phase 6
        └── SignUpScreen.kt           # Phase 6
```

### iOS 신규 파일 위치
```
ios/DailyMemory/
├── Data/
│   ├── Remote/
│   │   ├── AIAnalysisService.swift   # Phase 2
│   │   ├── AuthService.swift         # Phase 6
│   │   └── FirestoreService.swift    # Phase 6
│   └── Service/
│       ├── SpeechRecognitionService.swift  # Phase 2
│       └── NotificationService.swift       # Phase 5
├── Domain/
│   └── UseCase/
│       └── AI/
│           └── AnalyzeMemoryUseCase.swift  # Phase 2
└── Presentation/
    ├── Memory/
    │   └── MemoryDetailView.swift    # Phase 1/4
    ├── Person/
    │   └── PersonEditView.swift      # Phase 1
    ├── Photo/
    │   └── PhotoGalleryView.swift    # Phase 3
    ├── Reminder/
    │   └── ReminderEditView.swift    # Phase 5
    └── Auth/
        ├── LoginView.swift           # Phase 6
        └── SignUpView.swift          # Phase 6
```

---

## 권장 진행 순서

### Week 1-2: Phase 1 완성
1. 메모리 상세 화면 구현
2. Person 추가/편집 화면 구현
3. 에러 핸들링 및 빈 상태 UI 개선
4. 이미지 로딩 라이브러리 연동

### Week 3-4: Phase 2 핵심
1. Speech-to-Text 서비스 구현
2. AI Analysis API 클라이언트 구현
3. RecordViewModel에 실제 서비스 연동

### Week 5-6: Phase 5 & 6 기반
1. Firebase 프로젝트 설정
2. 인증 화면 및 서비스 구현
3. 리마인더 알림 서비스 구현

### Week 7-8: Phase 3 & 4
1. 사진 촬영/선택 기능
2. AI 검색 고도화
3. 고급 필터링

### Week 9+: Phase 6 & 7
1. 클라우드 동기화
2. 테스트 작성
3. 최적화 및 출시 준비

---

## 참고 TODO 위치

| 파일 | 라인 | 내용 |
|------|------|------|
| `RecordViewModel.kt` | 87 | 실제 음성인식으로 교체 |
| `RecordViewModel.kt` | 129 | AI 분석 API 연동 |
| `HomeScreen.kt` | 62 | 사용자 이름 Preference |
| `SettingsViewModel.kt` | 52 | 로그아웃 구현 |
| `PersonListScreen.kt` | 376 | Coil 이미지 로딩 |
| `Constants.swift` | 8, 13 | App Store ID, API URL |

---

## 세션 시작 시 확인사항

다음 세션에서 작업 시작 전:
1. 이 문서의 진행 상황 확인
2. 원하는 Phase 선택
3. 해당 Phase의 첫 번째 항목부터 순차 진행

**명령어 예시:**
- "Phase 1 잔여 작업 진행해줘"
- "Phase 2 음성인식 구현해줘"
- "Firebase 인증 구현해줘"
