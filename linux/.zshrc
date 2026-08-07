# ============================================================================
# ~/.zshrc — Linux dev box (sgup-dev)
# Ported from sgup/new-mac-setup. Same structure and keybindings; only the
# macOS-specific paths differ. Divergences are marked LINUX.
# ============================================================================

# --- Editor ------------------------------------------------------------------
# LINUX: no Zed on a headless box.
export EDITOR="nvim"
export VISUAL="nvim"
alias code="nvim"

# --- Powerlevel10k instant prompt (must stay near top) -----------------------
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

# --- Completions (must run before plugins that register completions) ---------
autoload -Uz compinit && compinit -C

# --- Plugins (autosuggestions → syntax-highlighting → history-substring) -----
# LINUX: apt ships these under /usr/share; history-substring-search has no
# Ubuntu package, so it is cloned to ~/.zsh.
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up      # ↑
bindkey '^[[B' history-substring-search-down    # ↓
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- Theme -------------------------------------------------------------------
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- PATH --------------------------------------------------------------------
# LINUX: ~/.local/bin carries claude, mise, zoxide, and the fd/bat shims.
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.atuin/bin:$PATH"

# LINUX: pnpm lives under XDG, not ~/Library.
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- Languages (mise — replaces nvm + pyenv) ---------------------------------
command -v mise >/dev/null && eval "$(mise activate zsh)"

# --- Tools -------------------------------------------------------------------
# NOTE: zoxide is deliberately NOT initialised here — it must come last, after
# atuin and fzf. See the block at the bottom of this file.

# fzf — Ctrl+T fuzzy file picker, Alt+C fuzzy cd. (Ctrl+R is owned by atuin.)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {} | head -200'"
# LINUX: Debian ships fzf's shell bindings here rather than ~/.fzf.zsh.
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# atuin — fuzzy SQLite-backed shell history (replaces Ctrl+R).
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# --- Aliases -----------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias l="eza -l --git --icons"
  alias ll="eza -la --git --icons"
  alias lt="eza --tree --level=2 --icons"
else
  alias l="ls -l"
fi

# --- Functions ---------------------------------------------------------------
mkcd() { mkdir -p "$1" && cd "$1"; }

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

ghpr() { gh pr view --web 2>/dev/null || gh pr create --web; }

alias cc="claude"

# Silence zoxide's doctor warning. It misfires inside non-interactive shells
# (e.g. Claude Code's shell snapshots) that replay the `cd` wrapper but don't
# re-register __zoxide_hook into chpwd_functions. Tracking still works.
export _ZO_DOCTOR=0

# --- zoxide (must be LAST) ---------------------------------------------------
# zoxide's chpwd hook needs to be registered after atuin/fzf/etc., otherwise
# they wrap precmd/chpwd after zoxide and zoxide warns about it on startup.
# Replaces `cd` with frecency-ranked smart cd. Original: `\cd` or `builtin cd`.
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
alias z=cd
alias zi='cd -i'
