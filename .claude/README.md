# `.claude/` — Cấu hình Claude Code cho Kaso

Folder này chứa toàn bộ cấu hình project cho Claude Code: rules, hooks, slash commands, skills, subagents.

## Cấu trúc

```
.claude/
├── README.md                 # File này
├── CLAUDE.md                 # Rules project (tự load mỗi session)
├── settings.json             # Permissions, hooks, env (commit vào git)
├── settings.local.json       # Override cá nhân (gitignored)
│
├── hooks/                    # Bash scripts gọi từ settings.json
│   ├── swift-post-edit.sh    # Auto format/lint sau edit Swift
│   ├── guard-destructive.sh  # Chặn lệnh nguy hiểm (force push, rm -rf)
│   ├── session-context.sh    # Inject git status + project info đầu session
│   └── stop-reminder.sh      # Nhắc test/build khi Claude kết thúc lượt
│
├── commands/                 # Slash commands (gọi qua /name)
│   ├── feature.md            # /feature <Name> — scaffold TCA feature
│   ├── build.md              # /build [scheme] — build app
│   ├── test.md               # /test [scope] — run tests
│   ├── lint.md               # /lint [fix] — SwiftLint + SwiftFormat
│   ├── shader.md             # /shader <Name> [type] — scaffold Metal shader
│   ├── snapshot.md           # /snapshot [record|verify|clean]
│   ├── audit.md              # /audit — full pre-commit pipeline
│   ├── preview.md            # /preview <View> — audit SwiftUI Preview coverage
│   ├── review-changes.md     # /review-changes — self-review diff
│   └── release.md            # /release [patch|minor|major] — release pipeline
│
├── skills/                   # Domain knowledge (auto-trigger theo description)
│   ├── tca-patterns/SKILL.md
│   ├── swiftui-metal-bridge/SKILL.md
│   ├── kaso-design-system/SKILL.md
│   └── swift6-concurrency/SKILL.md
│
└── agents/                   # Subagents chuyên biệt
    ├── swift-reviewer.md         # Review Swift code
    ├── tca-architect.md          # Design TCA architecture
    ├── metal-shader-expert.md    # Metal/MSL specialist
    └── accessibility-auditor.md  # A11y compliance check
```

## Cách dùng

### Slash commands

Gõ `/` trong Claude Code, chọn từ danh sách:
- `/feature TransactionList` — tạo TCA feature mới
- `/shader Confetti color` — tạo Metal shader
- `/audit` — full pre-commit check
- `/review-changes` — self-review trước commit

### Subagents

Gọi explicit khi cần expert review:
- "Hãy gọi `swift-reviewer` audit file `TransactionFeature.swift`"
- "Dùng `tca-architect` thiết kế navigation cho onboarding flow"
- "Dùng `metal-shader-expert` viết shader cho liquid balance indicator"
- "Dùng `accessibility-auditor` check `DashboardView`"

### Skills

Skills tự động trigger khi context phù hợp (theo `description` frontmatter). Không cần gọi explicit — chỉ cần làm việc với code TCA / Metal / Design System / Concurrency và Claude sẽ apply skill tương ứng.

## Hooks behavior

| Event | Hook | Tác dụng |
|-------|------|----------|
| `PostToolUse` (Edit/Write) | `swift-post-edit.sh` | Auto chạy `swiftformat` + `swiftlint` cho file `.swift` vừa edit, compile `.metal` để verify syntax |
| `PreToolUse` (Bash) | `guard-destructive.sh` | Chặn `rm -rf /`, `git push --force`, `git reset --hard`, `--no-verify` |
| `SessionStart` | `session-context.sh` | Inject git branch + modified file count + project type vào context |
| `Stop` | `stop-reminder.sh` | Nhắc test/build nếu có Swift file modified |

## Permissions

Đã pre-allow các tool thường dùng cho dev iOS:
- Swift toolchain: `swift`, `swiftc`, `swiftformat`, `swiftlint`
- Xcode: `xcodebuild`, `xcrun`, `xcbeautify`
- Project: `tuist`, `mint`, `fastlane`, `maestro`
- Inspect: `periphery`, `sourcery`
- Read-only git: `git status/diff/log/show/branch/...`

Cần ask trước khi:
- `git commit`, `git push`
- Fastlane release/beta
- Upload App Store

Cấm tuyệt đối:
- `git push --force`
- `git reset --hard` với HEAD/origin
- Đọc file secret (`.env`, `Secrets.plist`, certs, provisioning profile)

## Cá nhân hoá

Tạo `.claude/settings.local.json` (đã gitignore) để override không ảnh hưởng team:

```json
{
  "permissions": {
    "allow": ["Bash(your-personal-tool:*)"]
  }
}
```

## Bảo trì

- Update `CLAUDE.md` khi quy ước project thay đổi
- Update skill khi pattern mới được áp dụng
- Update agent description khi scope thay đổi
- Test hook script local trước khi commit (`bash .claude/hooks/X.sh`)
