---
description: Self-review the current diff against Kaso enterprise rules before committing.
---

Review the current `git diff` against enterprise criteria. Output checklist + score, and do not edit code.

## Checklist

### Architecture (BLOCKER)
- [ ] Swift files in correct layers? (Domain does not import Feature/Data)
- [ ] Any new `ObservableObject`? → must change to `@Observable`
- [ ] Any new `class ViewModel`? → must change to TCA Reducer
- [ ] Any unnecessary UIKit code? → flag it

### Code quality (MAJOR)
- [ ] `print()`? → `Logger`
- [ ] `try!` / `force unwrap`? → fix
- [ ] Hardcode color/font/spacing? → token `KasoDesignSystem`
- [ ] Hardcoded "VND"/Vietnamese dong symbol in UI strings? → formatter

### Concurrency (MAJOR)
- [ ] `@unchecked Sendable`? → find a way to remove it
- [ ] `DispatchQueue.main.async`? → `await MainActor.run`
- [ ] Reducer capture `self`?

### Testing (MAJOR)
- [ ] New reducers have TestStore tests?
- [ ] New views have snapshot tests?
- [ ] Coverage does not drop?

### Privacy & Security (BLOCKER)
- [ ] Amount/user name/phone number logged to console?
- [ ] PII sent to cloud (analytics, AI prompt)?
- [ ] Network calls have pinning?
- [ ] Sensitive data stored in Keychain (not UserDefaults)?

### Design & UX (MAJOR)
- [ ] New components have dark mode previews?
- [ ] Dynamic Type support?
- [ ] Animation honor `accessibilityReduceMotion`?
- [ ] VoiceOver labels complete?

### Localization (MINOR)
- [ ] New strings in String Catalog?
- [ ] Plural rules for both Vietnamese + English?
- [ ] Numbers/dates formatted through `.formatted()`?

## Output format

```
## Review: <branch> vs main

### Files changed: X (+Y -Z lines)

### 🚨 Blocker
- [file:line] <issue> — <fix>

### ⚠️ Major
- [file:line] <issue> — <fix>

### 💡 Minor
- [file:line] <issue> — <fix>

### ✓ Good
- <positive point>

## Score
- Architecture: X/10
- Code quality: X/10
- Concurrency: X/10
- Testing: X/10
- Privacy: X/10
- Design: X/10
- **Total: X/60**

## Verdict
✅ Pass / ⚠️ Fix major then pass / ❌ Block
```

## After Review

If it passes → suggest `/kaso-audit` to verify CI is clean.
Do not fix automatically — the user decides.
