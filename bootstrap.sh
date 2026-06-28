#!/usr/bin/env bash
# Install the tools these dotfiles use, then symlink everything.
# Supports macOS (Homebrew) and Red Hat / Fedora (dnf).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nerd Fonts referenced by the terminal configs (kitty: VictorMono, ghostty: Lilex)
NERD_FONTS=(VictorMono Lilex)
NERD_FONTS_VERSION="v3.4.0"

install_fonts_macos() {
  brew install --cask font-victor-mono-nerd-font font-lilex-nerd-font || \
    echo "skip: install Nerd Font casks manually if the above failed"
}

install_fonts_linux() {
  local dir="$HOME/.local/share/fonts"
  mkdir -p "$dir"
  for f in "${NERD_FONTS[@]}"; do
    if ls "$dir/${f}"*Nerd* >/dev/null 2>&1; then
      echo "ok: $f Nerd Font already present"; continue
    fi
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${f}.zip"
    echo "Installing $f Nerd Font..."
    curl -fL "$url" -o "/tmp/${f}.zip" && unzip -oq "/tmp/${f}.zip" -d "$dir/${f}NerdFont" \
      && rm -f "/tmp/${f}.zip" || echo "skip: could not fetch $f Nerd Font"
  done
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$dir" >/dev/null 2>&1 || true
}

install_macos() {
  command -v brew >/dev/null 2>&1 || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  brew install \
    zsh tmux neovim starship fish htop fastfetch \
    fzf fd ripgrep bat eza zoxide atuin btop dust git-delta git kitty
  install_fonts_macos
}

install_dnf() {
  sudo dnf install -y dnf-plugins-core || true
  # RHEL/CentOS/Rocky/Alma: most of these tools live in EPEL; COPR needs it too.
  # CRB (CodeReady Builder) provides build deps several EPEL packages need.
  if ! grep -qi fedora /etc/os-release; then
    local ver; ver="$(. /etc/os-release && echo "${VERSION_ID%%.*}")"
    sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${ver}.noarch.rpm" || true
    sudo dnf config-manager --set-enabled crb 2>/dev/null \
      || sudo dnf config-manager --set-enabled powertools 2>/dev/null || true
  fi
  # COPR repos for tools not in EPEL/base
  sudo dnf copr enable -y atim/starship || true
  sudo dnf copr enable -y atim/eza || true
  # Install one at a time so a single missing package doesn't abort the rest.
  for pkg in \
    zsh tmux neovim fish htop fastfetch \
    fzf fd-find ripgrep bat eza zoxide atuin btop git git-delta kitty starship \
    curl unzip fontconfig; do
    sudo dnf install -y "$pkg" || echo "skip: $pkg not available via dnf"
  done
  echo "Note on Fedora: 'fd' may be /usr/bin/fdfind and 'bat' may be /usr/bin/batcat."
  install_fonts_linux
}

case "$OSTYPE" in
  darwin*) install_macos ;;
  linux*)
    if command -v dnf >/dev/null 2>&1; then
      install_dnf
    else
      echo "Unsupported Linux (no dnf). Install the tools manually, then run ./install.sh" >&2
      exit 1
    fi
    ;;
  *) echo "Unsupported OS: $OSTYPE" >&2; exit 1 ;;
esac

# oh-my-zsh (configs source it)
[[ -d "$HOME/.oh-my-zsh" ]] || \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# oh-my-tmux (tmux.conf symlink target)
if [[ ! -e "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf" ]]; then
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.local/share/tmux/oh-my-tmux"
fi
mkdir -p "$HOME/.config/tmux"
ln -sf "$HOME/.local/share/tmux/oh-my-tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Symlink the dotfiles
"$DOTFILES/install.sh"

echo
echo "Bootstrap complete. Set zsh as your shell if needed:  chsh -s \"\$(command -v zsh)\""
