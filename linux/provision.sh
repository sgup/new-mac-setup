#!/usr/bin/env bash
# Provision a fresh Ubuntu box with the same shell experience as the Mac.
# Installs what the Brewfile provides on macOS, then hands off to ../install.sh
# for the symlinks. Idempotent — safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/sgup/new-mac-setup/main/linux/provision.sh | bash
#   # or, from a clone:  ./linux/provision.sh
#
# Skipped deliberately (no Xcode on Linux, so they can do nothing): cocoapods,
# watchman, xcodegen, ruby, eas-cli, and every cask / mas entry.
set -uo pipefail

echo "### apt packages"
sudo apt-get update -qq
PKGS=(zsh zsh-autosuggestions zsh-syntax-highlighting
      bat fd-find eza fzf ripgrep jq direnv httpie neovim tree wget git-lfs
      git-delta unzip)
MISSING=()
for p in "${PKGS[@]}"; do
  sudo apt-get install -y -qq "$p" >/dev/null 2>&1 || MISSING+=("$p")
done
[ ${#MISSING[@]} -gt 0 ] && echo "  apt could not install: ${MISSING[*]}" || echo "  all apt packages installed"

# zsh-history-substring-search has no Ubuntu package.
echo "### zsh-history-substring-search (no apt package)"
[ -d ~/.zsh/zsh-history-substring-search ] || {
  mkdir -p ~/.zsh
  git clone --depth=1 -q https://github.com/zsh-users/zsh-history-substring-search \
    ~/.zsh/zsh-history-substring-search
}
echo "  $([ -d ~/.zsh/zsh-history-substring-search ] && echo present || echo FAILED)"

# Debian renames these binaries; linux/.zshrc calls them by their upstream names
# (fzf previews use `bat`, FZF_DEFAULT_COMMAND uses `fd`).
echo "### binary-name shims"
mkdir -p ~/.local/bin
command -v fdfind >/dev/null && ln -sf "$(command -v fdfind)" ~/.local/bin/fd
command -v batcat >/dev/null && ln -sf "$(command -v batcat)" ~/.local/bin/bat
echo "  fd  -> $(readlink -f ~/.local/bin/fd  2>/dev/null || echo MISSING)"
echo "  bat -> $(readlink -f ~/.local/bin/bat 2>/dev/null || echo MISSING)"

echo "### powerlevel10k"
[ -d ~/powerlevel10k ] || git clone --depth=1 -q https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo "  $([ -d ~/powerlevel10k ] && echo present || echo FAILED)"

echo "### mise, atuin, zoxide, pnpm (not packaged, upstream installers)"
command -v mise   >/dev/null || curl -fsSL https://mise.run | sh >/dev/null 2>&1
command -v atuin  >/dev/null || curl -fsSL https://setup.atuin.sh | bash >/dev/null 2>&1
command -v zoxide >/dev/null || curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh >/dev/null 2>&1
[ -x "$HOME/.local/share/pnpm/pnpm" ] || curl -fsSL https://get.pnpm.io/install.sh | SHELL=bash sh - >/dev/null 2>&1
for t in mise atuin zoxide; do
  printf "  %-7s %s\n" "$t" "$(PATH="$HOME/.local/bin:$HOME/.atuin/bin:$PATH" command -v $t || echo MISSING)"
done

echo "### dotfiles"
if [ -d ~/.dotfiles/.git ]; then
  git -C ~/.dotfiles pull -q --ff-only 2>/dev/null || echo "  (pull skipped — local changes)"
else
  git clone -q https://github.com/sgup/new-mac-setup.git ~/.dotfiles
fi
echo "  $(git -C ~/.dotfiles log --oneline -1 2>&1 | head -1)"

echo "### symlinks (delegated to install.sh)"
~/.dotfiles/install.sh

# PATH must be in .zshenv, not only .zshrc: .zshrc is skipped for
# non-interactive shells, so `ssh <host> claude ...` would not find ~/.local/bin.
echo "### ~/.zshenv (PATH for non-interactive shells)"
cat > ~/.zshenv <<'EOF'
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$HOME/.local/share/pnpm:$PATH"
EOF
echo "  written"

echo "### default shell"
[ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ] || sudo chsh -s /usr/bin/zsh "$USER"
echo "  $(getent passwd "$USER" | cut -d: -f7)"

echo
echo "Done. Log out and back in for zsh to take effect."
echo "Then: claude auth login && gh auth login"
