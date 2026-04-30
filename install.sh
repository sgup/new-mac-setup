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

echo
echo "Done. Open a new terminal to load the new shell config."
