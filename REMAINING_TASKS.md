# DailyMemory 잔여 작업 목록

> 마지막 업데이트: 2026-03-24

이 문서는 각 Phase에서 제외되거나 미완료된 항목들을 정리합니다.

---

## Phase 3: 사진 관리 (75% 완료)

### 제외된 항목

#### AI 이미지 분석
- **설명**: 사진에서 객체, 장면, 텍스트를 자동으로 인식하고 메모리에 태그 추가
- **필요 기술**:
  - Google Cloud Vision API 또는 OpenAI Vision API
  - API 키 설정 및 비용 관리
- **구현 위치**:
  - Android: `data/remote/ImageAnalysisService.kt`
  - iOS: `Data/Remote/ImageAnalysisService.swift`
- **기능 상세**:
  - [ ] 객체 인식 (사람, 동물, 물건 등)
  - [ ] 장면 설명 (실내/실외, 장소 유형)
  - [ ] OCR (텍스트 추출)
  - [ ] 얼굴 인식 및 Person 자동 연결
- **우선순위**: 낮음 (선택 사항)
- **예상 난이도**: 중간

---

## Phase 4: 메모리 상세 & AI 검색 (75% 완료)

### 제외된 항목

#### AI 시맨틱 검색
- **설명**: 자연어 질의를 이해하고 의미적으로 관련된 메모리를 찾는 기능
- **필요 기술**:
  - 텍스트 임베딩 API (OpenAI Embeddings, Cohere 등)
  - 벡터 데이터베이스 또는 로컬 유사도 검색
- **구현 위치**:
  - Android: `data/remote/EmbeddingService.kt`, `domain/usecase/search/SemanticSearchUseCase.kt`
  - iOS: `Data/Remote/EmbeddingService.swift`, `Domain/UseCase/Search/SemanticSearchUseCase.swift`
- **기능 상세**:
  - [ ] 메모리 저장 시 임베딩 벡터 생성
  - [ ] 검색 쿼리 임베딩 생성
  - [ ] 코사인 유사도 기반 검색
  - [ ] 자연어 질의 처리 ("작년에 엄마랑 뭐했지?")
  - [ ] 검색 결과 랭킹
- **DB 스키마 변경 필요**:
  - Memory 테이블에 `embedding` 컬럼 추가 (BLOB 또는 별도 테이블)
- **우선순위**: 중간
- **예상 난이도**: 높음

---

## Phase 5: 스마트 리마인더 (80% 완료)

### 제외된 항목

#### 위치 기반 리마인더
- **설명**: 특정 장소에 도착하거나 떠날 때 알림 발송
- **필요 기술**:
  - 지오펜싱 API
  - 백그라운드 위치 권한
  - 배터리 최적화
- **구현 위치**:
  - Android: `data/service/GeofenceService.kt`
  - iOS: `Data/Service/GeofenceService.swift`
- **기능 상세**:
  - [ ] 장소 검색 및 선택 UI
  - [ ] 지오펜스 등록/해제
  - [ ] 도착/출발 조건 설정
  - [ ] 백그라운드 위치 모니터링
  - [ ] 배터리 효율적 구현
- **권한 요구사항**:
  - Android: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
  - iOS: `NSLocationAlwaysAndWhenInUseUsageDescription`
- **우선순위**: 낮음 (선택 사항)
- **예상 난이도**: 높음

---

## Phase 6: 클라우드 동기화 & 인증 (0% 완료)

### Firebase 인증

#### 로그인/회원가입 화면
- **구현 위치**:
  - Android: `presentation/auth/LoginScreen.kt`, `SignUpScreen.kt`
  - iOS: `Presentation/Auth/LoginView.swift`, `SignUpView.swift`
- **기능 상세**:
  - [ ] 이메일/비밀번호 로그인
  - [ ] 회원가입 폼 (이메일, 비밀번호, 이름)
  - [ ] 비밀번호 찾기
  - [ ] Google 소셜 로그인
  - [ ] Apple 소셜 로그인 (iOS)
  - [ ] 로그인 상태 유지
  - [ ] 로그아웃

#### 인증 서비스
- **구현 위치**:
  - Android: `data/remote/AuthService.kt`
  - iOS: `Data/Remote/AuthService.swift`
- **기능 상세**:
  - [ ] Firebase Authentication 연동
  - [ ] 토큰 관리 및 갱신
  - [ ] 사용자 세션 관리

#### 사용자 프로필 관리
- **기능 상세**:
  - [ ] 프로필 이름 수정
  - [ ] 프로필 사진 업로드
  - [ ] 프리미엄 상태 확인

### 클라우드 동기화

#### Firebase Firestore 연동
- **구현 위치**:
  - Android: `data/remote/FirestoreService.kt`
  - iOS: `Data/Remote/FirestoreService.swift`
- **기능 상세**:
  - [ ] Memory 컬렉션 CRUD
  - [ ] Person 컬렉션 CRUD
  - [ ] Reminder 컬렉션 CRUD
  - [ ] 사용자별 데이터 분리 (`/users/{userId}/memories`)

#### 오프라인 우선 동기화
- **기능 상세**:
  - [ ] 로컬 변경사항 큐잉
  - [ ] 네트워크 복구 시 자동 동기화
  - [ ] 충돌 해결 전략 (Last Write Wins 또는 Merge)
  - [ ] 동기화 상태 UI 표시
  - [ ] 수동 동기화 버튼

