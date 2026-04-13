# Eisenhower Matrix + Calendar View Implementation Plan

> Created: 2026-04-12
> Status: Draft — Pending Confirmation
> Target: iOS Primary, Android Secondary

---

## 1. Overview

DailyMemory에 두 가지 주요 기능을 추가한다:

1. **Eisenhower Matrix** — AI가 메모리에서 할일/약속을 추출하여 긴급도+중요도 기반 4사분면에 자동 배치
2. **Calendar View** — 메모리, 태스크, 리마인더를 월간 캘린더와 일별 타임라인으로 시각화

### Core Integration Flow

```
기록(Record)
  → AI 분석(Analysis)
    → 할일/약속 자동 추출(Task Extraction)
      → Calendar (언제?)
      → Matrix (얼마나 중요?)
        → Smart Reminder (자동 알림)
        → People (누구와 관련?)
```

### Tab Bar 재구성

| Before | After |
|--------|-------|
| Home / Search / People / Settings | Home / Calendar / Matrix / People / Search |

Settings는 Home 화면의 navigation bar (gear icon)로 이동.

---

## 2. Requirements

### 2.1 Eisenhower Matrix

| Requirement | Description |
|-------------|-------------|
| 4-Quadrant View | Q1(Urgent+Important), Q2(Important+Not Urgent), Q3(Urgent+Not Important), Q4(Neither) |
| AI Auto-Classification | 메모리에서 추출된 태스크를 urgency/importance 점수 기반으로 사분면 자동 배치 |
| Drag & Drop | 사분면 간 드래그앤드롭으로 사용자가 분류 오버라이드 |
| Task Lifecycle | open → inProgress → completed / cancelled |
| People Integration | "David에게 한 약속들" 필터링 |
| Reminder Integration | Q1 항목에 자동 리마인더 생성 |
| Source Linking | 각 태스크는 원본 메모리로 링크 |

### 2.2 Calendar View

| Requirement | Description |
|-------------|-------------|
| Month Grid | 날짜별 컬러 도트로 밀도 표시 (파랑=메모리, 주황=태스크, 초록=리마인더) |
| Day Detail | 선택 날짜의 모든 이벤트를 타임라인으로 표시 |
| AI Date Parsing | 자연어 날짜 ("다음 주 수요일") → 절대 날짜 자동 변환 |
| Apple Calendar | EventKit 연동 (선택적, 권한 거부 시 자체 캘린더만 동작) |
| Event Creation | AI 추출 날짜 기반으로 캘린더 이벤트 자동 생성 제안 |

---

## 3. Existing Code Reuse Analysis

### Reusable As-Is

| Component | Location | Usage |
|-----------|----------|-------|
| `Memory.category == .promise` | `Domain/Model/Memory.swift` | 약속 감지 기반 |
| `MemoryRepository.getByDateRange()` | `Domain/Repository/` | 캘린더 날짜별 조회 |
| `GenerateSmartRemindersUseCase` | `Domain/UseCase/Reminder/` | Q1 자동 리마인더 기반 |
| `FirestoreService` pattern | `Data/Remote/FirestoreService.swift` | tasks 컬렉션 추가 |
| `AIAnalysisService` | `Data/Remote/AIAnalysisService.swift` | 프롬프트 확장으로 태스크 추출 |
| `ReminderRepository.getByDate()` | `Domain/Repository/` | 캘린더 리마인더 표시 |
| `MemoryCard` component | `Presentation/Home/` | 캘린더 일별 상세에서 재사용 |
| `SyncManager` pattern | `Data/Remote/SyncManager.swift` | tasks 싱크 추가 |

### New Implementation Required

| Component | Description |
|-----------|-------------|
| `Task` domain model | 새 엔티티 (id, memoryId, personId, title, dueDate, quadrant, status) |
| `TaskRepository` | 인터페이스 + Core Data 구현 + Firestore 컬렉션 |
| `CalendarEvent` | Memory + Task + Reminder 통합 뷰모델 |
| Matrix UI | 2x2 그리드 + 드래그앤드롭 |
| Calendar UI | 월간 그리드 + 일별 타임라인 |
| `CalendarService` | EventKit 연동 |
| Backend tasks module | NestJS CRUD + PostgreSQL 테이블 |
| AI prompt extension | 태스크 추출 + urgency/importance 점수 |

---

## 4. Data Model

### Task Entity

```
Task
├── id: UUID
├── memoryId: UUID          // source memory
├── personId: UUID?         // linked person
├── title: String
├── description: String?
├── dueDate: Date?
├── quadrant: EisenhowerQuadrant  // Q1, Q2, Q3, Q4
├── status: TaskStatus            // open, inProgress, completed, cancelled
├── isAISuggested: Bool
├── aiConfidence: Float           // 0.0 - 1.0
├── createdAt: Date
├── updatedAt: Date
└── syncStatus: SyncStatus
```

### EisenhowerQuadrant Enum

