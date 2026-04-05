# DailyMemory 구현 계획서

> 작성일: 2025-03-24
> 목표: 남은 Phase 3~7 기능 완료

---

## 1. 구현 순서 및 일정

### Phase 3 완료: AI 이미지 분석 (2-3일)
### Phase 4 완료: AI 시맨틱 검색 (3-5일)
### Phase 5 완료: 위치 기반 리마인더 (3-4일)
### Phase 6: 클라우드 동기화 & 인증 (10-14일)
### Phase 7: 테스트 & 품질 (7-10일)

**총 예상 기간: 25-36일 (약 5-7주)**

---

## 2. Phase 3 완료: AI 이미지 분석

### 2.1 목표
사진에서 객체, 장면, 텍스트를 자동 인식하여 메모리에 태그 추가

### 2.2 기술 스택
- **API**: OpenAI Vision API (GPT-4o) 또는 Google Cloud Vision
- **비용**: OpenAI - $0.01/이미지, Google - $1.50/1000이미지

### 2.3 구현 항목

#### Android
```
app/src/main/java/com/dailymemory/
├── data/remote/
│   └── ImageAnalysisService.kt       # Vision API 호출
├── domain/usecase/photo/
│   └── AnalyzeImageUseCase.kt        # 이미지 분석 UseCase
└── presentation/record/
    └── RecordViewModel.kt            # 사진 추가 시 자동 분석
```

#### iOS
```
DailyMemory/
├── Data/Remote/
│   └── ImageAnalysisService.swift    # Vision API 호출
├── Domain/UseCase/Photo/
│   └── AnalyzeImageUseCase.swift     # 이미지 분석 UseCase
└── Presentation/Record/
    └── RecordView.swift              # 사진 추가 시 자동 분석
```

### 2.4 기능 상세
| 기능 | 설명 | 우선순위 |
|------|------|----------|
| 객체 인식 | 사람, 동물, 물건 감지 | 높음 |
| 장면 설명 | 실내/실외, 장소 유형 | 높음 |
| OCR | 이미지 내 텍스트 추출 | 중간 |
| 얼굴 인식 | Person 자동 연결 | 낮음 |

### 2.5 API 응답 예시
```json
{
  "objects": ["person", "cake", "table"],
  "scene": "birthday party, indoor",
  "text": "Happy Birthday!",
  "faces": 3,
  "description": "A birthday celebration with 3 people around a cake"
}
```

### 2.6 설정 필요
- [ ] OpenAI API 키 또는 Google Cloud Vision 키
- [ ] 환경변수 설정 (API_KEY)
- [ ] 비용 제한 설정

---

## 3. Phase 4 완료: AI 시맨틱 검색

### 3.1 목표
자연어 질의로 의미적으로 관련된 메모리 검색

### 3.2 기술 스택
- **임베딩**: OpenAI text-embedding-3-small ($0.02/1M tokens)
- **벡터 검색**: 로컬 코사인 유사도 (SQLite/CoreData 저장)

### 3.3 구현 항목

#### Android
```
app/src/main/java/com/dailymemory/
├── data/remote/
│   └── EmbeddingService.kt           # 임베딩 API 호출
├── data/local/
│   └── VectorSearchEngine.kt         # 코사인 유사도 검색
├── domain/usecase/search/
│   └── SemanticSearchUseCase.kt      # 시맨틱 검색 UseCase
└── presentation/search/
    └── SearchViewModel.kt            # AI 검색 UI 연동
```

#### iOS
```
DailyMemory/
├── Data/Remote/
│   └── EmbeddingService.swift        # 임베딩 API 호출
├── Data/Local/
│   └── VectorSearchEngine.swift      # 코사인 유사도 검색
├── Domain/UseCase/Search/
│   └── SemanticSearchUseCase.swift   # 시맨틱 검색 UseCase
└── Presentation/Search/
    └── SearchView.swift              # AI 검색 UI 연동
```

### 3.4 데이터베이스 변경
```sql
-- Memory 테이블에 embedding 컬럼 추가
ALTER TABLE Memory ADD COLUMN embedding BLOB;
-- 또는 별도 테이블
CREATE TABLE MemoryEmbedding (
  memoryId TEXT PRIMARY KEY,
  embedding BLOB NOT NULL,
  createdAt TIMESTAMP
);
```

### 3.5 검색 플로우
```
1. 사용자 입력: "작년에 엄마랑 뭐했지?"
2. 쿼리 임베딩 생성 (1536차원 벡터)
3. 모든 메모리 임베딩과 코사인 유사도 계산
4. 상위 N개 결과 반환 (유사도 0.7 이상)
5. AI 요약 생성 (선택)
```

### 3.6 성능 최적화
- 임베딩 캐싱 (메모리 저장 시 생성)
- 배치 처리 (기존 메모리 일괄 임베딩)
- 인덱싱 (대량 데이터 시 FAISS 고려)

---

## 4. Phase 5 완료: 위치 기반 리마인더

