#!/usr/bin/env bash
# Install the tools these dotfiles use, then symlink everything.
# Supports macOS (Homebrew) and Red Hat / Fedora (dnf).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_macos() {
  command -v brew >/dev/null 2>&1 || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  brew install \
    zsh tmux neovim starship fish htop fastfetch \
    fzf fd ripgrep bat eza zoxide atuin btop dust git-delta git kitty
}

install_dnf() {
  sudo dnf install -y dnf-plugins-core || true
  # COPR repos for tools not always in the base Fedora repos
  sudo dnf copr enable -y atim/starship || true
  sudo dnf copr enable -y atim/eza || true
  # Install one at a time so a single missing package doesn't abort the rest.
  for pkg in \
    zsh tmux neovim fish htop fastfetch \
    fzf fd-find ripgrep bat eza zoxide atuin btop git git-delta kitty starship; do
    sudo dnf install -y "$pkg" || echo "skip: $pkg not available via dnf"
  done
  echo "Note on Fedora: 'fd' may be /usr/bin/fdfind and 'bat' may be /usr/bin/batcat."
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
