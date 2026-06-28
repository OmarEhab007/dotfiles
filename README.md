# dotfiles

My personal configuration files for **macOS** and **Red Hat / Fedora (dnf)**.

## Contents

| Path | What |
|------|------|
| `home/.zshrc` `.zshenv` `.zprofile` | zsh shell config |
| `config/tmux/` | tmux (uses [oh-my-tmux](https://github.com/gpakosz/.tmux); my overrides in `tmux.conf.local`) |
| `config/nvim/` | Neovim config (Lua) |
| `config/starship.toml` | Starship prompt |
| `config/ghostty/` `config/kitty/` | terminal emulators |
| `config/karabiner/` | keyboard remapping |
| `config/fish/` `config/htop/` `config/neofetch/` `config/zed/` | misc tools |

## Install

```bash
git clone https://github.com/OmarEhab007/dotfiles ~/dotfiles
cd ~/dotfiles
./bootstrap.sh   # installs tools (brew on macOS, dnf on Fedora/RHEL) + oh-my-zsh + oh-my-tmux, then symlinks
```

Already have the tools? Just symlink:

```bash
./install.sh
```

`install.sh` symlinks each file into place and backs up anything it would
overwrite to `~/.dotfiles-backup/<timestamp>/`.

### Red Hat / Fedora notes

`bootstrap.sh` installs via `dnf` (enabling the `atim/starship` and `atim/eza`
COPR repos for those two). A few packages differ by name on Fedora:

- `fd` is installed as `fd-find` (binary `fdfind`)
- `bat` may install as `batcat`

The configs guard these with `command -v`, so missing tools degrade gracefully.
`karabiner` is macOS-only — its symlink on Linux is harmless (nothing reads it).

### tmux

### Fonts

The terminal configs use Nerd Fonts for icons: **VictorMono Nerd Font** (kitty)
and **Lilex Nerd Font** (ghostty). `bootstrap.sh` installs both — via brew casks
on macOS, and from the [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
release zips into `~/.local/share/fonts` on Linux. After install, select the font
in your terminal's preferences if it isn't picked up automatically.

### tmux

`bootstrap.sh` installs oh-my-tmux automatically. To do it by hand:

```bash
git clone https://github.com/gpakosz/.tmux.git ~/.local/share/tmux/oh-my-tmux
ln -s ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
```

## Secrets

No credentials live in this repo. zsh sources machine-local secrets from
`~/.zsh_secrets` (gitignored, not included). Create it yourself for any
API keys or tokens.
