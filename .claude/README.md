# `.claude/` — Claude Code Configuration for Kaso

This folder contains all project configuration for Claude Code: rules, hooks, slash commands, skills, and subagents.

## Structure

```
.claude/
├── README.md                 # This file
├── CLAUDE.md                 # Project rules (auto-loaded every session)
├── settings.json             # Permissions, hooks, env (committed to git)
├── settings.local.json       # Personal overrides (gitignored)
│
├── hooks/                    # Bash scripts called from settings.json
│   ├── swift-post-edit.sh    # Auto format/lint after Swift edits
│   ├── guard-destructive.sh  # Block dangerous commands (force push, rm -rf)
│   ├── session-context.sh    # Inject git status + project info at session start
│   └── stop-reminder.sh      # Remind about tests/builds when Claude ends a turn
│
├── commands/                 # Slash commands (called with /name)
│   ├── feature.md            # /feature <Name> — scaffold a TCA feature
│   ├── build.md              # /build [scheme] — build the app
│   ├── test.md               # /test [scope] — run tests
│   ├── lint.md               # /lint [fix] — SwiftLint + SwiftFormat
│   ├── shader.md             # /shader <Name> [type] — scaffold a Metal shader
│   ├── snapshot.md           # /snapshot [record|verify|clean]
│   ├── audit.md              # /audit — full pre-commit pipeline
│   ├── preview.md            # /preview <View> — audit SwiftUI Preview coverage
│   ├── review-changes.md     # /review-changes — self-review the diff
│   └── release.md            # /release [patch|minor|major] — release pipeline
│
├── skills/                   # Domain knowledge (auto-triggered by description)
│   ├── tca-patterns/SKILL.md
│   ├── swiftui-metal-bridge/SKILL.md
│   ├── kaso-design-system/SKILL.md
│   └── swift6-concurrency/SKILL.md
│
└── agents/                   # Specialized subagents
    ├── swift-reviewer.md         # Review Swift code
    ├── tca-architect.md          # Design TCA architecture
    ├── metal-shader-expert.md    # Metal/MSL specialist
    └── accessibility-auditor.md  # A11y compliance check
```

## Usage

### Slash commands

Type `/` in Claude Code and choose from the list:
- `/feature TransactionList` — create a new TCA feature
- `/shader Confetti color` — create a Metal shader
- `/audit` — full pre-commit check
- `/review-changes` — self-review before committing

### Subagents

Call them explicitly when expert review is needed:
- "Call `swift-reviewer` to audit `TransactionFeature.swift`"
- "Use `tca-architect` to design navigation for the onboarding flow"
- "Use `metal-shader-expert` to write the shader for the liquid balance indicator"
- "Use `accessibility-auditor` to check `DashboardView`"

### Skills

Skills trigger automatically when context matches their frontmatter `description`. You do not need to call them explicitly — work with TCA / Metal / Design System / Concurrency code and Claude will apply the matching skill.

## Hooks behavior

| Event | Hook | Effect |
|-------|------|----------|
| `PostToolUse` (Edit/Write) | `swift-post-edit.sh` | Auto-runs `swiftformat` + `swiftlint` for edited `.swift` files and compiles `.metal` files to verify syntax |
| `PreToolUse` (Bash) | `guard-destructive.sh` | Blocks `rm -rf /`, `git push --force`, `git reset --hard`, `--no-verify` |
| `SessionStart` | `session-context.sh` | Injects git branch + modified file count + project type into context |
| `Stop` | `stop-reminder.sh` | Reminds about tests/builds when Swift files are modified |

## Permissions

Common iOS development tools are pre-allowed:
- Swift toolchain: `swift`, `swiftc`, `swiftformat`, `swiftlint`
- Xcode: `xcodebuild`, `xcrun`, `xcbeautify`
- Project: `tuist`, `mint`, `fastlane`, `maestro`
- Inspect: `periphery`, `sourcery`
- Read-only git: `git status/diff/log/show/branch/...`

Ask before:
- `git commit`, `git push`
- Fastlane release/beta
- Upload App Store

Strictly forbidden:
- `git push --force`
- `git reset --hard` with HEAD/origin
- Reading secret files (`.env`, `Secrets.plist`, certs, provisioning profiles)

## Personalization

Create `.claude/settings.local.json` (gitignored) to override settings without affecting the team:

```json
{
  "permissions": {
    "allow": ["Bash(your-personal-tool:*)"]
  }
}
```

## Maintenance

- Update `CLAUDE.md` when project conventions change
- Update skills when new patterns are adopted
- Update agent descriptions when scope changes
- Test hook scripts locally before committing (`bash .claude/hooks/X.sh`)
