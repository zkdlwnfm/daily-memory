# Design System Strategy: The Cognitive Atelier

## 1. Overview & Creative North Star
The "DailyMemory" experience is defined by the Creative North Star: **The Digital Curator.** 

Rather than a standard utility app that feels like a database, this design system treats a user’s memories as precious artifacts in a high-end gallery. We move away from the "grid-of-boxes" aesthetic toward an editorial, fluid layout. By leveraging intentional asymmetry, overlapping surfaces, and a sophisticated typographic scale, we transform "data entry" into "mindful reflection." This system prioritizes breathing room and tonal depth to reduce cognitive load, ensuring the AI assistant feels like a supportive whisper rather than a noisy interface.

---

## 2. Color & Atmospheric Depth
Our palette transitions from functional Indigo to a soulful, AI-driven Purple. We move beyond flat HEX codes to create an atmosphere of intelligence.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders for sectioning or containment. 
Boundaries must be defined exclusively through background color shifts. For example, a content block using `surface_container_low` (#f1f3ff) should sit directly on the `surface` (#f9f9ff) background. This creates a "soft-edge" UI that feels organic and premium.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine vellum.
*   **Base:** `background` (#f9f9ff)
*   **Secondary Content Areas:** `surface_container_low` (#f1f3ff)
*   **Interactive Cards:** `surface_container_lowest` (#ffffff)
*   **Elevated AI Insights:** `secondary_container` (#8455ef) with 10% opacity for a tinted glass effect.

### The "Glass & Gradient" Rule
To elevate the AI assistant components, use Glassmorphism. Apply `surface_bright` at 60% opacity with a `24px` backdrop blur. For primary CTAs, use a subtle linear gradient: `primary` (#4648d4) to `primary_container` (#6063ee) at a 135° angle. This adds "soul" and visual kinetic energy that flat fills lack.

---

## 3. Typography: The Editorial Voice
We use a dual-font strategy to balance authority with warmth. 

*   **Display & Headlines (Manrope):** Large, bold, and expressive. Use `display-md` for "Welcome back" moments to establish a high-end editorial feel. The tight tracking and geometric builds of Manrope signal modern intelligence.
*   **Titles & Body (Plus Jakarta Sans):** Designed for high legibility. `title-md` (1.125rem) is your workhorse for memory headers. 
*   **Hierarchy as Navigation:** Use extreme scale contrast. A `headline-lg` title paired with a `body-sm` caption creates an intentional "staccato" rhythm that guides the eye better than uniform sizing.

---

## 4. Elevation & Tonal Layering
We reject traditional "Material 2" drop shadows in favor of **Tonal Layering.**

*   **The Layering Principle:** Depth is achieved by stacking. Place a `surface_container_lowest` (#ffffff) card on a `surface_container_low` (#f1f3ff) background. This creates a "natural lift" without visual clutter.
*   **Ambient Shadows:** If an element must float (e.g., a FAB or Menu), use a "Cognitive Shadow": `Color: on_surface (141b2b)`, `Opacity: 6%`, `Blur: 32px`, `Y-Offset: 8px`. It should feel like a soft glow, not a hard shadow.
*   **The Ghost Border Fallback:** If accessibility requires a stroke (e.g., high-contrast mode), use `outline_variant` at **15% opacity**. Never use 100% opaque lines.

---

## 5. Signature Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary_container`), `roundness-md` (0.75rem), `label-md` uppercase with 0.05rem letter spacing.
*   **Secondary:** No fill, `surface_container_high` background on hover.
*   **AI Action:** `secondary_container` with a glass blur.

### Memory Cards
*   **Structure:** No dividers. Use `spacing-6` (1.5rem) to separate the title from the body. 
*   **Visual Soul:** Use a subtle `tertiary_container` (#b55d00) accent at 5% opacity for "Throwback" memories to differentiate them from daily logs.

### Input Fields
*   **The "Invisible Field":** Use a `surface_variant` bottom-only highlight. On focus, transition the background to `surface_container_lowest` and expand a soft ambient shadow. 

### The Memory Stream (Lists)
*   **Forbid Dividers:** Separate list items using `spacing-4` (1rem). 
*   **Asymmetric Loading:** When cards appear, stagger their entrance by 50ms and use a slight `2px` horizontal offset to break the rigid vertical line, creating a "hand-curated" feel.

---

## 6. Do’s and Don’ts

### Do:
*   **Embrace Negative Space:** Use `spacing-10` (2.5rem) for section gaps. White space is a luxury signal.
*   **Prioritize Touch:** Ensure every interactive element maintains a `44dp` minimum hit area, even if the visual asset is smaller.
*   **Tone-on-Tone:** Use `on_surface_variant` for captions to keep them secondary to the primary narrative.

### Don’t:
*   **Don't use 1px borders.** It breaks the "Atelier" feel and looks like a generic template.
*   **Don't use pure black (#000000).** It is too harsh for a memory app. Always use `on_surface` (#141b2b).
*   **Don't crowd the screen.** If you have more than 5 elements in a view, use a "Nested Surface" to group them and provide visual relief.