```
Q1: urgentImportant        — "Do"        (urgency >= 3 AND importance >= 3)
Q2: importantNotUrgent     — "Schedule"  (urgency < 3 AND importance >= 3)
Q3: urgentNotImportant     — "Delegate"  (urgency >= 3 AND importance < 3)
Q4: neitherUrgentNorImportant — "Eliminate" (urgency < 3 AND importance < 3)
```

### CalendarEvent (View Model, not persisted)

```
CalendarEvent
├── id: String
├── type: .memory | .task | .reminder
├── title: String
├── date: Date
├── color: Color          // blue, orange, green
├── sourceId: UUID        // original entity id
└── metadata: [String: Any]
```

---

## 5. AI Pipeline Enhancement

### Current AI Response (existing)

```json
{
  "persons": ["David Kim"],
  "places": ["Italian restaurant"],
  "amounts": [],
  "tags": ["meeting", "project"],
  "category": "promise",
  "date": "2026-04-18",
  "emotion": "neutral",
  "importance": 4
}
```

### Extended AI Response (new)

```json
{
  "persons": ["David Kim"],
  "places": ["Italian restaurant"],
  "amounts": [],
  "tags": ["meeting", "project"],
  "category": "promise",
  "date": "2026-04-18",
  "emotion": "neutral",
  "importance": 4,
  "tasks": [
    {
      "title": "Send revised proposal",
      "description": "Send the revised project proposal to David",
      "dueDate": "2026-04-18",
      "urgency": 4,
      "importance": 5,
      "relatedPerson": "David Kim"
    }
  ]
}
```

### Quadrant Mapping Logic

```
if urgency >= 3 AND importance >= 3 → Q1 (Do)
if urgency < 3 AND importance >= 3  → Q2 (Schedule)
if urgency >= 3 AND importance < 3  → Q3 (Delegate)
if urgency < 3 AND importance < 3   → Q4 (Eliminate)
```

---

## 6. Phased Implementation

### Phase A: Domain Foundation (3-4 days)

| Step | Task | Files |
|------|------|-------|
| A1 | `Task` model + enums | `Domain/Model/Task.swift` |
| A2 | `TaskRepository` protocol | `Domain/Repository/TaskRepository.swift` |
| A3 | Core Data `TaskMO` entity | `Data/Local/CoreDataModels.swift` |
| A4 | `TaskStore` (Core Data) | `Data/Local/TaskStore.swift` |
| A5 | `TaskRepositoryImpl` | `Data/Repository/TaskRepositoryImpl.swift` |
| A6 | `CalendarEvent` view model | `Domain/Model/CalendarEvent.swift` |

### Phase B: AI Pipeline Enhancement (3-4 days)

| Step | Task | Files |
|------|------|-------|
| B1 | Backend prompt extension | `api/src/ai/ai.service.ts` |
| B2 | Task extraction DTO | `api/src/ai/dto/task-extraction.dto.ts` |
| B3 | iOS `AnalysisResult` extension | `Data/Remote/AIAnalysisService.swift` |
| B4 | `ExtractTasksFromMemoryUseCase` | `Domain/UseCase/Task/ExtractTasksFromMemoryUseCase.swift` |
| B5 | `ClassifyTaskQuadrantUseCase` | `Domain/UseCase/Task/ClassifyTaskQuadrantUseCase.swift` |
| B6 | RecordViewModel integration | `Presentation/Record/RecordViewModel.swift` |
| B7 | Q1 auto-reminder extension | `Domain/UseCase/Reminder/GenerateSmartRemindersUseCase.swift` |

### Phase C: Eisenhower Matrix UI (4-5 days)

| Step | Task | Files |
|------|------|-------|
| C1 | `MatrixViewModel` | `Presentation/Matrix/MatrixViewModel.swift` |
| C2 | `MatrixView` (2x2 grid) | `Presentation/Matrix/MatrixView.swift` |
| C3 | Drag-and-drop | SwiftUI `.draggable()` / `.dropDestination()` |
| C4 | `TaskDetailView` | `Presentation/Matrix/TaskDetailView.swift` |
| C5 | People integration | `Presentation/People/PersonDetailView.swift` extension |

### Phase D: Calendar View UI (5-6 days)

| Step | Task | Files |
|------|------|-------|
| D1 | `CalendarViewModel` | `Presentation/Calendar/CalendarViewModel.swift` |
| D2 | `MonthGridView` | `Presentation/Calendar/CalendarView.swift` |
| D3 | `DayDetailView` | `Presentation/Calendar/DayDetailView.swift` |
| D4 | AI date extraction enhancement | `api/src/ai/ai.service.ts` |
| D5 | `CalendarService` (EventKit) | `Data/Service/CalendarService.swift` |
| D6 | `SyncCalendarUseCase` | `Domain/UseCase/Calendar/SyncCalendarUseCase.swift` |

### Phase E: Navigation + Integration (2-3 days)

| Step | Task | Files |
|------|------|-------|
| E1 | Tab bar restructure (5 tabs) | `App/ContentView.swift` |
| E2 | Deep link handling | `App/DeepLinkHandler.swift` |
| E3 | DI Container updates | `Core/DI/DIContainer.swift` |
| E4 | E2E flow verification | Manual testing |