#### Firebase Storage
- **기능 상세**:
  - [ ] 사진 업로드
  - [ ] 음성 파일 업로드 (선택)
  - [ ] 업로드 진행률 표시
  - [ ] 다운로드 및 캐싱

#### 데이터 암호화
- **기능 상세**:
  - [ ] E2E 암호화 옵션
  - [ ] 잠금 메모리 클라이언트 사이드 암호화
  - [ ] 암호화 키 관리

### 설정 필요 사항
- [ ] Firebase 프로젝트 생성
- [ ] `google-services.json` (Android)
- [ ] `GoogleService-Info.plist` (iOS)
- [ ] Firebase Console에서 Authentication 활성화
- [ ] Firestore 보안 규칙 설정
- [ ] Storage 보안 규칙 설정

---

## Phase 7: 테스트 & 품질 (0% 완료)

### 단위 테스트

#### UseCase 테스트
- **Android 위치**: `app/src/test/java/com/dailymemory/domain/usecase/`
- **iOS 위치**: `DailyMemoryTests/Domain/UseCase/`
- **테스트 대상**:
  - [ ] SaveMemoryUseCaseTest
  - [ ] SearchMemoriesUseCaseTest
  - [ ] AnalyzeMemoryUseCaseTest
  - [ ] SaveReminderUseCaseTest
  - [ ] GenerateSmartRemindersUseCaseTest
  - 기타 18개 UseCase

#### ViewModel 테스트
- **테스트 대상**:
  - [ ] HomeViewModelTest
  - [ ] RecordViewModelTest
  - [ ] SearchViewModelTest
  - [ ] ReminderEditViewModelTest

#### Repository 테스트
- **테스트 대상**:
  - [ ] MemoryRepositoryTest
  - [ ] PersonRepositoryTest
  - [ ] ReminderRepositoryTest

### 통합 테스트

#### Database 테스트
- **Android**: Room Database 테스트
- **iOS**: Core Data 테스트
- **테스트 대상**:
  - [ ] CRUD 작업
  - [ ] 마이그레이션
  - [ ] 쿼리 성능

#### API 테스트
- **테스트 대상**:
  - [ ] AIAnalysisService 모킹 테스트
  - [ ] 네트워크 에러 핸들링

### UI 테스트

#### Android Compose Testing
- **위치**: `app/src/androidTest/java/com/dailymemory/`
- **테스트 대상**:
  - [ ] HomeScreen 네비게이션
  - [ ] RecordScreen 음성/텍스트 입력
  - [ ] SearchScreen 필터링
  - [ ] ReminderEditScreen 폼 검증

#### iOS XCUITest
- **위치**: `DailyMemoryUITests/`
- **테스트 대상**:
  - [ ] HomeView 네비게이션
  - [ ] RecordView 입력
  - [ ] SearchView 필터링
  - [ ] ReminderEditView 폼 검증

### 기타 품질 관리

#### Crashlytics 연동
- **기능**:
  - [ ] Firebase Crashlytics 설정
  - [ ] 크래시 리포트 수집
  - [ ] 비치명적 오류 로깅

#### Analytics 연동
- **기능**:
  - [ ] Firebase Analytics 설정
  - [ ] 주요 이벤트 트래킹
  - [ ] 사용자 행동 분석

#### 성능 최적화
- **항목**:
  - [ ] 메모리 사용량 프로파일링
  - [ ] 이미지 로딩 최적화
  - [ ] 데이터베이스 쿼리 최적화
  - [ ] 앱 시작 시간 최적화

#### 접근성 테스트
- **항목**:
  - [ ] VoiceOver/TalkBack 지원
  - [ ] 색상 대비 검사
  - [ ] 터치 타겟 크기 검사
  - [ ] 동적 글꼴 크기 지원

---

## 우선순위 요약

### 높음 (핵심 기능)
1. Phase 6: Firebase 인증 (로그인/회원가입)
2. Phase 6: Firestore 동기화
3. Phase 7: 주요 UseCase 단위 테스트

### 중간 (향상 기능)
4. Phase 4: AI 시맨틱 검색
5. Phase 6: 오프라인 동기화
6. Phase 7: UI 테스트

### 낮음 (선택 기능)
7. Phase 3: AI 이미지 분석
8. Phase 5: 위치 기반 리마인더
9. Phase 6: E2E 암호화
10. Phase 7: Crashlytics/Analytics

---

## 예상 소요 시간

| Phase | 항목 | 예상 시간 |
|-------|------|----------|
| Phase 3 | AI 이미지 분석 | 2-3일 |
| Phase 4 | AI 시맨틱 검색 | 3-5일 |
| Phase 5 | 위치 기반 리마인더 | 3-4일 |
| Phase 6 | Firebase 인증 | 2-3일 |
| Phase 6 | Firestore 동기화 | 4-5일 |
| Phase 6 | 오프라인 동기화 | 3-4일 |
| Phase 6 | Storage 연동 | 1-2일 |
| Phase 6 | 암호화 | 2-3일 |
| Phase 7 | 단위 테스트 | 3-4일 |
| Phase 7 | 통합 테스트 | 2-3일 |
| Phase 7 | UI 테스트 | 2-3일 |
| Phase 7 | 품질 관리 | 2-3일 |

**총 예상 소요 시간**: 약 4-6주

---

## 시작하기

다음 Phase를 진행하려면:
```
"Phase 6 진행해" - 클라우드 동기화 & 인증
"Phase 7 진행해" - 테스트 & 품질
"AI 이미지 분석 구현해" - 특정 기능만 구현
```
