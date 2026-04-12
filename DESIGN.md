# Design System — Engram

## Product Context
- **What this is:** AI 기반 개인 기억 관리 앱. 음성/텍스트로 기록하면 AI가 자동 분석하고, 시맨틱 검색으로 기억을 찾아줌.
- **Who it's for:** 20-40대 일상 기록 사용자, 관계 관리가 중요한 비즈니스 전문가
- **Space/industry:** Personal journaling / memory management (Day One, Journey, Bear, Diarly, Momento)
- **Project type:** Native mobile app (iOS SwiftUI + Android Jetpack Compose)

## Aesthetic Direction
- **Direction:** Apple Native Minimal
- **Decoration level:** Minimal — 시스템 UI 패턴에 충실. 장식 최소화.
- **Mood:** 깨끗하고 절제된 iOS 네이티브 느낌. Deep Teal 악센트로 재성/집중/성장을 표현.
- **Reference sites:** Apple HIG, Bear, Day One

## Typography

iOS는 SF Pro 시스템 폰트, Android는 Plus Jakarta Sans를 사용.
Apple HIG Dynamic Type 스케일을 따릅니다.

- **Large Title:** SF Pro Display Bold 34pt (iOS) / Plus Jakarta Sans Bold 34sp (Android) — 화면 제목
- **Title 1:** SF Pro Display Bold 28pt / Plus Jakarta Sans Bold 28sp — 섹션 제목
- **Headline:** SF Pro Text Semibold 17pt / Plus Jakarta Sans Semibold 17sp — 카드 제목
- **Body:** SF Pro Text Regular 15pt / Plus Jakarta Sans Regular 15sp — 메모리 본문
- **Subheadline:** SF Pro Text Regular 13pt / Plus Jakarta Sans Regular 13sp — 부제, 캡션
- **Caption:** SF Pro Text Regular 12pt / Plus Jakarta Sans Regular 12sp — 날짜, 메타
- **Data/Mono:** SF Mono Regular 13pt / Geist Mono Regular 13sp — 날짜, 시간, 금액 (tabular-nums)
- **Loading:** 시스템 폰트 (빌트인). Android만 Google Fonts에서 Plus Jakarta Sans + Geist Mono 로드.

## Color

- **Approach:** Restrained — iOS 시스템 컬러 기반 + Ink Sage 악센트 1개
- **Accent:** `#3D5A50` — 잉크와 세이지가 만난 Engram 고유 색. 어떤 프레임워크(Tailwind/Material/iOS)에도 없는 커스텀 컬러. 자연스럽고 지적인 느낌.
- **Accent Light:** `#4E7264` — 호버, 강조
- **Accent Dark:** `#2D4339` — 라이트모드 텍스트 위 라벨
- **Accent Tint:** `rgba(61,90,80,0.10)` — 배경 강조, 태그 배경, AI 답변 카드
- **Accent Tint Strong:** `rgba(61,90,80,0.18)` — 버튼 tinted, 포커스 링

### Light Mode
- **Background:** `#F2F2F7` (systemGroupedBackground)
- **Surface:** `#FFFFFF` (secondarySystemGroupedBackground)
- **Label:** `#1C1C1E` (label)
- **Secondary Label:** `#8E8E93` (secondaryLabel)
- **Tertiary Label:** `#AEAEB2` (tertiaryLabel)
- **Separator:** `rgba(60,60,67,0.12)` (separator)
- **Fill:** `rgba(120,120,128,0.08)` (tertiarySystemFill)

### Dark Mode
- **Background:** `#000000` (OLED pure black)
- **Surface:** `#1C1C1E` (secondarySystemGroupedBackground)
- **Surface Elevated:** `#2C2C2E` (tertiarySystemGroupedBackground)
- **Label:** `#FFFFFF`
- **Accent Light (dark):** `#6B8F7E` — 다크모드에서 가독성을 위해 밝게 조정
- **Separator:** `rgba(84,84,88,0.36)`

### Semantic Colors
- **Success (Green):** `#34C759` / `#30D158` (dark)
- **Warning (Orange):** `#FF9500` / `#FF9F0A` (dark)
- **Error (Red):** `#FF3B30` / `#FF453A` (dark)
- **Info:** Accent tint 사용

