#!/usr/bin/env bash
# Symlink every dotfile in this repo into its target home location.
# Idempotent: re-running just refreshes the links. Existing files are backed up
# to <name>.bak.<timestamp> the first time so you never lose anything.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$dst.bak.$TIMESTAMP"
    echo "  backed up existing $dst → $dst.bak.$TIMESTAMP"
  fi
  ln -s "$src" "$dst"
  echo "  linked $dst → $src"
}

echo "Linking dotfiles from $REPO_DIR …"
link "$REPO_DIR/.zshrc"          "$HOME/.zshrc"
link "$REPO_DIR/.p10k.zsh"       "$HOME/.p10k.zsh"
link "$REPO_DIR/.gitconfig"      "$HOME/.gitconfig"
link "$REPO_DIR/ghostty/config"  "$GHOSTTY_DIR/config"

# Claude Code — installed via Anthropic's native installer (not Homebrew).
# Lives at ~/.local/bin/claude → ~/.local/share/claude/versions/<v>.
echo
if command -v claude >/dev/null 2>&1; then
  echo "Claude Code already installed: $(claude --version)"
else
  echo "Installing Claude Code …"
  curl -fsSL https://claude.ai/install.sh | bash
  echo "  → run 'claude' in a new terminal and sign in"
fi

# pnpm — standalone installer (matches PNPM_HOME=$HOME/Library/pnpm in .zshrc).
echo
if [[ -x "$HOME/Library/pnpm/pnpm" ]]; then
  echo "pnpm already installed: $("$HOME/Library/pnpm/pnpm" --version)"
else
  echo "Installing pnpm …"
  curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# EAS CLI — install into mise's node so `eas build/submit/update` works in
# fresh shells. Requires `mise use --global node@22` to have run already.
echo
if command -v mise >/dev/null 2>&1 && mise exec node@22 -- which eas >/dev/null 2>&1; then
  echo "eas-cli already installed: $(mise exec node@22 -- eas --version | head -1)"
elif command -v mise >/dev/null 2>&1; then
  echo "Installing eas-cli into mise's node …"
  mise exec node@22 -- npm install -g eas-cli
else
  echo "⚠️  Skipping eas-cli — install mise + node first, then re-run."
fi

echo
echo "Done. Open a new terminal to load the new shell config."
