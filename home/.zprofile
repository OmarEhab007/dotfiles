export PATH="$HOME/.local/bin:$PATH"

if [[ "$OSTYPE" == darwin* ]]; then
  # JetBrains Toolbox
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  # Homebrew
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Linux: pick up Linuxbrew if present (optional)
  [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
