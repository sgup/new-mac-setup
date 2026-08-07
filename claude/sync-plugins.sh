#!/usr/bin/env bash
# Apply the tracked Claude Code agent config to this machine.
#
# Two steps, because settings alone are not enough: `enabledPlugins` is inert
# until a plugin is actually installed. Claude Code does not install from it,
# so a machine can look correctly configured and still have no plugins.
#
# Called by install.sh; safe to run directly and safe to re-run.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRAGMENT="$REPO_DIR/claude/settings.plugins.json"
SETTINGS="$HOME/.claude/settings.json"

command -v jq >/dev/null 2>&1 || {
  echo "  jq not found — skipping agent config (install jq, then re-run)"; exit 0; }
[ -f "$FRAGMENT" ] || { echo "  no settings.plugins.json — nothing to apply"; exit 0; }

# --- 1. Merge the fragment into settings.json --------------------------------
# Merged, not copied: settings.json also holds machine-specific keys (hooks,
# statusLine, theme, permissions) that this repo does not own. The fragment
# wins for its own keys only.
mkdir -p "$HOME/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
_tmp="$(mktemp)"
if jq -s '.[0] * .[1]' "$SETTINGS" "$FRAGMENT" > "$_tmp" && [ -s "$_tmp" ]; then
  # Redirect rather than mv: settings.json may be a symlink, and mv would
  # replace the link instead of writing through it.
  cat "$_tmp" > "$SETTINGS"
  echo "  merged agent config into $SETTINGS"
else
  echo "  merge FAILED — settings.json left untouched"
fi
rm -f "$_tmp"

command -v claude >/dev/null 2>&1 || {
  echo "  claude not on PATH — skipping plugin install"; exit 0; }

# --- 2. Register marketplaces -------------------------------------------------
# From marketplaces.json, not settings.json: `extraKnownMarketplaces` holds
# only the ones added by hand. The rest live in the plugin cache's
# known_marketplaces.json, and omitting them makes their plugins uninstallable
# (frontend-design@claude-code-plugins failed exactly this way).
MARKETPLACES="$REPO_DIR/claude/marketplaces.json"
if [ -f "$MARKETPLACES" ]; then
  while read -r src; do
    [ -n "$src" ] || continue
    claude plugin marketplace add "$src" >/dev/null 2>&1 \
      && echo "  marketplace: $src" \
      || echo "  marketplace skipped (already present, or upstream unreachable): $src"
  done < <(jq -r '.[] | (.repo // .url) // empty' "$MARKETPLACES")
fi

# --- 3. Install everything marked enabled ------------------------------------
installed="$(claude plugin list 2>/dev/null || true)"
while read -r plugin; do
  [ -n "$plugin" ] || continue
  # swift-lsp needs a Swift toolchain; there is none on Linux.
  if [ "$(uname -s)" = "Linux" ] && [[ "$plugin" == swift-lsp@* ]]; then
    echo "  skipped (needs a Mac): $plugin"; continue
  fi
  case "$installed" in
    *"${plugin%%@*}"*) echo "  already installed: $plugin"; continue ;;
  esac
  claude plugin install "$plugin" >/dev/null 2>&1 \
    && echo "  installed: $plugin" \
    || echo "  FAILED: $plugin"
done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$FRAGMENT")
