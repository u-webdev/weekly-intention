## 1. App Overview

**Name:** Weekly Intention  
**Platforms:** iOS, macOS (Apple Watch widget planned)  
**Includes:** App + Widgets  
**Status:** Live

**One-liner:**  
A minimal app to hold **one intention per calendar week** and keep it gently present across devices.

---

## 2. Core Product Rule (Non-Negotiable)

> **At any given moment, there is exactly one current intention per week — and it is the same on every device.**

- Intentions can be changed at any time
    
- There is no “versioning” exposed to the user
    
- All surfaces converge to the same value
    

This rule applies to:

- iPhone app
    
- macOS app
    
- iOS & macOS widgets
    
- Apple Watch widget
    

Sync is therefore **foundational**, not optional.

---

## 3. Philosophy

- Orientation over productivity
    
- Presence over execution
    
- Visibility without pressure
    
- Built primarily for personal use, shared openly
    

**Non-goals:**

- No streaks
    
- No gamification
    
- No analytics-driven behavior
    
- No social features
    
- No feature bloat
    

---

## 4. Current Feature Scope

### App

- Create and edit one intention per calendar week
    
- Navigate between weeks
    
- Change intention mid-week without penalty
    
- Local-first UX, iCloud-backed persistence
    

### Widgets

- Show current week + intention
    
- Read-only
    
- Designed for glanceability
    

---

## 5. Data & Sync Model

- **Storage:** SwiftData
    
- **Sync:** iCloud / CloudKit (private database)
    
- **Source of truth:** CloudKit-backed model container
    
- **Conflict policy:** Last write wins (timestamp-based)
    

Design intent:

- All devices eventually converge
    
- Temporary divergence is acceptable
    
- Permanent divergence is not
    

---

## 6. Design Constraints

- Minimal color palette
    
- Calm, neutral visuals
    
- Icon as a single dot (orientation metaphor)
    
- No onboarding unless absolutely necessary
    

---

## 7. App Store Context

- No sign-in
    
- No ads
    
- No tracking
    
- No payments
    
- Privacy-first
    
- Metadata intentionally concise
    

---

## 8. Explicitly Out of Scope

- Full watchOS app
    
- Interactive widgets
    
- Multiple simultaneous intentions
    
- Cross-user sharing
    
- Growth features
    

---

## 9. Working Principles

- Prefer the simplest solution
    
- Ship only what is needed
    
- Small, finishable releases
    
- Reflection after shipping
    
- No roadmap pressure
    

An app is complete when it is **clear, calm, and reliable at its current resolution**.