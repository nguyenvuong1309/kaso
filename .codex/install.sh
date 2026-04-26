#!/usr/bin/env bash
# Install Codex config + prompts for the Kaso project into ~/.codex/
# Usage:
#   bash .codex/install.sh             # install
#   bash .codex/install.sh --uninstall # remove

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
NAMESPACE="kaso"

ACTION="${1:-install}"

color() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
info()  { color "1;34" "→ $1"; }
ok()    { color "1;32" "✓ $1"; }
warn()  { color "1;33" "⚠ $1"; }
err()   { color "1;31" "✗ $1"; }

ensure_dir() { mkdir -p "$1"; }

uninstall() {
    info "Uninstalling Kaso Codex config..."

    # Remove namespaced symlinks
    for dir in prompts agents; do
        target_dir="$CODEX_HOME/$dir"
        if [[ -d "$target_dir" ]]; then
            removed=0
            for f in "$target_dir/$NAMESPACE-"*.md; do
                [[ -e "$f" ]] || continue
                rm -f "$f"
                removed=$((removed + 1))
            done
            if [[ $removed -gt 0 ]]; then
                ok "Removed $removed symlink(s) from $target_dir"
            fi
        fi
    done

    # Restore config backup
    if [[ -f "$CODEX_HOME/config.toml.kaso.bak" ]]; then
        mv "$CODEX_HOME/config.toml.kaso.bak" "$CODEX_HOME/config.toml"
        ok "Restored config.toml from backup"
    else
        warn "No config.toml backup found — manual cleanup may be needed"
    fi

    ok "Uninstall complete"
    exit 0
}

if [[ "$ACTION" == "--uninstall" ]] || [[ "$ACTION" == "uninstall" ]]; then
    uninstall
fi

# === Install ===

info "Installing Kaso Codex config to $CODEX_HOME"

ensure_dir "$CODEX_HOME"
ensure_dir "$CODEX_HOME/prompts"
ensure_dir "$CODEX_HOME/agents"

# Backup existing config
if [[ -f "$CODEX_HOME/config.toml" ]]; then
    if [[ ! -f "$CODEX_HOME/config.toml.kaso.bak" ]]; then
        cp "$CODEX_HOME/config.toml" "$CODEX_HOME/config.toml.kaso.bak"
        ok "Backed up existing config.toml → config.toml.kaso.bak"
    else
        warn "Backup exists from previous install — keeping it"
    fi
fi

# Append/install config (don't overwrite — append marker section)
if [[ -f "$CODEX_HOME/config.toml" ]] && grep -q "# === Kaso project profile ===" "$CODEX_HOME/config.toml" 2>/dev/null; then
    warn "Kaso section already in config.toml — skipping"
else
    {
        echo ""
        echo "# === Kaso project profile (managed by .codex/install.sh) ==="
        echo "# Activate: codex --profile kaso"
        echo ""
        cat "$SCRIPT_DIR/config.toml"
        echo ""
        echo "# === End Kaso section ==="
    } >> "$CODEX_HOME/config.toml"
    ok "Appended Kaso config to $CODEX_HOME/config.toml"
fi

# Symlink prompts with namespace
linked=0
for f in "$SCRIPT_DIR"/prompts/*.md; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f" .md)
    target="$CODEX_HOME/prompts/$NAMESPACE-$name.md"
    ln -sf "$f" "$target"
    linked=$((linked + 1))
done
ok "Linked $linked prompt(s) → ~/.codex/prompts/$NAMESPACE-*.md"

# Symlink agents
linked=0
for f in "$SCRIPT_DIR"/agents/*.md; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f" .md)
    target="$CODEX_HOME/agents/$NAMESPACE-$name.md"
    ln -sf "$f" "$target"
    linked=$((linked + 1))
done
if [[ $linked -gt 0 ]]; then
    ok "Linked $linked agent(s) → ~/.codex/agents/$NAMESPACE-*.md"
fi

cat <<EOF

$(color "1;32" "═══════════════════════════════════════════")
$(color "1;32" "  Kaso Codex setup complete")
$(color "1;32" "═══════════════════════════════════════════")

Next steps:
  1. Verify config:    cat ~/.codex/config.toml
  2. Activate profile: codex --profile kaso
  3. Try a command:    /kaso-build, /kaso-test, /kaso-feature MyFeature

Available slash commands (Codex):
EOF

for f in "$SCRIPT_DIR"/prompts/*.md; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f" .md)
    desc=$(grep -m1 '^description:' "$f" 2>/dev/null | sed 's/description: *//' || echo "")
    printf "  /%s-%-12s %s\n" "$NAMESPACE" "$name" "$desc"
done

cat <<EOF

To uninstall: bash .codex/install.sh --uninstall

EOF
