---
description: Self-review current changes against Kaso rules before committing
---

Review Kaso local changes against enterprise criteria.

## Checklist

### Architecture
- [ ] Any Swift file in the wrong layer? (Domain must not import Feature/Data)
- [ ] Any new ObservableObject? → must change to `@Observable`
- [ ] Any new ViewModel? → must change to TCA Reducer
- [ ] Any unnecessary UIKit code? → flag it

### Code quality
- [ ] Any `print()`? → replace with `Logger`
- [ ] Any `try!` / `force unwrap`? → fix it
- [ ] Any hardcoded color/font/spacing? → use `KasoDesignSystem` tokens
- [ ] Any hardcoded currency code "VND" in UI strings? → use formatter

### Concurrency
- [ ] `@unchecked Sendable` appears? → find a way to remove it
- [ ] `DispatchQueue.main.async`? → replace with `await MainActor.run`
- [ ] Does a reducer capture `self` unnecessarily?

### Testing
- [ ] Does every new `Reducer` have tests?
- [ ] Does every new `View` have snapshot tests?
- [ ] Does coverage stay above thresholds?

### Privacy & Security
- [ ] Any amount/user name/phone number logged to console?
- [ ] Any PII sent to cloud (analytics, AI prompt)?
- [ ] Do network calls have pinning?
- [ ] Is sensitive data stored in Keychain (not UserDefaults)?

### Design & UX
- [ ] Do new components have dark mode previews?
- [ ] Is Dynamic Type supported?
- [ ] Do animations honor `accessibilityReduceMotion`?
- [ ] Are VoiceOver labels complete?

### Localization
- [ ] Are new strings in String Catalog?
- [ ] Are plural rules correct for both Vietnamese + English?
- [ ] Are numbers/dates formatted through `Decimal.formatted` / `Date.formatted`?

## Output

Score each group (0-10), listing specific items:
- Violating file:line
- Severity (blocker / major / minor)
- Suggested fix

Do not fix automatically — report only. The user decides.

## After Review

If everything passes → suggest running `/audit` to verify CI is clean.
