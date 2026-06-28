#!/bin/sh
# Print the current git branch of the active tmux pane's directory.
# Output: " <branch>" (U+E0A0 powerline branch glyph) — empty if not a git repo.
# Called from tmux_conf_theme_status_right in tmux.conf.local.

dir=$(tmux display-message -p -F '#{pane_current_path}' 2>/dev/null) || exit 0
cd "$dir" 2>/dev/null || exit 0

branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) \
  || branch=$(git rev-parse --short HEAD 2>/dev/null) \
  || exit 0

[ -n "$branch" ] && printf '\356\202\240 %s' "$branch"
