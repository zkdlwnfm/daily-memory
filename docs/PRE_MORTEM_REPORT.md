# Pre-Mortem: DailyMemory 런칭 전 리스크 분석

**Date**: 2026-04-06
**Status**: Draft
**Analyst**: PM Toolkit (Claude)

---

## Risk Summary

- **Tigers**: 9 (🚫 Launch-blocking: 4, ⚡ Fast-follow: 3, 👁️ Track: 2)
- **Paper Tigers**: 3
- **Elephants**: 3

---

## 🚫 Launch-Blocking Tigers

반드시 런칭 전에 해결해야 하는 리스크들입니다.

| # | Risk | Likelihood | Impact | Mitigation | Owner | Deadline |
|---|------|-----------|--------|-----------|-------|----------|
| T1 | **시뮬레이션 모드가 프로덕션에서 활성화** — AI 분석/임베딩/이미지 서비스가 API 키 없으면 가짜 데이터 반환. 사용자는 AI가 작동한다고 믿지만 실제론 더미 결과 | 높음 | 치명적 | API 키 미설정 시 시뮬레이션이 아닌 명확한 에러 메시지 표시. 프로덕션 빌드에서 시뮬레이션 모드 완전 제거 | Dev | 런칭 1주 전 |
| T2 | **개인정보 보호 미흡으로 앱스토어 심사 거부** — 일기/기억 데이터를 OpenAI API로 전송하는데, Privacy Policy 부재. Apple은 AI 처리 관련 정보 공개를 요구 | 높음 | 치명적 | ① Privacy Policy 작성 (데이터 수집/AI 처리 명시) ② App Privacy Labels 설정 ③ 앱 내 AI 데이터 처리 동의 팝업 추가 | PM+Legal | 런칭 2주 전 |
| T3 | **Rate Limiting 미적용 — API 비용 폭탄 위험** — 백엔드에 rate-limit 로직이 구현되어 있지만 컨트롤러에 적용 안 됨. 악의적 사용자가 OpenAI API를 무제한 호출 가능 | 높음 | 치명적 | ① 모든 AI/Embedding 컨트롤러에 @UseGuards(RateLimitGuard) 적용 ② 사용자별 일일 한도 강제 ③ 비용 알림 설정 | Backend Dev | 런칭 1주 전 |
| T4 | **테스트 0% — 크리티컬 패스 검증 안 됨** — 유닛/통합/UI 테스트 전무. 저장→동기화→검색 전체 플로우가 검증되지 않음. 출시 후 데이터 손실 리스크 | 높음 | 높음 | 최소한 ① 핵심 UseCase 8개 유닛테스트 ② 저장→조회 통합테스트 ③ 동기화 충돌 테스트 작성. 전체 커버리지보다 크리티컬 패스 우선 | Dev | 런칭 1주 전 |

---

## ⚡ Fast-Follow Tigers

런칭 직후 첫 스프린트에서 해결해야 할 리스크들입니다.

| # | Risk | Likelihood | Impact | Planned Response | Owner |
|---|------|-----------|--------|-----------------|-------|
| T5 | **오프라인→온라인 동기화 충돌로 데이터 손실** — Last-write-wins 전략이 동시 편집 시 한쪽 데이터를 덮어씀. 사용자가 두 기기에서 작업 후 동기화하면 한쪽이 소실 | 중간 | 높음 | ① 충돌 시 사용자에게 "어떤 버전을 유지할까요?" UI 추가 ② 충돌 이력 보관 ③ 필드 단위 머지 검토 |Dev |
| T6 | **벡터 검색 O(n) 성능 — 메모리 1만개 넘으면 검색 느려짐** — 현재 모든 임베딩을 순차 비교. 초기엔 문제 없지만 활성 사용자는 빠르게 1만건 도달 가능 | 중간 | 중간 | ① 성능 모니터링 추가 ② 5000건 이상 시 pgvector 서버 사이드 검색으로 자동 전환 ③ HNSW 인덱스 적용 검토 | Backend Dev |
| T7 | **Crashlytics/Analytics 미연동 — 문제 발생 시 원인 파악 불가** — 크래시 리포트, 사용자 행동 데이터 없이 출시하면 문제 대응이 사후적/느림 | 높음 | 중간 | ① Firebase Crashlytics 연동 (1일 작업) ② 핵심 이벤트 10개 Analytics 추적 ③ 에러 로깅 서비스 연동 | Dev |

---

## 👁️ Track Tigers

모니터링하면서 추적할 리스크들입니다.

| # | Risk | Trigger Condition | Response Plan |
|---|------|-------------------|---------------|
| T8 | **OpenAI API 비용이 예상 초과** — 사용자당 하루 3-5회 AI 분석 + 임베딩 생성. 1000명 기준 월 $50-200 예상이지만, 헤비유저/이미지 분석 시 급증 가능 | 월 비용 > $300 | ① 이미지 분석 횟수 제한 강화 ② 캐싱 레이어 추가 ③ 로컬 모델(on-device) 검토 |
| T9 | **Apple/Google 로그인 토큰 만료 시 사일런트 로그아웃** — Firebase Auth 토큰 리프레시 실패 시 사용자가 갑자기 로그아웃. 오프라인 데이터는 유지되지만 동기화 중단 | 사용자 리포트 3건 이상 | ① 토큰 리프레시 에러 핸들링 강화 ② 재로그인 안내 UX 추가 |

