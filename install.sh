#!/usr/bin/env bash
# Symlink dotfiles into place. Existing files are backed up to ~/.dotfiles-backup/<timestamp>.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok    $dest"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP/$(dirname "${dest#$HOME/}")"
    mv "$dest" "$BACKUP/${dest#$HOME/}"
    echo "backup $dest -> $BACKUP/${dest#$HOME/}"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "link  $dest -> $src"
}

# home/* -> ~/*   (dotfiles already named with the leading dot)
for f in "$DOTFILES"/home/.*; do
  base="$(basename "$f")"
  { [ "$base" = "." ] || [ "$base" = ".." ]; } && continue
  link "$f" "$HOME/$base"
done

# config/* -> ~/.config/*
for f in "$DOTFILES"/config/*; do
  link "$f" "$HOME/.config/$(basename "$f")"
done

echo
echo "Done. Backups (if any) in $BACKUP"
echo "Note: tmux uses oh-my-tmux. Install it for ~/.config/tmux/tmux.conf to resolve:"
echo "  git clone https://github.com/gpakosz/.tmux.git ~/.local/share/tmux/oh-my-tmux"
echo "  ln -s ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf"
