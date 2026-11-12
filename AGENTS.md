# Moneta Design & Development Guidelines (AGENTS.md)

This document contains persistent project rules and design standards for **Moneta**. All agents and developers working on this project must strictly adhere to these guidelines.

---

## The 20 Ways to Unslop AI Designs

To prevent UI from looking like "AI-generated slop", always follow these 20 design rules:

### 1. Delete Filler Badges
- Do NOT slap decorative pills or badges everywhere (e.g. `🏛️ อารักขาคลัง`, `✨ No-Spend`, `0 สลิป`, `แนะนำ`).
- Badges must be reserved strictly for critical, actionable status (such as active streaks: `🔥 7 วัน`).

### 2. Drop Redundant Labels
- Let the numbers and content speak for themselves.
- Remove redundant boilerplate:
  - ❌ `"Moneta Daily Check-in"`
  - ❌ `"เฉลี่ยรายจ่ายรายวันของเดือนนี้"` -> ✅ `"เฉลี่ยต่อวัน"`
  - ❌ `"จำนวนรายจ่ายต่อวัน: 3 ครั้ง"` -> ✅ `"3 รายการ"`

### 3. Unitalicize Random Words
- Maintain clean, confident standard typography. Avoid random italicized captions.

### 4. Mono Only Where Needed
- Use monospace or tabular styling **only** for financial figures, counters, and dates.
- Prose, labels, and titles must use clean human typography (Noto Sans Thai / SF Pro).

### 5. Use a Design System
- Strictly adhere to `AppColors` and `AppTheme`:
  - `background`: `Color(0xFF0D0E14)` (OLED Deep Dark)
  - `surface`: `Color(0xFF161722)` (Clean Midnight surface)
  - `surfaceElevated`: `Color(0xFF1F212E)`
  - `border`: `Color(0xFF282A3A)` (Subtle crisp 1px border)
  - `indigoPrimary`: `Color(0xFF4F5FFA)` (Primary Action Accent)
  - `mintSuccess`: `Color(0xFF2ED573)` (Income / Success / Mint)
  - `textPrimary`: `Color(0xFFFFFFFF)` (Pure White)
  - `textSecondary`: `Color(0xFF9EA3B8)` (High-contrast Slate Grey)
- Do NOT introduce ad-hoc one-off hex colors scattered across components.

### 6. Show the Actual Product
- Prioritize real financial data (Today's spending, remaining budget, pending slips to triage).
- Do not let decorative illustrations push real financial content below the fold.

### 7. Enlarge the Main Feature
- Give primary hierarchy to the core metrics. The main daily spending number must be prominent (e.g. 32px font with tabular figures).

### 8. Group with Spacing
- Do NOT wrap card inside card inside card with heavy borders.
- Use whitespace and subtle dividers (`AppColors.border`) to create natural visual grouping.

### 9. Make Headlines Specific
- Use clear, actionable Thai copy:
  - ✅ `"วันพฤหัสบดีที่ 12 พ.ย."`
  - ✅ `"มีสลิป 3 ใบ รอปัดแยกหมวด"`
  - ✅ `"จัดหมวดหมู่สลิปครบแล้ว"`
  - ❌ Generic phrases like `"สรุปยอดค่าใช้จ่ายของคุณ"`.

### 10. Emphasize the CTA
- Primary action buttons must use high-contrast Electric Indigo (`#4F5FFA`) with bold white text. The user should never wonder what to click next.

### 11. Add an Accent Colour
- Strict accents: Electric Indigo (`#4F5FFA`) for primary user actions, Mint Green (`#2ED573`) for positive cashflow/success, Orange/Coral (`#FF5722`) for streaks.

### 12. Keep Icons Consistent
- Use the rounded Material icon family consistently (`Icons.*_rounded`). Never mix sharp, outlined, and duotone icons in the same view.

### 13. Remove Embellishments
- Remove tacky decorative noise: fake 3D bevels, fake altar lines (`List.generate`), decorative emojis inside speech bubbles, random star sparkles.

### 14. Golden Corner Radius Formula: Inner Radius = Outer - Padding
- Whenever nesting containers:
  `innerRadius = (outerRadius - padding).clamp(4.0, outerRadius)`
- Use `AppTheme.innerRadius(outer, padding)` and `AppTheme.innerBorderRadius(outer, padding)`.
- If an outer card has `radius = 24` and `padding = 16`, any child container inside it MUST have `radius = 8`.

### 15. Improve Text Contrast
- Primary text must be pure white `#FFFFFF`.
- Secondary text must be readable slate `#9EA3B8` (never dark grey `#63667B` on OLED black).

### 16. Wrap Headlines Properly
- Always use `Expanded`, `Flexible`, and `TextOverflow.ellipsis` on horizontal rows to prevent yellow-and-black RenderFlex overflows.

### 17. Align by Eye, Not Pixels
- Ensure visual optical balance. Currency symbols (`฿`) should align naturally with the baseline of numbers.

### 18. Use Tabular Numbers (`FontFeature.tabularFigures()`)
- All currency amounts, percentages, and dates MUST use `.withTabularFigures()` or `AppTheme.tabularFigures()`.
- This prevents digits from jumping or jittering when values update.

### 19. Add Loading States
- Always provide clean skeleton/loading states for asynchronous tasks (e.g., slip gallery scanning).

### 20. Animate Useful Feedback
- Reserve animations and haptics for meaningful feedback (e.g., swiping a card into a category, checking in a No-Spend day, tapping Moneta or the Sacred Goose).

---

## Character & Brand Lore

- **Mascot**: **Little Goddess Moneta** (Chibi Roman Goddess of Wealth & Mindful Spending) and **The Sacred Goose** (🪿).
- **Art Style**: Crisp 16/24-bit Vector Pixel Art (implemented in `lib/widgets/moneta_goddess_widget.dart`).
- **Do NOT** revert to generic Mintio geometry shapes with random googly eyes.

