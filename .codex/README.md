# `.codex/` — Cấu hình OpenAI Codex CLI cho Kaso

Folder này chứa template config + custom prompts cho **Codex CLI** khi làm việc với project Kaso.

## Cấu trúc

```
.codex/
├── README.md                # File này
├── config.toml              # Codex config template (copy/merge vào ~/.codex/config.toml)
├── install.sh               # Script tự động cài config + prompts vào ~/.codex/
├── prompts/                 # Custom slash commands (sẽ install thành /kaso-*)
│   ├── feature.md           # /kaso-feature <Name>
│   ├── build.md             # /kaso-build [scheme]
│   ├── test.md              # /kaso-test [scope]
│   ├── lint.md              # /kaso-lint [fix]
│   ├── shader.md            # /kaso-shader <Name> [type]
│   ├── snapshot.md          # /kaso-snapshot
│   ├── audit.md             # /kaso-audit (full pre-commit)
│   ├── preview.md           # /kaso-preview <View>
│   ├── review.md            # /kaso-review (self-review diff)
│   └── release.md           # /kaso-release [patch|minor|major]
└── agents/                  # Codex agent profiles (template)
    ├── swift-reviewer.md
    ├── tca-architect.md
    └── metal-shader-expert.md
```

## Cách Codex đọc config

Codex CLI đọc theo thứ tự:

1. **`~/.codex/config.toml`** — global config (model, sandbox, approval, MCP)
2. **`~/.codex/AGENTS.md`** — global instructions (cá nhân)
3. **`./AGENTS.md`** (project root) — project instructions (auto-load)
4. **`~/.codex/prompts/*.md`** — custom slash commands

Project root `AGENTS.md` đã có sẵn — Codex sẽ tự đọc khi `cd` vào project.

## Cài đặt

### Option 1: Auto install (recommended)

```bash
cd /Users/vuongnguyen/dev3/kaso
bash .codex/install.sh
```

Script sẽ:
- Backup `~/.codex/config.toml` hiện có (nếu có) thành `config.toml.bak`
- Merge config Kaso vào `~/.codex/config.toml`
- Symlink `.codex/prompts/*.md` → `~/.codex/prompts/kaso-*.md` (namespace tránh conflict)
- Symlink `.codex/agents/*.md` → `~/.codex/agents/kaso-*.md`

### Option 2: Manual

```bash
# 1. Copy config (review trước nếu có ~/.codex/config.toml)
cp .codex/config.toml ~/.codex/config.toml

# 2. Symlink prompts với namespace
mkdir -p ~/.codex/prompts
for f in .codex/prompts/*.md; do
  name=$(basename "$f" .md)
  ln -sf "$(pwd)/$f" "$HOME/.codex/prompts/kaso-$name.md"
done
```

### Option 3: Project-only (nếu Codex version mới hỗ trợ project-local prompts)

Một số version Codex CLI mới hỗ trợ đọc `./.codex/prompts/`. Kiểm tra:

```bash
codex --version  # cần version hỗ trợ
```

Nếu có, không cần install gì — chỉ cần `cd` vào project.

## Slash commands

Sau khi install, dùng trong Codex:

| Command | Mô tả |
|---------|-------|
| `/kaso-feature <Name>` | Scaffold TCA feature module mới |
| `/kaso-build [scheme]` | Build app |
| `/kaso-test [scope]` | Run tests |
| `/kaso-lint [fix]` | SwiftLint + SwiftFormat |
| `/kaso-shader <Name> [type]` | Scaffold Metal shader |
| `/kaso-snapshot` | Quản lý snapshot test |
| `/kaso-audit` | Full pre-commit pipeline |
| `/kaso-preview <View>` | Audit SwiftUI Preview coverage |
| `/kaso-review` | Self-review diff hiện tại |
| `/kaso-release` | Release pipeline |

## Cấu hình recommend

`config.toml` đã set:

- **Model**: `gpt-5-codex` (hoặc `o3` nếu có access) — tốt nhất cho coding task lớn
- **Sandbox**: `workspace-write` — đủ cho dev, không touch ngoài project
- **Approval**: `on-failure` — chỉ hỏi khi action fail
- **History**: persistent
- **Profile `kaso`**: profile riêng cho project, có MCP servers config

Activate profile:
```bash
codex --profile kaso
```

Hoặc set default trong `~/.codex/config.toml`:
```toml
profile = "kaso"
```

## So sánh với `.claude/`

| Khái niệm | Claude Code | Codex CLI |
|-----------|-------------|-----------|
| Project rules | `.claude/CLAUDE.md` | `AGENTS.md` (root) |
| Permissions/sandbox | `.claude/settings.json` | `~/.codex/config.toml` |
| Slash commands | `.claude/commands/*.md` | `~/.codex/prompts/*.md` |
| Subagents | `.claude/agents/*.md` | Codex không có native subagent — dùng `agents/` template làm system prompt |
| Skills (auto-trigger) | `.claude/skills/*/SKILL.md` | Không có equivalent — đưa vào AGENTS.md |
| Hooks | `.claude/hooks/*.sh` | Codex không có hook — dùng git hook hoặc tool wrapper |

## Bảo trì

- `AGENTS.md` (root) là source of truth — update khi quy ước thay đổi
- `.codex/prompts/` mirror `.claude/commands/` — sync khi update
- `.codex/agents/` mirror `.claude/agents/` — adapt theo Codex (system prompt format)
- `config.toml` chỉ commit recommendation, user vẫn có thể override

## Uninstall

```bash
bash .codex/install.sh --uninstall
```

Hoặc thủ công xoá `~/.codex/prompts/kaso-*.md` và revert `config.toml.bak`.
