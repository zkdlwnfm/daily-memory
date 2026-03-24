# DailyMemory - Google Stitch Prompts (Global/English)

> UI prompts for generating screens in Google Stitch.
> Default language: **English** (Global target)

---

## Design System

### Colors
```
Primary:        #6366F1 (Indigo)
AI/Secondary:   #8B5CF6 (Purple)
Success:        #10B981 (Green)
Warning:        #F59E0B (Amber)
Error:          #EF4444 (Red)
Background:     #F9FAFB
Surface/Card:   #FFFFFF
Text:           #111827
Text Secondary: #6B7280

Dark Mode:
Background:     #111827
Surface:        #1F2937
Text:           #F9FAFB
Text Secondary: #9CA3AF
Primary:        #818CF8
```

### Typography
```
Title:    20sp, Bold
Subtitle: 16sp, SemiBold
Body:     16sp, Regular
Caption:  14sp, Regular
Small:    12sp, Regular
Font:     System default (SF Pro / Roboto) or Noto Sans for i18n
```

### Spacing & Layout
```
Screen padding:  16dp
Card padding:    12-16dp
Section gap:     24dp
Item gap:        12dp
Corner radius:   12dp (cards), 8dp (buttons), 28dp (FAB pill)
```

### Global Design Principles
```
1. FLEXIBLE WIDTHS - No fixed text widths (German is 30-40% longer)
2. RTL READY - Layout should mirror for Arabic/Hebrew
3. LOCALE FORMATS - Dates, times, numbers adapt to region
4. UNIVERSAL ICONS - Use globally understood symbols
5. ACCESSIBLE - Min touch target 44x44dp, WCAG AA contrast
```

---

## 1. Home Screen

### 1.1 Home - Default State (With Records)

```
Mobile app home screen for "DailyMemory" - a personal memory assistant app.

Layout (top to bottom):
1. HEADER:
   - Left: App logo "DailyMemory" (icon + text)
   - Right: Circular profile avatar (40px)

2. GREETING SECTION:
   - Title: "Good afternoon, Alex 👋" (time-based greeting)
   - Subtitle: "2 memories today · 1 reminder"

3. REMINDER CARD (amber/yellow tinted background):
   - Icon + Title: "🎂 Mom's birthday tomorrow"
   - Description: "Last year you gave her a massage chair"
   - Two buttons: "Done" (outline), "Snooze" (filled primary)

4. SECTION "📝 Recent Memories" with "See all >" link:
   - Memory Card 1:
     - Timestamp: "Today, 2:30 PM"
     - Content: "Had lunch with Mike in downtown. He's getting married next month."
     - Tags: "👤 Mike" "📍 Downtown" "💰 Gift"
   - Memory Card 2:
     - Timestamp: "Yesterday, 6:00 PM"
     - Content: "Meeting with Acme Corp - project proposal went well"

5. SECTION "📸 On this day, 1 year ago":
   - Card with photo thumbnail + "Family trip - Beach vacation"

6. FAB (Floating Action Button):
   - Pill shape, centered above bottom nav
   - "🎤 Record" text with mic icon
   - Background: #6366F1

7. BOTTOM NAVIGATION:
   - 4 tabs: Home (active), Search, People, Settings

Style: Clean, modern, iOS/Material hybrid. Soft shadows, 12dp rounded corners.
Use flexible layouts - text should wrap naturally.
```

### 1.2 Home - Empty State (First-time User)

```
Mobile app home screen - empty/onboarding state for new users.

Layout:
1. HEADER: "DailyMemory" logo left, profile avatar right

2. GREETING:
   - Title: "Welcome! 👋"
   - Subtitle: "Let's capture your first memory"

3. CENTERED EMPTY STATE CARD:
   - Large icon: 📝
   - Title: "Record your first memory"
   - Description: "Speak or type what happened today. AI will organize it for you."
   - Primary button: "🎤 Start Recording"

4. SECTION "💡 Try recording something like...":
   - Example card 1: "Had coffee with Sarah today. She mentioned her new job starts Monday."
   - Example card 2: "Mom sent $200 for my birthday. Should call to thank her."

5. BOTTOM NAVIGATION (Home tab active)

Style: Welcoming, encouraging. Clear CTA. Flexible text containers.
```

---

## 2. Record Screen

### 2.1 Record - Voice Mode (Idle)

```
Mobile app voice recording screen - waiting to record.

Layout:
1. HEADER:
   - Left: "✕ Cancel" button
   - Right: "Type instead" text link

2. CENTER CONTENT:
   - Large circular microphone button (120px diameter)
   - 🎤 icon inside, white on #6366F1 background
   - Label below: "Tap to record"

3. BOTTOM HINT:
   - "💡 Just speak naturally. AI will extract people, places, and events."

Style: Minimal, focused on the mic button. Large touch target.
Background: #F9FAFB
```

