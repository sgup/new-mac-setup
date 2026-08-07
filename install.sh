#!/usr/bin/env bash
# Symlink every dotfile in this repo into its target home location.
# Idempotent: re-running just refreshes the links. Existing files are backed up
# to <name>.bak.<timestamp> the first time so you never lose anything.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
OS="$(uname -s)"

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

echo "Linking dotfiles from $REPO_DIR ($OS) …"

# The shells diverge enough that one file with OS guards would be mostly guards:
# different plugin paths, editor, pnpm home, and fzf keybinding location. Keep
# two files; linux/.zshrc marks each divergence with a LINUX comment.
if [[ "$OS" == "Linux" ]]; then
  link "$REPO_DIR/linux/.zshrc"  "$HOME/.zshrc"
else
  link "$REPO_DIR/.zshrc"        "$HOME/.zshrc"
fi

link "$REPO_DIR/.p10k.zsh"       "$HOME/.p10k.zsh"
link "$REPO_DIR/.gitconfig"      "$HOME/.gitconfig"

# Ghostty is macOS-only here; on Linux the terminal lives on the client machine.
if [[ "$OS" == "Darwin" ]]; then
  link "$REPO_DIR/ghostty/config"  "$GHOSTTY_DIR/config"
fi

# Claude Code statusline. Portable: the epoch formatter tries BSD `date -r`
# then GNU `date -d @`, and the tty walk accepts both ttysN and pts/N.
# Registering it is separate — settings.json needs:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
link "$REPO_DIR/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

# Agent context. AGENTS.md holds the shared rules (branch discipline, secrets)
# read by every coding agent: Codex reads ~/.codex/AGENTS.md directly, and
# CLAUDE.md pulls it in via `@~/.dotfiles/AGENTS.md` for Claude Code (whose
# global also carries the Claude-only model-routing notes).
link "$REPO_DIR/AGENTS.md"        "$HOME/.codex/AGENTS.md"
link "$REPO_DIR/CLAUDE.md"        "$HOME/.claude/CLAUDE.md"

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

# pnpm — standalone installer. PNPM_HOME differs per OS and each .zshrc exports
# the matching one: ~/Library/pnpm on macOS, ~/.local/share/pnpm on Linux.
if [[ "$OS" == "Linux" ]]; then PNPM_DIR="$HOME/.local/share/pnpm"; else PNPM_DIR="$HOME/Library/pnpm"; fi
echo
if [[ -x "$PNPM_DIR/pnpm" ]]; then
  echo "pnpm already installed: $("$PNPM_DIR/pnpm" --version)"
else
  echo "Installing pnpm …"
  curl -fsSL https://get.pnpm.io/install.sh | sh -
  # The installer appends its own PNPM_HOME block to the shell rc. By this
  # point that rc is a SYMLINK into this repo, so the append lands in tracked
  # source and dirties the working tree on every run — and it lands after the
  # zoxide block, which is documented as needing to stay last. Our .zshrc
  # already exports PNPM_HOME and both PATH candidates, so drop the block.
  if [[ -f "$HOME/.zshrc" ]]; then
    perl -0pi -e 's/\n?# pnpm\n.*?\n# pnpm end\n//s' "$HOME/.zshrc"
  fi
fi

# EAS CLI — install into mise's node so `eas build/submit/update` works in
# fresh shells. Requires `mise use --global node@22` to have run already.
# Skipped on Linux: the mobile toolchain needs Xcode, so a Linux box has no
# use for it.
echo
if [[ "$OS" == "Linux" ]]; then
  echo "Skipping eas-cli — mobile builds need a Mac."
elif command -v mise >/dev/null 2>&1 && mise exec node@22 -- which eas >/dev/null 2>&1; then
  echo "eas-cli already installed: $(mise exec node@22 -- eas --version | head -1)"
elif command -v mise >/dev/null 2>&1; then
  echo "Installing eas-cli into mise's node …"
  mise exec node@22 -- npm install -g eas-cli
else
  echo "⚠️  Skipping eas-cli — install mise + node first, then re-run."
fi

echo
echo "Done. Open a new terminal to load the new shell config."