### 4.1 목표
특정 장소 도착/출발 시 자동 알림

### 4.2 기술 스택
- **Android**: Google Geofencing API
- **iOS**: CoreLocation CLCircularRegion

### 4.3 구현 항목

#### Android
```
app/src/main/java/com/dailymemory/
├── data/service/
│   ├── GeofenceService.kt            # 지오펜스 관리
│   └── GeofenceBroadcastReceiver.kt  # 이벤트 수신
├── domain/model/
│   └── LocationReminder.kt           # 위치 리마인더 모델
└── presentation/reminder/
    └── LocationPickerScreen.kt       # 장소 선택 UI
```

#### iOS
```
DailyMemory/
├── Data/Service/
│   └── GeofenceService.swift         # 지오펜스 관리
├── Domain/Model/
│   └── LocationReminder.swift        # 위치 리마인더 모델
└── Presentation/Reminder/
    └── LocationPickerView.swift      # 장소 선택 UI
```

### 4.4 권한 요구
```xml
<!-- Android -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```
```swift
// iOS Info.plist
NSLocationAlwaysAndWhenInUseUsageDescription
NSLocationWhenInUseUsageDescription
```

### 4.5 데이터베이스 변경
```sql
-- Reminder 테이블에 위치 정보 추가
ALTER TABLE Reminder ADD COLUMN latitude REAL;
ALTER TABLE Reminder ADD COLUMN longitude REAL;
ALTER TABLE Reminder ADD COLUMN radius REAL DEFAULT 100;
ALTER TABLE Reminder ADD COLUMN triggerType TEXT; -- 'enter' | 'exit' | 'both'
```

---

## 5. Phase 6: 클라우드 동기화 & 인증

### 5.1 Firebase 프로젝트 설정 (1일)

#### 필요 작업
- [ ] Firebase Console에서 프로젝트 생성
- [ ] Android 앱 등록 → `google-services.json` 다운로드
- [ ] iOS 앱 등록 → `GoogleService-Info.plist` 다운로드
- [ ] Authentication 활성화 (Email, Google, Apple)
- [ ] Firestore Database 생성
- [ ] Storage 버킷 생성

#### Firebase 보안 규칙
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}

// Storage Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5.2 인증 구현 (2-3일)

#### 파일 구조
```
Android:
├── data/remote/AuthService.kt
├── domain/repository/AuthRepository.kt
├── domain/usecase/auth/
│   ├── SignInUseCase.kt
│   ├── SignUpUseCase.kt
│   ├── SignOutUseCase.kt
│   └── GetCurrentUserUseCase.kt
└── presentation/auth/
    ├── LoginScreen.kt
    ├── SignUpScreen.kt
    └── AuthViewModel.kt

iOS:
├── Data/Remote/AuthService.swift
├── Domain/Repository/AuthRepository.swift
├── Domain/UseCase/Auth/
│   ├── SignInUseCase.swift
│   ├── SignUpUseCase.swift
│   ├── SignOutUseCase.swift
│   └── GetCurrentUserUseCase.swift
└── Presentation/Auth/
    ├── LoginView.swift
    ├── SignUpView.swift
    └── AuthViewModel.swift
```

#### 인증 기능
| 기능 | 설명 | 우선순위 |
|------|------|----------|
| 이메일 로그인 | 이메일/비밀번호 인증 | 높음 |
| 회원가입 | 이메일, 비밀번호, 이름 | 높음 |
| 비밀번호 찾기 | 이메일로 재설정 링크 | 높음 |
| Google 로그인 | OAuth 소셜 로그인 | 중간 |
| Apple 로그인 | iOS Sign in with Apple | 중간 |
| 자동 로그인 | 토큰 유지 | 높음 |

### 5.3 Firestore 동기화 (4-5일)

#### 데이터 구조
```
/users/{userId}/
├── memories/{memoryId}
│   ├── id: string
│   ├── content: string
│   ├── photos: array<PhotoRef>
│   ├── extractedPersons: array<string>
│   ├── extractedLocation: string?
│   ├── category: string
│   ├── importance: number
│   ├── isLocked: boolean
│   ├── recordedAt: timestamp
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   └── syncStatus: string
├── persons/{personId}
│   ├── id: string
│   ├── name: string
│   ├── relationship: string
│   ├── meetingCount: number
│   └── ...
└── reminders/{reminderId}
    ├── id: string
    ├── title: string
    ├── scheduledAt: timestamp
    └── ...
```

#### 동기화 서비스
```
├── data/remote/
│   ├── FirestoreService.kt/.swift    # CRUD 작업
│   └── SyncManager.kt/.swift         # 동기화 로직
├── domain/usecase/sync/
│   ├── SyncMemoriesUseCase.kt/.swift
│   ├── SyncPersonsUseCase.kt/.swift
│   └── SyncRemindersUseCase.kt/.swift
```

### 5.4 오프라인 우선 동기화 (3-4일)