### 2.2 Record - Voice Mode (Recording)

```
Mobile app voice recording screen - actively recording.

Layout:
1. HEADER: "✕ Cancel" left, "Type instead" right

2. RECORDING INDICATOR (centered):
   - Red pulsing circle with timer "0:12"
   - Audio waveform visualization (5-7 animated bars)
   - Label: "Recording..."

3. REAL-TIME TRANSCRIPTION BOX:
   - Light gray card
   - Live text: "Had lunch with Mike downtown. He told me he's getting married next month. Need to prepare a wedding gift around 300 dollars..."

4. STOP BUTTON:
   - Large red square/circle button at bottom
   - Label: "Tap to stop"

Style: Recording state with red (#EF4444) accent. Active/pulsing animation on indicator.
```

### 2.3 Record - AI Analysis Result

```
Mobile app screen showing AI-extracted information after recording.

Layout:
1. HEADER:
   - Left: "← Back"
   - Right: "Save ✓" button (primary filled)

2. SECTION "📝 Your Memory":
   - White card with text content
   - "Had lunch with Mike downtown. He told me he's getting married next month. Need to prepare a wedding gift around 300 dollars."
   - "Edit ✏️" link

3. SECTION "✨ AI Analysis" (purple accent):

   a) "👤 People":
      - Chip tag: "Mike ✕"
      - "+ Add person" button
      - Info: "ⓘ New person detected. Set relationship?"

   b) "📍 Location": "Downtown" with "Change >" link

   c) "📅 Event": "🎊 Wedding - Next month" with "Change >"

   d) "💰 Amount": "$300 (Gift)" with "Change >"

   e) "🏷️ Category":
      Radio options: "General / Meeting / Event / Financial / Promise"
      "Event" selected

4. SECTION "📸 Add Photos":
   - Add button (dashed border square with + icon)

5. SECTION "🔔 Set Reminder":
   - Toggle: OFF with "Set up >" link
   - AI suggestion: "💡 Remind you before the wedding?"
   - Quick action button: "Yes, remind me 1 day before"

Style: Form-like layout with clear sections. AI elements have purple border/accent.
All text fields should accommodate longer translations.
```

### 2.4 Record - Text Mode

```
Mobile app text input screen for creating memories.

Layout:
1. HEADER:
   - Left: "✕ Cancel"
   - Right: "🎤 Voice input" link

2. TEXT INPUT AREA:
   - Large multiline text field
   - Placeholder: "What happened today?"
   - Character count at bottom right (flexible, e.g., "0/500")

3. SECTION "📸 Add Photos":
   - Square add button with + icon

4. ACTION BUTTONS (bottom):
   - Primary: "✨ Analyze with AI" (filled)
   - Secondary: "Save without analysis" (outline/text)

Style: Clean text editor focused on input.
```

---

## 3. Search Screen

### 3.1 Search - Initial State

```
Mobile app search screen with AI query suggestions.

Layout:
1. SEARCH BAR:
   - "🔍 Ask AI anything..." placeholder
   - Microphone icon on right for voice search

2. SECTION "💡 Try asking...":
   - Tappable suggestion cards:
     - "When is Mike's wedding?"
     - "What did I do with Mom last year?"
     - "Do I owe anyone money?"
     - "Summarize my work meetings this month"

3. SECTION "🕐 Recent searches" with "Clear" link:
   - List with delete (✕) icons:
     - "Mike wedding"
     - "Mom birthday gift"
     - "Acme meeting"

4. COLLAPSED SECTION "🔧 Filter search" with expand indicator

5. BOTTOM NAVIGATION (Search tab active)

Style: Clean search interface. Suggestion cards are tappable.
```

### 3.2 Search - AI Response

```
Mobile app search results with AI answer.

Layout:
1. SEARCH BAR:
   - Shows query: "When is Mike's wedding?"
   - "New search" link on right

2. AI ANSWER CARD (purple border/accent):
   - Header: "✨ AI Answer"
   - Content: "Mike's wedding is in **April** (next month).\n\nBased on your memory from March 23rd, you're planning a gift around $300.\n\n23 days until the wedding."
   - Feedback button: "👍 Helpful"

3. SECTION "📋 Related memories (1)":
   - Memory card:
     - "Mar 23, 2:30 PM"
     - "Had lunch with Mike downtown..."
     - Tags: "👤 Mike" "📍 Downtown"

4. SECTION "💡 Follow-up questions":
   - Chip buttons:
     - "When is Mike's birthday?"
     - "What gifts have I given Mike?"

5. BOTTOM NAVIGATION

Style: AI answer prominently displayed. Purple (#8B5CF6) accent on AI elements.
```