---

## 📄 Paper Tigers

걱정되지만 실제로는 관리 가능한 리스크들입니다.

| # | Concern | Why It's Manageable |
|---|---------|-------------------|
| P1 | **Android Firebase 미구현이 런칭을 막는다** | iOS 먼저 출시하는 전략이므로 Android는 로컬 전용으로 베타 제공 가능. Firebase 연동은 Android v2에서 추가하면 됨 |
| P2 | **E2E 암호화 없으면 사용자가 안 쓴다** | 대부분의 일기앱(Day One, Journey 등)도 초기엔 E2E 없이 출시. Firebase 보안 규칙 + HTTPS + 잠금 기능으로 충분한 기본 보안 제공. Premium 기능으로 추후 추가 |
| P3 | **시맨틱 검색이 한국어를 잘 못 처리한다** | OpenAI text-embedding-3-small은 한국어 지원 양호. 키워드 폴백 검색이 있어 최소한의 검색 품질은 보장됨. 실사용 데이터로 품질 모니터링 후 개선 |

---

## 🐘 Elephants in the Room

팀이 알고 있지만 논의를 회피하는 불편한 진실들입니다.

| # | Elephant | Why It Matters | Conversation Starter |
|---|----------|---------------|---------------------|
| E1 | **수익 모델이 불명확하다** — Free tier 제한(30 memories/month)만 있고, Premium 과금 구조/결제 연동이 전혀 없음. 무료만으로 충분하면 과금 전환이 안 됨 | API 비용은 사용자가 늘수록 증가하는데, 수익이 0이면 지속 불가. 1000명만 돼도 월 $100+ OpenAI 비용 발생 | "무료 사용자 1000명이 되면 월 서버비가 얼마인지 계산해봤나? Premium으로 전환하는 시나리오를 구체화하자" |
| E2 | **혼자/소규모 팀이 iOS + Android + Backend + Airflow를 유지보수할 수 있는가?** — 4개 플랫폼 코드베이스, 3개 외부 서비스 의존. 한 사람이 모두 관리하기엔 범위가 너무 넓음 | 버그 리포트가 들어오면 iOS/Android/Backend 중 어디 문제인지 추적하는 것만으로도 시간 소모. Airflow DAG까지 관리하면 과부하 | "MVP 런칭은 iOS만 집중하고, Android는 6개월 후로 미루는 게 현실적이지 않은가?" |
| E3 | **AI 분석 품질이 실제로 '좋은' 수준인지 검증한 적 없다** — 시뮬레이션 모드로 개발해서, 실제 OpenAI 응답이 한국어 일기 맥락에서 얼마나 정확한지 테스트 데이터가 없음 | 사용자가 "어제 엄마랑 카페 갔어"를 입력했을 때, AI가 인물='엄마', 장소='카페'를 정확히 추출 못하면 핵심 가치가 무너짐 | "실제 API로 한국어 일기 50개를 분석해보고 정확도를 측정하자. 80% 미만이면 프롬프트 튜닝이 필요하다" |

---

## ✅ Go/No-Go Checklist

### 런칭 전 필수 (Launch-Blocking)
- [ ] T1: 프로덕션 빌드에서 시뮬레이션 모드 제거/비활성화
- [ ] T2: Privacy Policy 작성 및 앱 내 AI 데이터 처리 동의 구현
- [ ] T3: Rate Limiting을 API 컨트롤러에 적용
- [ ] T4: 핵심 플로우 최소 테스트 작성 (저장, 동기화, 검색)

### 런칭 전 권장
- [ ] Firebase Crashlytics 연동 (T7)
- [ ] 핵심 Analytics 이벤트 설정 (T7)
- [ ] App Store 심사용 스크린샷/설명 준비
- [ ] 실제 한국어 데이터로 AI 분석 품질 테스트 (E3)
- [ ] OpenAI 비용 예산 및 알림 설정 (T8)

### 런칭 직후 (Fast-Follow)
- [ ] T5: 동기화 충돌 UI 개선
- [ ] T6: 벡터 검색 성능 모니터링
- [ ] 사용자 피드백 수집 채널 구축
- [ ] 수익 모델 구체화 (E1)

### Rollback Plan
- API 서버 다운 시: 앱은 오프라인 모드로 자동 전환 (로컬 저장 유지)
- OpenAI API 장애 시: 시뮬레이션 모드 대신 "AI 분석 일시 중단" 메시지 표시
- Firebase 장애 시: 오프라인 퍼스트이므로 로컬 데이터로 정상 작동
- 치명적 버그 발견 시: App Store에서 앱 숨김 처리 + 긴급 패치

---

## Next Steps

1. **Privacy Policy 작성** → `/privacy-policy` 스킬로 생성 가능
2. **테스트 시나리오 작성** → `/test-scenarios` 스킬로 크리티컬 패스 테스트 생성
3. **런칭 체크리스트 상세화** → 위 Go/No-Go를 팀 태스크로 변환
