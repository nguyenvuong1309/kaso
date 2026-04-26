# `.codex/` — OpenAI Codex CLI Configuration for Kaso

This folder contains template configuration + custom prompts for **Codex CLI** when working on the Kaso project.

## Structure

```
.codex/
├── README.md                # This file
├── config.toml              # Codex config template (copy/merge into ~/.codex/config.toml)
├── install.sh               # Script that installs config + prompts into ~/.codex/
├── prompts/                 # Custom slash commands (installed as /kaso-*)
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
└── agents/                  # Codex agent profiles (templates)
    ├── swift-reviewer.md
    ├── tca-architect.md
    └── metal-shader-expert.md
```

## How Codex Reads Config

Codex CLI reads in this order:

1. **`~/.codex/config.toml`** — global config (model, sandbox, approval, MCP)
2. **`~/.codex/AGENTS.md`** — global instructions (personal)
3. **`./AGENTS.md`** (project root) — project instructions (auto-load)
4. **`~/.codex/prompts/*.md`** — custom slash commands

The project root `AGENTS.md` already exists — Codex will read it automatically when you `cd` into the project.

## Installation

### Option 1: Auto install (recommended)

```bash
cd /Users/vuongnguyen/dev3/kaso
bash .codex/install.sh
```

The script will:
- Back up existing `~/.codex/config.toml` (if any) to `config.toml.bak`
- Merge Kaso config into `~/.codex/config.toml`
- Symlink `.codex/prompts/*.md` → `~/.codex/prompts/kaso-*.md` (namespace avoids conflicts)
- Symlink `.codex/agents/*.md` → `~/.codex/agents/kaso-*.md`

### Option 2: Manual

```bash
# 1. Copy config (review first if ~/.codex/config.toml exists)
cp .codex/config.toml ~/.codex/config.toml

# 2. Symlink prompts with namespace
mkdir -p ~/.codex/prompts
for f in .codex/prompts/*.md; do
  name=$(basename "$f" .md)
  ln -sf "$(pwd)/$f" "$HOME/.codex/prompts/kaso-$name.md"
done
```

### Option 3: Project-only (if newer Codex versions support project-local prompts)

Some newer Codex CLI versions support reading `./.codex/prompts/`. Check:

```bash
codex --version  # requires a supported version
```

If supported, no installation is needed — just `cd` into the project.

## Slash commands

After installation, use in Codex:

| Command | Description |
|---------|-------|
| `/kaso-feature <Name>` | Scaffold a new TCA feature module |
| `/kaso-build [scheme]` | Build app |
| `/kaso-test [scope]` | Run tests |
| `/kaso-lint [fix]` | SwiftLint + SwiftFormat |
| `/kaso-shader <Name> [type]` | Scaffold Metal shader |
| `/kaso-snapshot` | Manage snapshot tests |
| `/kaso-audit` | Full pre-commit pipeline |
| `/kaso-preview <View>` | Audit SwiftUI Preview coverage |
| `/kaso-review` | Self-review current diff |
| `/kaso-release` | Release pipeline |

## Recommended Configuration

`config.toml` sets:

- **Model**: `gpt-5-codex` (or `o3` if you have access) — best for large coding tasks
- **Sandbox**: `workspace-write` — enough for development, does not touch outside the project
- **Approval**: `on-failure` — asks only when an action fails
- **History**: persistent
- **Profile `kaso`**: dedicated project profile with MCP server config

Activate profile:
```bash
codex --profile kaso
```

Or set it as default in `~/.codex/config.toml`:
```toml
profile = "kaso"
```

## Comparison with `.claude/`

| Concept | Claude Code | Codex CLI |
|-----------|-------------|-----------|
| Project rules | `.claude/CLAUDE.md` | `AGENTS.md` (root) |
| Permissions/sandbox | `.claude/settings.json` | `~/.codex/config.toml` |
| Slash commands | `.claude/commands/*.md` | `~/.codex/prompts/*.md` |
| Subagents | `.claude/agents/*.md` | Codex has no native subagent — use `agents/` templates as system prompts |
| Skills (auto-trigger) | `.claude/skills/*/SKILL.md` | No equivalent — put content into AGENTS.md |
| Hooks | `.claude/hooks/*.sh` | Codex has no hooks — use git hooks or tool wrappers |

## Maintenance

- `AGENTS.md` (root) is the source of truth — update when conventions change
- `.codex/prompts/` mirrors `.claude/commands/` — sync when updated
- `.codex/agents/` mirrors `.claude/agents/` — adapted for Codex (system prompt format)
- `config.toml` only commits recommendations; users can still override it

## Uninstall

```bash
bash .codex/install.sh --uninstall
```

Or manually delete `~/.codex/prompts/kaso-*.md` and revert `config.toml.bak`.