### 3.3 Search - Filter Expanded

```
Mobile app search with expanded filter panel.

Layout:
1. SEARCH BAR: "🔍 Search memories..."

2. FILTER PANEL "🔧 Filters" with "Collapse ▲":
   - "📅 Date Range":
     - Two date pickers: Start / End
     - Quick filters: "Today" "This week" "This month" "This year"

   - "👤 People":
     - Multi-select checkboxes: "☑ Mike" "☑ Mom" "☐ John" "+More"

   - "🏷️ Category":
     - Checkboxes: "☑ All" "☐ Event" "☐ Meeting" "☐ Financial"

   - Buttons: "Reset" (outline), "Apply" (primary filled)

3. RESULTS AREA placeholder

4. BOTTOM NAVIGATION

Style: Filter as expandable card. Clear form controls.
```

---

## 4. People Screen

### 4.1 People - List

```
Mobile app contacts/people list screen.

Layout:
1. HEADER: "👥 People" title, "+ Add" button right

2. SEARCH BAR: "🔍 Search people..."

3. SORT TABS: "● Recent" (active), "○ A-Z", "○ Frequent"

4. PEOPLE LIST:
   - Card 1:
     - Avatar placeholder "👤"
     - Name: "Mike"
     - Subtitle: "Friend · Last seen Mar 23"
     - "📝 12 memories"
     - Arrow ">"

   - Card 2:
     - Avatar "👤", Name: "Mom"
     - "Family · Last seen Mar 15"
     - "📝 28 memories"
     - Event badge: "🎂 Birthday tomorrow!"

   - Card 3:
     - Avatar "👤", Name: "John (Work)"
     - "Colleague · Last seen Mar 20"
     - "📝 8 memories"

   - Card 4:
     - Avatar "👤", Name: "Sarah"
     - "Friend · Last seen Feb 10"
     - "📝 5 memories"
     - Warning badge: "⚠️ No contact for 41 days"

5. BOTTOM NAVIGATION (People tab active)

Style: Clean list with avatars. Badges for events (amber) and warnings (red).
Flexible card heights for varying text lengths.
```

### 4.2 People - Detail Profile

```
Mobile app person detail screen.

Layout:
1. HEADER: "← Back" left, "Edit" and "⋯" menu right

2. PROFILE SECTION (centered):
   - Large avatar (80px) with 👤 or photo
   - Name: "Mike"
   - Subtitle: "Friend (College)"

3. STATS CARD "📊 Relationship Summary":
   - "Meetings this year: 12 ↑" (trend indicator)
   - "Last met: Mar 23 (3 days ago)"
   - "First memory: March 2020"
   - "Known for: 4 years"

4. EVENT CARD "📅 Upcoming":
   - "🎊 Wedding"
   - "April 15 (in 23 days)"
   - "Gift: ~$300 planned"
   - "Set reminder" button

5. SECTION "📝 Timeline" with "See all >" link:
   - Timeline with connected dots:
   - "2024" header
   - "● Mar 23: Downtown lunch, wedding news - $300 gift planned"
   - "● Feb 14: Birthday - Gift: wine"
   - "● Jan 5: New Year meetup"
   - "2023" header
   - "● Dec 25: Christmas party"
   - "● ..."

6. BOTTOM ACTION: "📝 Add memory about Mike" button

Style: Profile-focused with visual timeline. Clean hierarchy.
```

---

## 5. Settings Screen

### 5.1 Settings - Main

```
Mobile app settings screen with grouped options.

Layout:
1. HEADER: "⚙️ Settings"

2. SECTION "Account":
   - Row: Avatar + "alex@email.com" + "Premium Plan" + ">"

3. SECTION "Data":
   - "💾 Storage" - "Cloud sync" - ">"
   - "🔄 Sync status" - "Last: Just now" - "Sync now" button
   - "📤 Export data" - ">"
   - "📥 Import data" - ">"

4. SECTION "Notifications":
   - "🔔 Reminders" - Toggle ON
   - "📝 Daily prompt" - Toggle ON - subtitle "Every day at 9 PM"
   - "⏰ Quiet hours" - "Set >" - subtitle "9 AM - 10 PM"
   - "📸 On this day" - Toggle ON

5. SECTION "Privacy & Security":
   - "🔒 App lock (Face ID)" - Toggle ON
   - "👁️ Show locked memories" - Toggle OFF

6. SECTION "AI":
   - "✨ Auto-analyze memories" - Toggle ON
   - "💡 Smart reminder suggestions" - Toggle ON

7. SECTION "About":
   - "ℹ️ Version" - "1.0.0"
   - "📄 Privacy Policy" - ">"
   - "📄 Terms of Service" - ">"
   - "💬 Contact Support" - ">"
   - "⭐ Rate the App" - ">"

8. "Sign Out" button (text style, gray)

9. BOTTOM NAVIGATION (Settings tab active)

Style: Standard grouped settings list. iOS/Android native feel.
```