#### 동기화 전략
```
1. 로컬 우선 저장 (즉시 반영)
2. 변경사항 큐에 추가 (pendingChanges)
3. 네트워크 가능 시 동기화
4. 충돌 해결: Last Write Wins (updatedAt 비교)
```

#### 동기화 상태
```kotlin
enum class SyncStatus {
    SYNCED,      // 동기화 완료
    PENDING,     // 동기화 대기
    CONFLICT,    // 충돌 발생
    LOCAL_ONLY   // 로컬 전용
}
```

### 5.5 Firebase Storage (1-2일)

#### 사진 업로드 플로우
```
1. 로컬에 사진 저장 (즉시)
2. 백그라운드에서 Storage 업로드
3. 업로드 완료 시 URL 저장
4. 다른 기기에서 URL로 다운로드
```

#### 파일 경로
```
/users/{userId}/photos/{memoryId}/{photoId}.jpg
/users/{userId}/photos/{memoryId}/{photoId}_thumb.jpg
```

### 5.6 데이터 암호화 (2-3일, 선택)

#### 암호화 대상
- 잠금된 메모리 (isLocked=true)
- 선택적 E2E 암호화

#### 구현 방식
```
- AES-256 대칭키 암호화
- 키 저장: Android Keystore / iOS Keychain
- 서버에는 암호화된 데이터만 저장
```

---

## 6. Phase 7: 테스트 & 품질

### 6.1 단위 테스트 (3-4일)

#### 테스트 대상 UseCase
```
Android: app/src/test/java/com/dailymemory/domain/usecase/
iOS: DailyMemoryTests/Domain/UseCase/

- [ ] SaveMemoryUseCaseTest
- [ ] GetMemoryUseCaseTest
- [ ] UpdateMemoryUseCaseTest
- [ ] DeleteMemoryUseCaseTest
- [ ] SearchMemoriesUseCaseTest
- [ ] AnalyzeMemoryUseCaseTest
- [ ] SavePersonUseCaseTest
- [ ] GetAllPersonsUseCaseTest
- [ ] SaveReminderUseCaseTest
- [ ] GetUpcomingRemindersUseCaseTest
- [ ] CompleteReminderUseCaseTest
```

#### 테스트 프레임워크
- **Android**: JUnit5, MockK, Turbine (Flow 테스트)
- **iOS**: XCTest, Swift Testing

### 6.2 통합 테스트 (2-3일)

#### Database 테스트
```
- [ ] Room/CoreData CRUD 테스트
- [ ] 마이그레이션 테스트
- [ ] 쿼리 성능 테스트
```

#### API 테스트
```
- [ ] AI 서비스 모킹 테스트
- [ ] 네트워크 에러 핸들링
- [ ] Firebase 연동 테스트 (선택)
```

### 6.3 UI 테스트 (2-3일)

#### Android (Compose Testing)
```kotlin
@Test
fun homeScreen_displaysMemories() {
    composeTestRule.setContent { HomeScreen() }
    composeTestRule.onNodeWithText("Recent Memories").assertIsDisplayed()
}
```

#### iOS (XCUITest)
```swift
func testHomeView_displaysMemories() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.staticTexts["Recent Memories"].exists)
}
```

### 6.4 품질 관리 (2-3일)

#### Crashlytics 설정
```
- [ ] Firebase Crashlytics 연동
- [ ] 비치명적 오류 로깅
- [ ] 크래시 알림 설정
```

#### Analytics 설정
```
- [ ] Firebase Analytics 연동
- [ ] 주요 이벤트 트래킹
  - memory_created
  - memory_searched
  - reminder_completed
  - app_opened
```

#### 성능 최적화
```
- [ ] 메모리 프로파일링
- [ ] 이미지 로딩 최적화 (lazy loading)
- [ ] 리스트 성능 (RecyclerView/LazyColumn)
- [ ] 앱 시작 시간 측정
```

---

## 7. 마일스톤 체크리스트

### Week 1-2: Phase 3-5 완료
- [ ] AI 이미지 분석 구현
- [ ] AI 시맨틱 검색 구현
- [ ] 위치 기반 리마인더 구현

### Week 3-4: Phase 6 (인증 & 기본 동기화)
- [ ] Firebase 프로젝트 설정
- [ ] 로그인/회원가입 구현
- [ ] Firestore 기본 CRUD
- [ ] 사진 Storage 업로드

### Week 5: Phase 6 (고급 동기화)
- [ ] 오프라인 우선 동기화
- [ ] 충돌 해결
- [ ] 암호화 (선택)

### Week 6-7: Phase 7 (테스트)
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성
- [ ] UI 테스트 작성
- [ ] 품질 관리 도구 설정

---

## 8. 시작 명령어

```
"Phase 3 완료해" - AI 이미지 분석
"Phase 4 완료해" - AI 시맨틱 검색
"Phase 5 완료해" - 위치 기반 리마인더
"Phase 6 시작해" - 클라우드 동기화 (인증부터)
"Phase 7 시작해" - 테스트 작성
```
