# dotfiles

My personal configuration files for macOS.

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
./install.sh
```

`install.sh` symlinks each file into place and backs up anything it would
overwrite to `~/.dotfiles-backup/<timestamp>/`.

### tmux

tmux depends on oh-my-tmux. After install:

```bash
git clone https://github.com/gpakosz/.tmux.git ~/.local/share/tmux/oh-my-tmux
ln -s ~/.local/share/tmux/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
```

## Secrets

No credentials live in this repo. zsh sources machine-local secrets from
`~/.zsh_secrets` (gitignored, not included). Create it yourself for any
API keys or tokens.