---

## 6. Memory Detail Screen

```
Mobile app memory detail view.

Layout:
1. HEADER: "← Back" left, "Edit" and "⋯" menu right

2. DATE/TIME:
   - "📅 Saturday, March 23, 2024"
   - "2:30 PM"

3. CONTENT CARD:
   - "Had lunch with Mike downtown. He told me he's getting married next month. Need to prepare a wedding gift around 300 dollars."

4. SECTION "📸 Photos (2)":
   - Two square photo thumbnails

5. SECTION "👤 People":
   - Tappable card: Avatar "👤 Mike" + "Friend" + ">"

6. METADATA:
   - "📍 Location: Downtown"
   - "💰 Amount: $300 (Gift)"
   - "🏷️ Category: Event"

7. SECTION "🔔 Reminders":
   - Reminder card:
     - "⏰ April 14 (Sun), 9:00 AM"
     - "Prepare wedding gift"
     - "Edit" "Delete" links
   - "+ Add reminder" link

8. FOOTER INFO:
   - "ℹ️ Created: Mar 23, 2024, 2:35 PM"
   - "Modified: Mar 23, 2024, 2:40 PM"

Style: Detail view with clear sections. Read-focused.
```

---

## 7. Widgets

### 7.1 Widget - Small (1x1)

```
Mobile home screen widget - small square.

Design:
- Single large microphone icon 🎤 centered
- Label: "Record" below icon
- Background: #6366F1 (Indigo), rounded corners 16dp
- Tap: Opens voice recording

Size: ~70x70dp
Style: Minimal, one-tap action
```

### 7.2 Widget - Medium (2x2)

```
Mobile home screen widget - medium square.

Layout:
- Top: "DailyMemory" small text
- Middle: Two buttons side by side
  - "🎤 Voice"
  - "✏️ Text"
- Bottom: "📝 Recent: Lunch with Mike..." (truncated preview)

Background: White, shadow, 16dp corners
Size: ~140x140dp
```

### 7.3 Widget - Large (4x2)

```
Mobile home screen widget - large horizontal.

Layout:
- Left side (60%):
  - "DailyMemory" + date "Mar 23"
  - "📝 2 memories today"
  - "⏰ Reminder: Mom's birthday tomorrow"
- Right side (40%):
  - Stacked buttons: "🎤 Voice" / "✏️ Text"

Background: White, rounded corners
Size: Full width, medium height
```

---

## 8. Dark Mode

### 8.1 Home Screen (Dark)

```
Mobile app home screen - DARK MODE.

Same layout as Home - Default State, with dark theme colors:
- Background: #111827
- Cards: #1F2937
- Text primary: #F9FAFB
- Text secondary: #9CA3AF
- Primary accent: #818CF8 (lighter indigo)
- Dividers: #374151

All content same as light mode home screen.
Style: Dark theme, OLED-friendly, maintains readability.
```

---

## 9. Global/i18n Considerations

### Date & Time Formats
```
Use locale-aware formatting in designs:
- US: "Mar 23, 2024" / "2:30 PM"
- EU: "23 Mar 2024" / "14:30"
- ISO: "2024-03-23"

Show placeholder format that can adapt.
```

### Number & Currency
```
- US: $300 / 1,000
- EU: €300 / 1.000
- Show currency symbol position flexibility
```

### Text Length Examples
```
"Record" (EN) → "Aufnehmen" (DE) → "Enregistrer" (FR)
"Save" (EN) → "Speichern" (DE) → "Sauvegarder" (FR)

Design buttons with padding, not fixed width.
```

### RTL Layout Note
```
For Arabic/Hebrew:
- Mirror entire layout (left ↔ right)
- Navigation on right
- Back arrows point right[NEXT_SESSION_PROMPT.md](../NEXT_SESSION_PROMPT.md)
- Text aligns right
```

---

## Prompt Tips

1. **One screen at a time** - Better quality with focused prompts
2. **Iterate** - "Make the button larger", "Change color to #6366F1"
3. **Specify flexibility** - "Text should wrap, not truncate"
4. **Request variants** - "Now show dark mode version"
5. **Extract components** - "Just the reminder card component"
