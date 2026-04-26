---
description: Run tests for Kaso (unit + snapshot). Optionally filter by scope.
argument-hint: [scope] (for example: TransactionFeature, Domain, all)
---

Run tests for the Kaso project.

## Logic

- No argument → run all tests
- Argument is a package/feature name → run tests for that package
- Argument `snapshot` → record mode for snapshot tests
- Argument `failed` → re-run only the previous failed tests

## Commands

```bash
# All tests via SPM (fast, no simulator required)
swift test --parallel

# Specific package
swift test --package-path Packages/Features/$1Feature --parallel

# Via Xcode (if a simulator is needed)
xcodebuild test \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -parallel-testing-enabled YES \
  -test-iterations 1 \
  -resultBundlePath .build/TestResults.xcresult \
  | xcbeautify --renderer terminal
```

## Report

- **Pass count / Fail count / Skipped count**
- If failing: list `FILE:LINE — test name — reason`, propose a fix
- If coverage drops below threshold: warn (Domain ≥ 90%, Features ≥ 80%)
- If snapshots fail: ask whether the user wants to re-record (do not auto re-record)

## After Passing

- Suggest next step: lint, full build, or commit
- If a Swift file changed without new tests: warn
