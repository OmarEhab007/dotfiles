#!/usr/bin/env bash
# verify-nvim.sh — clean-startup + health gate for the LeerVim config.
# Usage: scripts/verify-nvim.sh [sample_file ...]
# Exit 0 = clean. Non-zero = a startup error or a removed-in-0.12 deprecation.
set -uo pipefail

NVIM="${NVIM:-nvim}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
RAW="$TMP/raw.txt"
DUMP="$TMP/dump.lua"
FAIL=0

cat > "$DUMP" <<'LUA'
vim.defer_fn(function()
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  vim.fn.writefile(vim.split(msgs, "\n"), vim.env.VERIFY_MSGS)
  vim.cmd("qa!")
end, tonumber(vim.env.VERIFY_WAIT_MS) or 9000)
LUA

export VERIFY_MSGS="$TMP/msgs.txt"
export VERIFY_WAIT_MS="${VERIFY_WAIT_MS:-9000}"

SAMPLE="${1:-/tmp/verify_sample.lua}"
[ -e "$SAMPLE" ] || printf 'local x = 1\nprint(x)\n' > "$SAMPLE"

# Run in a PTY so the TUI path (and red errors) are exercised, not headless.
script -q /dev/null "$NVIM" -c "source $DUMP" "$SAMPLE" < /dev/null > "$RAW" 2>&1 &
PID=$!
sleep "$(( VERIFY_WAIT_MS / 1000 + 4 ))"
kill "$PID" 2>/dev/null

CLEAN="$(tr -d '\000' < "$RAW" | perl -pe 's/\e\[[0-9;:?]*[a-zA-Z]//g; s/\e[()][AB0]//g; s/\r/\n/g')"

echo "=== :messages ==="
[ -f "$VERIFY_MSGS" ] && cat "$VERIFY_MSGS" || echo "(messages file not written — nvim killed before timer; rely on rendered output)"

echo "=== red errors / removed-0.12 deprecations (excl. pty DSR artifact) ==="
HITS="$(printf '%s\n' "$CLEAN" \
  | grep -aiE 'error in|stack traceback|attempt to index|nil value|E[0-9]{3,4}:' \
  | grep -aiv 'DSR response' | sort -u)"
if [ -n "$HITS" ]; then echo "$HITS"; FAIL=1; else echo "(none)"; fi

echo "=== checkhealth vim.deprecated: removed-in-0.12 only ==="
CHK="$TMP/chk.txt"
"$NVIM" --headless "$SAMPLE" -c 'checkhealth vim.deprecated' -c "w! $CHK" -c 'qa!' 2>/dev/null
REMOVED="$(grep -iE 'removed in Nvim 0\.1[12]|Feature was removed' "$CHK" 2>/dev/null | sort -u)"
if [ -n "$REMOVED" ]; then echo "$REMOVED"; FAIL=1; else echo "(no removed-in-0.12 APIs flagged)"; fi

if [ "$FAIL" -eq 0 ]; then echo "VERIFY: PASS"; else echo "VERIFY: FAIL"; fi
exit "$FAIL"
