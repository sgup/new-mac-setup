# ============================================================================
# ~/.zshrc
# ============================================================================

# --- Editor ------------------------------------------------------------------
export EDITOR="zed --wait"
export VISUAL="zed --wait"
alias code="zed"

# --- Powerlevel10k instant prompt (must stay near top) -----------------------
# Anything that requires console input (password prompts, etc.) must go ABOVE.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- History -----------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY

# --- Shell options -----------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS EXTENDED_GLOB

# --- Terminal integrations ---------------------------------------------------
# Ghostty (also handles window titles via the `title` shell-integration feature,
# so no manual precmd hack is needed.)
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

# --- Completions (must run before plugins/tools that register completions) ---
autoload -Uz compinit && compinit -C   # -C skips daily security check (faster)

# --- Plugins (autosuggestions → syntax-highlighting → history-substring) -----
# Order matters: history-substring-search must come AFTER syntax-highlighting.
BREW_PREFIX="$(brew --prefix)"
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
# Type a partial command, hit ↑/↓ to walk through matching history.
bindkey '^[[A' history-substring-search-up      # ↑
bindkey '^[[B' history-substring-search-down    # ↓
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- Theme -------------------------------------------------------------------
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Languages (mise — replaces nvm + pyenv) ---------------------------------
# Manage node/python/etc per-project via .tool-versions or .mise.toml.
# Set globals: `mise use --global node@22 python@3.12`
eval "$(mise activate zsh)"

# --- Java / Android ----------------------------------------------------------
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"

# --- pnpm --------------------------------------------------------------------
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- Bun ---------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- Misc PATH ---------------------------------------------------------------
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# --- Turso -------------------------------------------------------------------
[ -f "$HOME/.turso/env" ] && . "$HOME/.turso/env"

# --- Entire CLI completion ---------------------------------------------------
command -v entire >/dev/null && source <(entire completion zsh)

# --- Tools -------------------------------------------------------------------
# zoxide replaces `cd` with frecency-ranked smart cd. Original: `\cd` or `builtin cd`.
eval "$(zoxide init zsh --cmd cd)"

# fzf — Ctrl+T fuzzy file picker, Alt+C fuzzy cd. (Ctrl+R is owned by atuin below.)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {} | head -200'"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# atuin — fuzzy SQLite-backed shell history (replaces Ctrl+R).
# Run `atuin import auto` once to import existing zsh history.
eval "$(atuin init zsh --disable-up-arrow)"

# --- Aliases -----------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias l="eza -l --git --icons"
  alias ll="eza -la --git --icons"
  alias lt="eza --tree --level=2 --icons"
else
  alias l="ls -l"
fi

alias geocode="bun run ~/Code/utils/geocode.ts"

# --- Functions ---------------------------------------------------------------
# mkdir + cd in one
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
  case "$1" in
    *.tar.gz|*.tgz)  tar -xzf "$1" ;;
    *.tar.bz2|*.tbz) tar -xjf "$1" ;;
    *.tar.xz)        tar -xJf "$1" ;;
    *.tar)           tar -xf  "$1" ;;
    *.zip)           unzip    "$1" ;;
    *.gz)            gunzip   "$1" ;;
    *) echo "Don't know how to extract $1" ;;
  esac
}

# Open the GitHub PR for the current branch (view, or create)
ghpr() { gh pr view --web 2>/dev/null || gh pr create --web; }
