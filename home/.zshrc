# Fast interactive shell for Kitty + tmux + Neovim.

# -- PATH ---------------------------------------------------------------------

typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.opencode/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.lmstudio/bin"
  "$HOME/Development/flutter/bin"
  $path
)

# macOS: Homebrew + JetBrains Toolbox
if [[ "$OSTYPE" == darwin* ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  path=(
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/ruby/bin"
    "/opt/homebrew/opt/openjdk@21/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    $path
  )
fi
export PATH

[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# -- Defaults -----------------------------------------------------------------

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export BUN_INSTALL="$HOME/.bun"
[[ "$OSTYPE" == darwin* ]] && export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

# Secrets should live outside dotfiles, for example in ~/.zsh_secrets.
[[ -r "$HOME/.zsh_secrets" ]] && source "$HOME/.zsh_secrets"

# -- History ------------------------------------------------------------------

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt inc_append_history
setopt extended_history
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt correct
unsetopt beep

# -- Oh My Zsh ----------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
# Prompt is handled by Starship (initialized below), not an OMZ theme.
ZSH_THEME=""

zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 14

DISABLE_UNTRACKED_FILES_DIRTY="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  git
  fzf
  zsh-completions
  fzf-tab
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# -- Starship prompt ----------------------------------------------------------
# Replaces the old spaceship OMZ theme. Guarded so a missing binary
# never leaves the shell prompt-less.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Edit the current command line in Neovim with Ctrl-x Ctrl-e.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# -- Lazy language managers ---------------------------------------------------

export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unfunction nvm node npm npx yarn pnpm corepack pi codex 2>/dev/null || true
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm() { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm() { _load_nvm; npm "$@"; }
npx() { _load_nvm; npx "$@"; }
yarn() { _load_nvm; yarn "$@"; }
pnpm() { _load_nvm; pnpm "$@"; }
corepack() { _load_nvm; corepack "$@"; }
pi() { _load_nvm; pi "$@"; }
codex() { _load_nvm; codex "$@"; }

export SDKMAN_DIR="$HOME/.sdkman"

_load_sdkman() {
  unfunction sdk 2>/dev/null || true
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
}

sdk() { _load_sdkman; sdk "$@"; }

# Bun completion is cheap enough to keep eager.
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# -- FZF ----------------------------------------------------------------------

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

export FZF_DEFAULT_OPTS="
  --height=45%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='❯ '
  --pointer='❯'
  --marker='✚'
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=border:#6c7086
"

# fzf-tab: rich previews using eza/bat when available
if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
fi
if command -v bat >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview \
    '[[ -d $realpath ]] && eza -1 --color=always --icons=always $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'
fi
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':completion:*' menu no

# -- Aliases ------------------------------------------------------------------

alias vim="nvim"
alias vi="nvim"
alias c="clear"
alias reload-zsh="source ~/.zshrc"
alias zshconfig="$EDITOR ~/.zshrc"
alias kittyconfig="$EDITOR ~/.config/kitty/kitty.conf"
alias tmuxconfig="$EDITOR ~/.config/tmux/tmux.conf.local"

alias gs="git status --short --branch"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gds="git diff --staged"
alias lg="lazygit"

alias kreload="kitty @ load-config ~/.config/kitty/kitty.conf"
alias tls="tmux list-sessions"
alias ta="tmux attach -t"
alias tn="tmux new -s"

# Use modern listing tools when available.
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons=auto --group-directories-first"
  alias ll="eza -lah --icons=auto --group-directories-first"
  alias tree="eza --tree --icons=auto --group-directories-first"
else
  alias ll="ls -lah"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat --paging=never"
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"

# -- Project helpers ----------------------------------------------------------

mkcd() {
  mkdir -p "$1" && cd "$1"
}

dev() {
  cd "$HOME/Developer" || return
}

nvconfig() {
  cd "$HOME/.config/nvim" || return
}

sync-nvim-config() {
  local source_dir="$HOME/.config/nvim/"
  local repo_dir="$HOME/Developer/nvim-config/"

  if [[ ! -d "$source_dir" ]]; then
    echo "Missing source config: $source_dir" >&2
    return 1
  fi

  if [[ ! -d "$repo_dir/.git" ]]; then
    echo "Missing nvim-config git repo: $repo_dir" >&2
    return 1
  fi

  rsync -rltvc --delete --chmod=F644,D755 \
    --exclude='.git/' \
    --exclude='.gitignore' \
    --exclude='.DS_Store' \
    --exclude='nvim.log' \
    "$source_dir" "$repo_dir"

  cd "$repo_dir" || return
  git status
}

# -- Enhancements added by terminal-enhancement plan --------------------------

# eza variants (base ls/ll/tree aliases already defined above when eza exists)
if command -v eza >/dev/null 2>&1; then
  alias la="eza -a --icons=auto --group-directories-first"
  alias lt="eza --tree --level=2 --icons=auto --group-directories-first"
  alias lt3="eza --tree --level=3 --icons=auto --group-directories-first"
  alias lg-files="eza -lah --git --icons=auto --group-directories-first"
fi

# git-delta as the pager for diffs (only if installed)
if command -v delta >/dev/null 2>&1; then
  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.line-numbers true
  git config --global delta.side-by-side false
  git config --global delta.syntax-theme "Catppuccin Mocha"
  git config --global merge.conflictStyle "zdiff3"
fi

# System monitor
command -v btop >/dev/null 2>&1 && alias top="btop"

# Disk usage
command -v dust >/dev/null 2>&1 && alias du="dust"

# Safer file ops (opt-in interactive)
alias rmi="rm -i"
alias cpi="cp -i"
alias mvi="mv -i"

# Docker / Kubernetes shortcuts
if command -v docker >/dev/null 2>&1; then
  alias d="docker"
  alias dc="docker compose"
  alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
fi
if command -v kubectl >/dev/null 2>&1; then
  alias k="kubectl"
  alias kgp="kubectl get pods"
  alias kgs="kubectl get svc"
fi

# Quick edit of the new configs
alias starshipconfig="$EDITOR ~/.config/starship.toml"


# Added by Antigravity CLI installer
export PATH="/Users/omar/.local/bin:$PATH"
