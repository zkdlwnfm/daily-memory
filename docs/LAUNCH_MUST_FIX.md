# DailyMemory 오픈 전 필수 수정사항

**Date**: 2026-04-06
**Target**: iOS App Store 출시

---

## 🚨 P0: 런칭 불가 (반드시 수정)

### 1. 시뮬레이션 모드 제거/분리
**파일**: `AIAnalysisService.swift:83`, `EmbeddingService.swift:68`, `ImageAnalysisService.swift:115`

**문제**: API 키 없거나 에러 시 가짜 데이터를 반환하는 시뮬레이션 모드가 프로덕션에서도 동작. 사용자에게 가짜 AI 결과를 보여줄 수 있음.

**수정**:
- `#if DEBUG`로 시뮬레이션 모드를 디버그 빌드에만 제한
- 프로덕션에서는 에러 시 명확한 에러 메시지 표시
- "AI 분석을 사용할 수 없습니다" UI 상태 추가

**예상 작업량**: 1일

---

### 2. Privacy Policy & 앱스토어 심사 준비
**파일**: 신규 생성 필요

**문제**: 
- Privacy Policy 웹페이지 없음 (App Store 필수)
- AI 데이터 처리 동의 팝업 없음
- App Privacy Labels (영양 라벨) 미설정
- `Constants.swift:8` — `appStoreId` 비어있음

**수정**:
- Privacy Policy 작성 (데이터 수집 항목: 음성, 텍스트, 사진, 위치, 연락처 정보)
- OpenAI로 전송되는 데이터에 대한 명시적 동의 UI
- App Store Connect에서 Privacy Labels 설정
- 앱 설명, 스크린샷, 카테고리 준비

**예상 작업량**: 2-3일

---

### 3. Rate Limiting 적용
**파일**: `api/src/ai/ai.controller.ts`, `api/src/embedding/embedding.controller.ts`, `api/src/search/search.controller.ts`

**문제**: `rate-limit.service.ts`에 로직은 구현되어 있지만 실제 컨트롤러에 Guard가 적용되지 않음. 악의적 사용자가 OpenAI API를 무제한 호출 가능 → 비용 폭탄.

**수정**:
- 모든 AI/Embedding/Search 컨트롤러에 RateLimitGuard 적용
- OpenAI 대시보드에서 월간 비용 상한 설정 ($100)
- 한도 초과 시 사용자에게 "오늘 AI 사용량을 초과했습니다" 안내

**예상 작업량**: 0.5일

---

### 4. 핵심 플로우 최소 테스트
**파일**: 신규 테스트 파일 생성

**문제**: 테스트 0%. 메모리 저장→조회→검색→동기화 전체 플로우가 검증되지 않음.

**수정** (최소한):
- `SaveMemoryUseCase` 유닛 테스트
- `SemanticSearchUseCase` 유닛 테스트
- Core Data 저장/조회 통합 테스트
- SyncManager 충돌 해결 테스트
- Firebase Auth 로그인 플로우 테스트

**예상 작업량**: 3-4일

---

## ⚠️ P1: 런칭 전 강력 권장

### 5. Crashlytics & 기본 Analytics
**문제**: 크래시 리포트 없이 출시하면 사용자 문제를 알 수 없음.

**수정**:
- Firebase Crashlytics SPM 추가 + 초기화
- 핵심 이벤트 추적: `memory_created`, `search_performed`, `reminder_set`, `photo_added`, `login_completed`
- 사용자 프로퍼티: `total_memories`, `days_active`

**예상 작업량**: 1일

---

### 6. TODO/미완성 코드 정리
| 파일 | 라인 | 문제 | 수정 |
|------|------|------|------|
| `PersistenceController.swift` | 35 | `TODO: Add sample Memory, Person entities` | 삭제하거나 구현 |
| `GenerateSmartRemindersUseCase.swift` | 108 | `TODO: Implement when birthday field is added` | Person 모델에 birthday 필드 추가하거나 TODO 제거 |
| `Constants.swift` | 8 | `appStoreId = ""` | 앱스토어 등록 후 채우기 |

**예상 작업량**: 0.5일

---

### 7. AI 분석 품질 검증 (한국어)
**문제**: 시뮬레이션 모드로 개발해서 실제 OpenAI가 한국어 일기를 얼마나 정확히 분석하는지 테스트 데이터 없음.

**수정**:
- 한국어 일기 샘플 50개 작성
- 실제 API로 분석 돌려서 정확도 측정
- 인물/장소/날짜/금액 추출 각각의 정확도 확인
- 80% 미만이면 프롬프트 튜닝

**예상 작업량**: 1-2일

---

### 8. 에러 핸들링 일관성
**문제**: 많은 try-catch가 에러를 삼킴. 사용자에게 무슨 문제인지 안 알려줌.

**주요 위치**:
- 네트워크 에러 시 오프라인 안내 부재
- AI 분석 실패 시 사일런트 폴백
- 동기화 실패 시 상태 표시 불명확

**예상 작업량**: 1-2일

---

## 📋 P2: 런칭 후 빠르게 (Fast-Follow)

| # | 항목 | 설명 |
|---|------|------|
| 9 | 동기화 충돌 UI | Last-write-wins 대신 사용자 선택 UI |
| 10 | 벡터 검색 성능 | 5000건 이상 시 서버사이드 검색으로 전환 |
| 11 | Android Firebase | 클라우드 동기화/인증 구현 |
| 12 | 온보딩 플로우 | 첫 사용자 가이드 및 가치 전달 |
| 13 | 다크모드 | 야간 사용자 경험 개선 |

---

## 📅 추천 일정 (iOS 런칭 기준)

```
Week 1 (4/7 - 4/11):
├── Day 1: 시뮬레이션 모드 분리 (#1)
├── Day 2-3: Privacy Policy + 앱스토어 준비 (#2)
├── Day 3: Rate Limiting 적용 (#3)
└── Day 4-5: AI 품질 검증 (#7) + TODO 정리 (#6)

Week 2 (4/14 - 4/18):
├── Day 1-4: 핵심 테스트 작성 (#4)
├── Day 4: Crashlytics/Analytics (#5)
└── Day 5: 에러 핸들링 개선 (#8)

Week 3 (4/21 - 4/23):
├── Day 1-2: 최종 QA + 버그 수정
└── Day 3: App Store 제출

→ 심사 통과 후 출시 (약 1-3일 소요)
```

**예상 런칭 가능일: 4월 마지막 주**
