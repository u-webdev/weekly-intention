# 1. App Overview

**Name:** Weekly Intention  
**Platforms:** iOS, macOS  
**Includes:** App + Widget Extension  
**Status:** Submitted / Live (update as needed)

**One-liner:**  
A minimal app to set one intention per week and stay aligned — supported by a simple widget.

---

# 2. Core Philosophy

- One intention per week, by design
- Reflection over productivity
- Calm, distraction-free experience
- Built primarily for personal use, shared publicly as-is

**Non-goals:**
- No streaks or gamification
- No analytics-driven behavior
- No social features
- No feature bloat

---

# 3. Current Feature Scope

### App
- Create and edit one weekly intention
- Automatically scoped to calendar weeks
- Local-first storage (no backend)
- Simple navigation between weeks

### Widget
- Displays current week + intention
- Same behavior on iOS and macOS
- Updates immediately after save
- No timestamps shown (intentional)

---

# 4. Technical Snapshot

- **Language:** Swift / SwiftUI
- **Architecture:** Simple, local state
- **Storage:** On-device only
- **Widgets:** WidgetKit
- **Platforms:** iOS, macOS
- **visionOS:** Explicitly excluded

---

# 5. Design Constraints

- Minimal color palette
- Neutral, calming visuals
- Icon is intentionally simple (single dot metaphor)
- No onboarding unless absolutely necessary

---

# 6. App Store Context

- No sign-in
- No tracking
- No ads
- No payments
- Privacy policy: `PRIVACY.md`
- Metadata intentionally concise

---

# 7. Explicit Decisions & Tradeoffs

- Only one active intention at a time
- No widget configuration options
- No sync between devices (for now)
- macOS support is a first-class citizen

---

# 8. Release Strategy

- Small, focused releases
- Ship only when it feels “done enough”
- Personal usage is the primary quality gate
- Avoid roadmap pressure

---

# 9. Future Ideas (Not Commitments)

- Optional history view
- Optional reminders
- Optional iCloud sync
- Lightweight reflection notes

These are ideas, not promises.

---

# 10. How to Work With This Project

When contributing or extending:
- Prefer the simplest solution
- Avoid overengineering
- Question new features by default
- Respect existing decisions unless explicitly revisited