## Spacing
- **Base unit:** 4px
- **Density:** Comfortable
- **Scale:** 2xs(2px) xs(4px) sm(8px) md(16px) lg(24px) xl(32px) 2xl(48px)
- **Content insets:** 16px (iOS standard)
- **Section spacing:** 24px
- **Card internal padding:** 13-14px
- **List row height:** 44px (iOS standard tap target)

## Layout
- **Approach:** Grid-disciplined — iOS HIG 네이티브 패턴
- **Navigation:** Bottom Tab Bar (5 tabs: 홈, 검색, 기록, 사람, 설정)
- **Record button:** Floating center tab, 46px circle, accent color, elevated shadow `0 3px 10px rgba(13,148,136,0.3)`
- **Lists:** iOS Grouped List style (rounded corners, separator lines)
- **Cards:** Full-width rounded cards, `shadow: 0 1px 4px rgba(0,0,0,0.04), 0 0 1px rgba(0,0,0,0.06)`
- **Max content width:** 화면 전체 (모바일 앱)
- **Border radius:** sm:10px, md:14px, lg:20px, full:9999px

## Motion
- **Approach:** Minimal-functional — iOS 시스템 애니메이션 활용
- **Easing:** enter(easeOut) exit(easeIn) move(easeInOut) — iOS default curves
- **Duration:** micro(100ms) short(200ms) medium(350ms) long(500ms)
- **Patterns:**
  - Sheet presentation: iOS default slide-up
  - Tab switch: cross-fade
  - Card tap: scale(0.98) on press
  - List insert/remove: iOS automatic row animation
  - Save success: SaveSuccessView 애니메이션

## Component Patterns

### Buttons
- **Filled:** Accent `#0D9488` background + white text. Primary actions (저장, 기록).
- **Tinted:** Accent tint strong background + accent dark text. Secondary actions (편집, 필터).
- **Plain:** Text only, accent color. Tertiary/cancel.
- **Gray:** Fill background + label text. Utility (더 보기, 첨부).
- **Destructive:** Red tint background + red text. 삭제 등.
- **Pill shape:** border-radius: 9999px. 태그 추가, 필터 등 작은 액션.
- **Circle:** 42x42px. 아이콘 버튼 (기록, 카메라, 마이크).

### Cards
- **Memory Card:** Surface background, shadow, 14px radius. 날짜(mono) + 본문 + 태그 pills.
- **Reminder Card:** Grouped list row 스타일. 아이콘(accent tint background, 8px radius) + 제목 + 부제.
- **Flashback Card:** Accent tint gradient background, accent border. 특별한 느낌.
- **AI Answer Card:** Accent tint background, 14px radius. AI 라벨 + 답변 텍스트.

### Tags / Pills
- **Person:** Accent tint background + accent dark text. `👤 김철수`
- **Place:** Green tint background + green text. `📍 강남역`
- **Category:** Fill background + secondary text. `🍽️ 식사`

### Inputs
- **Text field:** Fill background, no border, 10px radius. Focus: accent tint strong ring (3px).
- **Search bar:** Fill background, search icon, 10px radius.
- **Mood selector:** 38px circles, fill background. Active: accent border + accent tint.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-06 | v1 Organic/Warm Amber 제안 | 경쟁 앱 블루 차별화 시도. 사용자가 "별로"라고 피드백. |
| 2026-04-06 | v2 Apple Native + Amber 제안 | 더 미니멀/네이티브 방향 요청. 색상은 여전히 부족. |
| 2026-04-07 | 경쟁앱 6개 재분석 | Day One(블루), Journey(시안), Grid Diary(파랑), Notion(블랙), Diarly(퍼플), Momento(오렌지). |
| 2026-04-07 | v3 Deep Teal `#0D9488` 채택 | 기록/재성/집중에 어울리는 색. 경쟁앱 중 아무도 안 쓰는 색으로 차별화. 사용자 승인. |
| 2026-04-08 | Engram으로 앱 이름 변경 반영 | DailyMemory → Engram 리네이밍. |
| 2026-04-08 | Ink Sage `#3D5A50` 브랜드 컬러 확정 | Deep Teal(Tailwind 기본값)에서 Engram 고유 커스텀 컬러로 변경. 어떤 프레임워크에도 없는 색. |
