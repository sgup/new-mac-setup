# Brewfile — curated essentials for a new Mac
# Install:  brew bundle install
# Refresh:  brew bundle dump --force   (will re-add anything currently installed)

# ============================================================================
# Shell + CLI essentials
# ============================================================================
brew "atuin"          # SQLite-backed shell history with fuzzy Ctrl+R
brew "bat"            # cat with syntax highlighting
brew "direnv"         # auto-load per-directory env vars
brew "eza"            # modern ls (icons, git status column)
brew "fd"             # modern find
brew "fzf"            # fuzzy finder (Ctrl+R, Ctrl+T, Alt+C)
brew "gh"             # GitHub CLI
brew "git-delta"      # syntax-highlighted git diffs
brew "git-lfs"        # large file storage
brew "glow"           # render markdown in the terminal
brew "httpie"         # human-friendly curl
brew "jq"             # JSON processor
brew "mas"            # Mac App Store CLI (powers the mas entries below)
brew "mise"           # node/python/etc version manager (replaces nvm + pyenv)
brew "neovim"         # editor
brew "ripgrep"        # fastest grep
brew "tlrc"           # tldr — community-maintained simplified man pages
brew "tree"           # directory tree
brew "wget"           # download utility
brew "zoxide"         # frecency-ranked smart cd

# Zsh plugins (sourced from $(brew --prefix)/share/...)
brew "zsh-autosuggestions"
brew "zsh-history-substring-search"
brew "zsh-syntax-highlighting"

# ============================================================================
# Mobile / React Native dev (Fitloop)
# ============================================================================
brew "cocoapods"      # iOS dependency manager
brew "ruby@3.3"       # required by cocoapods
brew "watchman"       # Metro file watcher
brew "xcodegen"       # generate Xcode projects from yaml

# ============================================================================
# Backend / cloud
# ============================================================================
brew "flyctl"         # Fly.io deploy CLI
brew "libpq"          # postgres client + tools (psql, pg_dump)

# ============================================================================
# Casks
# ============================================================================
cask "android-studio"      # Android SDK + emulator (needed for Expo Android builds)
cask "font-jetbrains-mono-nerd-font"
cask "ngrok"               # local tunnel
cask "tailscale-app"       # mesh VPN
cask "zulu@17"             # JDK 17 for Android builds

# Daily-use apps
cask "1password"           # password manager
cask "docker"              # container runtime
cask "figma"               # design
cask "ghostty"             # terminal (config in ghostty/config)
cask "google-chrome"       # backup browser, web dev testing
cask "helium-browser"      # primary browser — Chromium, privacy-focused
cask "mimestream"          # native macOS Gmail client
cask "signal"              # encrypted messaging
cask "spotify"             # music
cask "tableplus"           # Postgres / SQLite GUI
cask "zed"                 # editor (used by EDITOR/VISUAL in .zshrc)
cask "zoom"                # video calls
cask "whatsapp"            # messaging
cask "discord"             # chat

# AI desktop apps
cask "chatgpt"
cask "claude"
cask "ollama"              # local LLMs

# Media + utilities
cask "backblaze"           # off-site backup (requires subscription to activate)
cask "iina"                # video player
cask "appcleaner"          # clean uninstall
cask "caffeine"            # prevent sleep (handy during long builds)
cask "mac-mouse-fix"       # smooth scrolling + button remaps
cask "monitorcontrol"      # brightness/volume for external displays

# ============================================================================
# Mac App Store
# ============================================================================
# Productivity
mas "Things", id: 904280696
mas "Bear", id: 1091189122
mas "DaisyDisk", id: 411643860
mas "Wipr", id: 1662217862
mas "Dark Reader for Safari", id: 1438243180
mas "Perplexity", id: 6714467650

# Apple iWork / iLife (free with Apple ID)
mas "Keynote", id: 361285480
mas "Numbers", id: 361304891
mas "Pages", id: 361309726
mas "iMovie", id: 408981434
mas "GarageBand", id: 682658836

# Pro creative
mas "Final Cut Pro", id: 424389933

# Dev
mas "Xcode", id: 497799835