### Phase F: Cloud Sync + Backend (3-4 days)

| Step | Task | Files |
|------|------|-------|
| F1 | NestJS tasks module | `api/src/task/` (module, controller, service) |
| F2 | PostgreSQL tasks table | `api/src/database/init.sql` |
| F3 | Firestore tasks collection | `Data/Remote/FirestoreService.swift` |
| F4 | SyncManager extension | `Data/Remote/SyncManager.swift` |
| F5 | Android domain stubs | `domain/model/Task.kt`, `domain/repository/TaskRepository.kt` |

### Phase G: Widgets + Polish (2-3 days)

| Step | Task | Description |
|------|------|-------------|
| G1 | Matrix widget | Small: Q1 count, Medium: Q1+Q2 top 3 |
| G2 | Calendar widget | Small: today + count, Medium: 3-day lookahead |
| G3 | Animations | Quadrant transitions, haptic feedback |
| G4 | Empty states | Matrix/Calendar 빈 상태 디자인 |
| G5 | Accessibility | VoiceOver labels, Dynamic Type |

---

## 7. Dependency Graph

```
Phase A (Domain)
  │
  ├──→ Phase B (AI Pipeline)
  │       │
  │       ├──→ Phase C (Matrix UI) ──┐
  │       │                          │
  │       └──→ Phase D (Calendar UI) ┤
  │                                  │
  │            Phase E (Navigation + Integration)
  │                                  │
  └──→ Phase F (Cloud Sync + Backend)
                                     │
                     Phase G (Widgets + Polish)
```

- Phase A must complete first (all phases depend on Task model)
- Phases C and D can run in parallel after B
- Phase F backend work can start after A (independent of UI)
- Phase G is final polish

---

## 8. Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| AI task extraction inaccuracy | High | Medium | Show as "suggestions" with easy override; track acceptance rate |
| Core Data migration breaks data | Critical | Low | Lightweight migration; test with production data; backup |
| EventKit permission denied | Medium | Medium | Optional feature; core calendar works without it |
| 5-tab crowding on small screens | Medium | Low | Compact icons without labels; test on iPhone SE |
| AI prompt cost increase | Medium | Low | Single prompt returns all data; no additional API calls |
| Firestore sync with 4 entity types | Medium | Low | Reuse existing SyncManager pattern exactly |
| Drag-and-drop iOS version req | Low | Low | iOS 16+ required; fallback to long-press context menu |
| Relative date parsing errors | Medium | Medium | Backend converts relative → absolute; show for user confirmation |

---

## 9. Backend API Changes

### New Endpoints

```
POST   /api/tasks              — Create task
GET    /api/tasks              — List tasks (query: quadrant, personId, status, dateRange)
GET    /api/tasks/:id          — Get task by ID
PUT    /api/tasks/:id          — Update task
DELETE /api/tasks/:id          — Delete task
PATCH  /api/tasks/:id/quadrant — Move task to different quadrant
PATCH  /api/tasks/:id/status   — Update task status
```

### Database Schema

```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  memory_id UUID REFERENCES memories(id),
  person_id UUID REFERENCES persons(id),
  title VARCHAR(500) NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  quadrant VARCHAR(4) NOT NULL CHECK (quadrant IN ('Q1','Q2','Q3','Q4')),
  status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','inProgress','completed','cancelled')),
  is_ai_suggested BOOLEAN DEFAULT true,
  ai_confidence FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_quadrant ON tasks(user_id, quadrant);
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_due_date ON tasks(user_id, due_date);
CREATE INDEX idx_tasks_person ON tasks(person_id);
CREATE INDEX idx_tasks_memory ON tasks(memory_id);
```

---

## 10. Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| A: Domain Foundation | 3-4 days | 3-4 days |
| B: AI Pipeline | 3-4 days | 6-8 days |
| C: Matrix UI | 4-5 days | 10-13 days |
| D: Calendar UI | 5-6 days | 15-19 days |
| E: Navigation + Integration | 2-3 days | 17-22 days |
| F: Cloud Sync + Backend | 3-4 days | 20-26 days |
| G: Widgets + Polish | 2-3 days | **22-29 days** |

> Note: Phases C+D can overlap with F (backend), reducing wall-clock time to ~20-25 days.

---

## 11. Success Criteria

- [ ] 메모리 기록 시 AI가 태스크를 자동 추출하고 사분면에 배치
- [ ] Matrix 뷰에서 드래그앤드롭으로 태스크 이동 가능
- [ ] Calendar 뷰에서 메모리/태스크/리마인더가 날짜별로 표시
- [ ] AI가 자연어 날짜를 파싱하여 캘린더 이벤트 자동 생성 제안
- [ ] Q1 태스크에 자동 리마인더 생성
- [ ] 인물별 태스크 필터링 동작
- [ ] 오프라인 동작 + 클라우드 싱크
- [ ] 기존 기능 (메모리, 검색, 인물, 리마인더) 회귀 없음
