# DailyMemory - Architecture Document

## 프로젝트 구조

```
DailyMemory/
├── docs/                          # 문서
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   └── API.md
│
├── android/                       # Android 앱
│   └── app/
│       └── src/main/
│           ├── java/com/dailymemory/
│           │   ├── data/          # Data Layer
│           │   │   ├── local/     # Room DB
│           │   │   ├── remote/    # Firebase
│           │   │   └── repository/
│           │   │
│           │   ├── domain/        # Domain Layer
│           │   │   ├── model/     # Domain Models
│           │   │   ├── repository/ # Repository Interfaces
│           │   │   └── usecase/   # Use Cases
│           │   │
│           │   ├── presentation/  # Presentation Layer
│           │   │   ├── home/
│           │   │   ├── record/
│           │   │   ├── search/
│           │   │   ├── person/
│           │   │   └── settings/
│           │   │
│           │   ├── di/            # Dependency Injection
│           │   └── util/          # Utilities
│           │
│           └── res/               # Resources
│
├── ios/                           # iOS 앱
│   └── DailyMemory/
│       ├── App/                   # App Entry Point
│       ├── Data/                  # Data Layer
│       │   ├── Local/             # Core Data
│       │   ├── Remote/            # Firebase
│       │   └── Repository/
│       │
│       ├── Domain/                # Domain Layer
│       │   ├── Model/
│       │   ├── Repository/
│       │   └── UseCase/
│       │
│       ├── Presentation/          # Presentation Layer
│       │   ├── Home/
│       │   ├── Record/
│       │   ├── Search/
│       │   ├── Person/
│       │   └── Settings/
│       │
│       ├── Core/                  # Shared Utilities
│       └── Resources/             # Assets, Localization
│
└── firebase/                      # Firebase 설정
    ├── firestore.rules
    ├── firestore.indexes.json
    └── functions/                 # Cloud Functions
```

---

## Clean Architecture 구조

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Screen    │  │  ViewModel  │  │    State    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   UseCase   │  │   Model     │  │ Repository  │     │
│  │             │  │  (Entity)   │  │ (Interface) │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Repository │  │ Local Data  │  │ Remote Data │     │
│  │   (Impl)    │  │   Source    │  │   Source    │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

---

## 데이터 흐름

### 1. 기록 작성 흐름
```
User Input (Voice/Text)
    │
    ▼
┌─────────────────┐
│  RecordScreen   │  ← UI Layer
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ RecordViewModel │  ← Presentation Layer
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ CreateMemory    │  ← Domain Layer (UseCase)
│    UseCase      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│MemoryRepository │  ← Data Layer
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│ Local │ │Remote │
│  DB   │ │ (FB)  │
└───────┘ └───────┘
```

### 2. 동기화 흐름
```
┌─────────────────────────────────────────┐
│              Local Database              │
│  (Room / Core Data)                      │
└────────────────┬────────────────────────┘
                 │
                 │  Sync Manager
                 │  (Offline-first)
                 ▼
┌─────────────────────────────────────────┐
│              Firebase Firestore          │
│  (Cloud Database)                        │
└─────────────────────────────────────────┘

동기화 전략:
1. 쓰기: 로컬 먼저 저장 → 백그라운드에서 Firebase 동기화
2. 읽기: 로컬에서 읽기 (캐시 우선)
3. 충돌: 최신 updatedAt 기준 또는 사용자 선택
```

---

## Firebase 구조

### Firestore Collections
```
users/
  └── {userId}/
        ├── profile: { displayName, email, createdAt }
        │
        ├── memories/
        │     └── {memoryId}: { content, date, personIds, ... }
        │
        ├── persons/
        │     └── {personId}: { name, relationship, ... }
        │
        └── reminders/
              └── {reminderId}: { memoryId, scheduledAt, ... }
```

### Security Rules 개요
```javascript
// 사용자는 자신의 데이터만 접근 가능
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;

  match /memories/{memoryId} {
    allow read, write: if request.auth.uid == userId;
  }
  // ... 동일 패턴
}
```

---

## 핵심 컴포넌트

### Android

| 컴포넌트 | 역할 |
|---------|------|
| `MemoryDao` | Room DB 접근 |
| `MemoryRepository` | 데이터 소스 추상화 |
| `CreateMemoryUseCase` | 기록 생성 비즈니스 로직 |
| `RecordViewModel` | UI 상태 관리 |
| `RecordScreen` | Compose UI |
| `SpeechRecognizerHelper` | 음성 인식 래퍼 |
| `SyncManager` | Firebase 동기화 |
| `NotificationHelper` | 로컬 알림 |

### iOS

| 컴포넌트 | 역할 |
|---------|------|
| `MemoryStore` | Core Data 접근 |
| `MemoryRepository` | 데이터 소스 추상화 |
| `CreateMemoryUseCase` | 기록 생성 비즈니스 로직 |
| `RecordViewModel` | UI 상태 관리 |
| `RecordView` | SwiftUI View |
| `SpeechRecognizer` | Speech Framework 래퍼 |
| `SyncManager` | Firebase 동기화 |
| `NotificationManager` | 로컬 알림 |

---

## 의존성

### Android
```kotlin
// build.gradle.kts (app)
dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")

    // Architecture
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.50")
    ksp("com.google.dagger:hilt-compiler:2.50")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")
}
```

### iOS
```swift
// Package.swift 또는 SPM
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]

// 사용 모듈
// - FirebaseAuth
// - FirebaseFirestore
// - FirebaseMessaging
```

---

## 다음 단계

1. Android 프로젝트 생성 및 기본 구조 설정
2. iOS 프로젝트 생성 및 기본 구조 설정
3. 공통 데이터 모델 구현
4. 로컬 DB 구현
5. 기본 UI 구현
