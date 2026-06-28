# LeerVim → Full-Stack IDE Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the LeerVim Neovim config into a modern full-stack IDE for JS/TS, Next.js, Go, and Java/Spring Boot, with debugging, test runners, code actions, and surrounding tooling — added as a strictly additive overlay, phased, with a verification gate after each phase.

**Architecture:** Each stack/tool is a new self-contained file under `lua/plugins/languages/` or `lua/plugins/tooling/`, or a surgical append to an existing config table. No LeerVim internals are rewritten. A `scripts/verify-nvim.sh` gate must pass after every phase; `lazy-lock.json` is committed per phase for instant rollback.

**Tech Stack:** Neovim 0.12.2, lazy.nvim, mason.nvim, mason-lspconfig, blink.cmp, conform.nvim, nvim-lint, nvim-dap, neotest. New: vtsls, nvim-vtsls, ts-error-translator, gopls, ray-x/go.nvim, nvim-dap-go, neotest-golang, nvim-jdtls, spring-boot.nvim, neotest-java, vim-dadbod(+ui+completion), kulala.nvim, overseer.nvim, docker/k8s LSPs, monorepo.nvim, codecompanion.nvim.

**Spec deviation flagged for confirmation:** Spec §3 says "swap `ts_ls`→`vtsls`". Reality: `lua/config/lsp/setup.lua` `["ts_ls"]` handler calls `require("typescript-tools").setup()`. So Phase 2 migrates **typescript-tools.nvim → vtsls** and updates `which-key/setup.lua:attach_typescript`. Net effect matches spec intent (VS Code-grade TS) and is still low-risk; Task 2.0 documents the typescript-tools config as fallback.

**Conventions every task follows:**
- LeerVim global is `LeerVim` (not `EcoVim`). `vim.fn.stdpath("data")` = `~/.local/share/nvim`. Mason packages dir = `vim.fn.stdpath("data") .. "/mason/packages"`.
- New plugins are pinned: every lazy spec includes `commit = "<sha>"` or `version = "<tag>"`. Resolve the current default-branch SHA at implementation time with the command given in each task and paste it in.
- Commit messages end with the Co-Authored-By trailer used in this repo's history.

---

## Phase 0 — Preconditions (run once, before Phase 1)

### Task 0.1: Confirm clean baseline

**Files:** none (verification only)

- [ ] **Step 1: Confirm git repo is clean**

Run: `cd ~/.config/nvim && git status --porcelain && git log --oneline -1`
Expected: empty porcelain output; HEAD is the `Baseline:` commit (`55faa1b` or later).

- [ ] **Step 2: Confirm toolchains**

Run: `node -v; go version; java -version 2>&1 | head -1; mvn -v | head -1`
Expected: node v22.x, go1.26.x, openjdk 21.x, Apache Maven 3.9.x. If any missing, STOP and report.

- [ ] **Step 3: Confirm Neovim version**

Run: `nvim --version | head -1`
Expected: `NVIM v0.12.x`. ray-x/go.nvim master and nvim-jdtls require ≥0.12.

---

## Phase 1 — Stability guardrails (verify gate + pin discipline)

This phase ships the test harness used to gate every later phase.

### Task 1.1: Create the verification gate script

**Files:**
- Create: `scripts/verify-nvim.sh`

- [ ] **Step 1: Write the script**

Create `~/.config/nvim/scripts/verify-nvim.sh`:

```bash
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
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x ~/.config/nvim/scripts/verify-nvim.sh`
Expected: no output, exit 0.

- [ ] **Step 3: Run it against the current (known-good) config — this is the baseline assertion**

Run: `cd ~/.config/nvim && scripts/verify-nvim.sh`
Expected: ends with `VERIFY: PASS` (exit 0). The current config was already verified clean in prior work, so this proves the gate itself is correct. If it FAILs on the untouched config, the gate is wrong — fix the script, do not proceed.

- [ ] **Step 4: Commit**

```bash
cd ~/.config/nvim
git add scripts/verify-nvim.sh
git commit -m "$(printf 'chore: add verify-nvim.sh clean-startup gate\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 1.2: Add the tooling import + pin-helper note

**Files:**
- Modify: `lua/plugins/init.lua:3-6` (add `plugins.tooling` import)
- Create: `lua/plugins/tooling/.keep` (so the import target exists before Phase 5)

- [ ] **Step 1: Add the tooling subdir import**

In `lua/plugins/init.lua`, the current block is:

```lua
  {
    { import = "plugins.ai" },
    { import = "plugins.languages" },
  },
```

Replace it with:

```lua
  {
    { import = "plugins.ai" },
    { import = "plugins.languages" },
    { import = "plugins.tooling" },
  },
```

- [ ] **Step 2: Create the directory so lazy's import does not error**

Run: `mkdir -p ~/.config/nvim/lua/plugins/tooling && printf 'return {}\n' > ~/.config/nvim/lua/plugins/tooling/_placeholder.lua`

(A `_placeholder.lua` returning `{}` is a valid empty lazy spec; it is deleted in Phase 5 Task 5.0 once real specs exist.)

- [ ] **Step 3: Verify gate**

Run: `cd ~/.config/nvim && scripts/verify-nvim.sh`
Expected: `VERIFY: PASS`. Confirms the empty tooling import does not break startup.

- [ ] **Step 4: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/init.lua lua/plugins/tooling/_placeholder.lua
git commit -m "$(printf 'chore: wire plugins.tooling import (empty placeholder)\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 1.3: Pin the lockfile snapshot

**Files:**
- Modify: `lazy-lock.json` (committed as the Phase-1 rollback point)

- [ ] **Step 1: Commit the current lockfile as the guardrail baseline**

```bash
cd ~/.config/nvim
git add lazy-lock.json
git commit -m "$(printf 'chore: snapshot lazy-lock.json as phase-1 rollback baseline\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')" || echo "lazy-lock.json already clean — ok"
```

**PHASE 1 GATE:** `scripts/verify-nvim.sh` → `VERIFY: PASS`. User confirms before Phase 2.

---

## Phase 2 — JS/TS/Next.js (typescript-tools → vtsls)

### Task 2.0: Document the typescript-tools fallback

**Files:**
- Create: `lua/config/lsp/servers/_tsserver-typescript-tools.bak.lua`

- [ ] **Step 1: Preserve the current typescript-tools settings as a documented fallback**

Run:
```bash
cp ~/.config/nvim/lua/config/lsp/servers/tsserver.lua \
   ~/.config/nvim/lua/config/lsp/servers/_tsserver-typescript-tools.bak.lua
```

- [ ] **Step 2: Add a header comment to the backup**

Prepend this line as the first line of `lua/config/lsp/servers/_tsserver-typescript-tools.bak.lua`:

```lua
-- FALLBACK: original typescript-tools.nvim settings. To revert vtsls: restore the
-- ["ts_ls"] handler in lua/config/lsp/setup.lua to require("typescript-tools").setup{}
-- with require("config.lsp.servers.tsserver"), and re-add the typescript-tools plugin.
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/config/lsp/servers/_tsserver-typescript-tools.bak.lua
git commit -m "$(printf 'chore: snapshot typescript-tools settings as vtsls fallback\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 2.1: Add vtsls + nvim-vtsls + ts-error-translator plugins

**Files:**
- Modify: `lua/plugins/languages/typescript.lua`

- [ ] **Step 1: Resolve pin SHAs**

Run:
```bash
git ls-remote https://github.com/yioneko/nvim-vtsls HEAD
git ls-remote https://github.com/dmmulroy/ts-error-translator.nvim HEAD
```
Record both 40-char SHAs; use them as `commit = "..."` below.

- [ ] **Step 2: Append the plugin specs**

Read `lua/plugins/languages/typescript.lua` first to find the returned spec table. Append these entries to that returned table (keep existing entries — e.g. package-info — intact):

```lua
  {
    "yioneko/nvim-vtsls",
    commit = "<NVIM_VTSLS_SHA>",
    lazy = true,
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  },
  {
    "dmmulroy/ts-error-translator.nvim",
    commit = "<TS_ERROR_TRANSLATOR_SHA>",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },
```

- [ ] **Step 3: Remove the typescript-tools plugin spec (it is being replaced)**

In the same file (or wherever it is declared — grep first: `grep -rn "typescript-tools" ~/.config/nvim/lua`), delete the lazy spec entry for `"pmizio/typescript-tools.nvim"`. Do not delete `tsserver.lua` (kept via the `.bak` copy from Task 2.0 and replaced in Task 2.3).

- [ ] **Step 4: Sync plugins**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3`
Expected: clones `nvim-vtsls`, `ts-error-translator.nvim`; removes `typescript-tools.nvim`. No error lines.

### Task 2.2: Add vtsls to Mason + create the vtsls server settings

**Files:**
- Modify: `lua/config/lsp/setup.lua:49-59` (ensure_installed list)
- Create: `lua/config/lsp/servers/vtsls.lua`

- [ ] **Step 1: Add vtsls to ensure_installed**

In `lua/config/lsp/setup.lua` the `ensure_installed` list (currently ending `"tailwindcss",`) — add `"vtsls",`:

```lua
  ensure_installed = {
    "bashls",
    "cssls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "prismals",
    "tailwindcss",
    "vtsls",
  },
```

- [ ] **Step 2: Create the vtsls settings module**

Create `lua/config/lsp/servers/vtsls.lua`:

```lua
local M = {}

-- Monorepo root: anchor at the workspace marker so each Turborepo package
-- gets its own tsserver instance instead of one giant root.
M.root_dir = function(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local markers = { "turbo.json", "pnpm-workspace.yaml", "nx.json", "lerna.json" }
  local found = vim.fs.find(markers, { upward = true, path = vim.fs.dirname(fname) })[1]
  local root = found and vim.fs.dirname(found)
    or vim.fs.root(bufnr, { "package.json", ".git" })
  on_dir(root)
end

local inlay = {
  enumMemberValues = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  variableTypes = { enabled = false },
}

M.settings = {
  complete_function_calls = true,
  vtsls = {
    enableMoveToFileCodeAction = true,
    autoUseWorkspaceTsdk = true,
    experimental = {
      maxInlayHintLength = 30,
      completion = { enableServerSideFuzzyMatch = true },
    },
  },
  typescript = {
    updateImportsOnFileMove = { enabled = "always" },
    suggest = { completeFunctionCalls = true },
    inlayHints = inlay,
    preferences = { importModuleSpecifier = "non-relative" },
  },
  javascript = {
    updateImportsOnFileMove = { enabled = "always" },
    inlayHints = inlay,
  },
}

M.on_attach = function(client, bufnr)
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  require("plugins.which-key.setup").attach_typescript(bufnr)
end

return M
```

### Task 2.3: Swap the LSP handler from typescript-tools to vtsls

**Files:**
- Modify: `lua/config/lsp/setup.lua:73-80` (the `["ts_ls"]` handler)

- [ ] **Step 1: Replace the handler**

In `lua/config/lsp/setup.lua` replace this exact block:

```lua
    ["ts_ls"] = function()
      require("typescript-tools").setup({
        capabilities = capabilities or vim.lsp.protocol.make_client_capabilities(),
        handlers = require("config.lsp.servers.tsserver").handlers,
        on_attach = require("config.lsp.servers.tsserver").on_attach,
        settings = require("config.lsp.servers.tsserver").settings,
      })
    end,
```

with:

```lua
    ["vtsls"] = function()
      local vt = require("config.lsp.servers.vtsls")
      lspconfig.vtsls.setup({
        capabilities = capabilities,
        handlers = handlers,
        on_attach = vt.on_attach,
        settings = vt.settings,
        root_dir = vt.root_dir,
      })
    end,
```

(Note: `mason-lspconfig` keys handlers by server name; the key must be `vtsls`, and `vtsls` must be in `ensure_installed` from Task 2.2.)

### Task 2.4: Repoint the TypeScript which-key keymaps to vtsls

**Files:**
- Modify: `lua/plugins/which-key/setup.lua:153` (function `attach_typescript`)

- [ ] **Step 1: Inspect the current function**

Run: `sed -n '153,215p' ~/.config/nvim/lua/plugins/which-key/setup.lua`
Identify every command that calls a `typescript-tools` feature (e.g. `TSToolsOrganizeImports`, `TSToolsAddMissingImports`, `TSToolsRemoveUnusedImports`, `TSToolsFixAll`, `TSToolsGoToSourceDefinition`, `TSToolsRenameFile`, `TSToolsFileReferences`).

- [ ] **Step 2: Replace typescript-tools commands with nvim-vtsls equivalents**

Map each command (keep the same `<leader>` keybindings and which-key labels — only swap the right-hand action):

| typescript-tools | nvim-vtsls replacement |
|---|---|
| `:TSToolsOrganizeImports` | `require('vtsls').commands.organize_imports` |
| `:TSToolsSortImports` | `require('vtsls').commands.sort_imports` |
| `:TSToolsRemoveUnusedImports` | `require('vtsls').commands.remove_unused_imports` |
| `:TSToolsAddMissingImports` | `require('vtsls').commands.add_missing_imports` |
| `:TSToolsFixAll` | `require('vtsls').commands.fix_all` |
| `:TSToolsGoToSourceDefinition` | `require('vtsls').commands.goto_source_definition` |
| `:TSToolsFileReferences` | `require('vtsls').commands.file_references` |
| `:TSToolsRenameFile` | `require('vtsls').commands.rename_file` |

Each `nvim-vtsls` command is a Lua function; bind as e.g. `function() require('vtsls').commands.organize_imports() end`. Preserve any keys with no vtsls equivalent by leaving them mapped to the generic LSP code action (`vim.lsp.buf.code_action`).

- [ ] **Step 3: Verify gate (must attach vtsls on a real TS file)**

Run:
```bash
cd ~/.config/nvim
printf 'export const x: number = 1\nconsole.log(x)\n' > /tmp/verify_sample.ts
VERIFY_WAIT_MS=14000 scripts/verify-nvim.sh /tmp/verify_sample.ts
```
Expected: `VERIFY: PASS`. Then manually confirm attach:
```bash
nvim --headless /tmp/verify_sample.ts -c 'lua vim.defer_fn(function() local c=vim.lsp.get_clients({bufnr=0}); local n={}; for _,x in ipairs(c) do n[#n+1]=x.name end; print("clients="..table.concat(n,",")); vim.cmd("qa!") end, 8000)' 2>&1 | grep clients
```
Expected: `clients=` contains `vtsls` (and possibly `eslint`). Must NOT contain `typescript-tools`.

- [ ] **Step 4: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/languages/typescript.lua lua/config/lsp/setup.lua \
        lua/config/lsp/servers/vtsls.lua lua/plugins/which-key/setup.lua lazy-lock.json
git commit -m "$(printf 'feat(ts): migrate typescript-tools -> vtsls + nvim-vtsls + ts-error-translator\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 2.5: Next.js DAP (attach config) + Vitest neotest adapter

**Files:**
- Modify: `lua/plugins/dap.lua` (configurations.pwa-node already exists ~line 176; add a Next.js attach + compound)
- Modify: `lua/plugins/testing.lua` (add neotest-vitest adapter)

- [ ] **Step 1: Inspect existing DAP JS config**

Run: `sed -n '145,210p' ~/.config/nvim/lua/plugins/dap.lua`
Confirm `dap.adapters["pwa-node"]` and `dap.adapters["pwa-chrome"]` exist (they do) and find where `dap.configurations` for js/ts is set.

- [ ] **Step 2: Add Next.js server attach + compound configs**

After the existing `dap.configurations[ext]` assignment block, add (inside the same `config = function()`):

```lua
      local js_fts = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
      for _, ft in ipairs(js_fts) do
        dap.configurations[ft] = dap.configurations[ft] or {}
        table.insert(dap.configurations[ft], {
          type = "pwa-node",
          request = "attach",
          name = "Next.js: attach to dev server (node --inspect)",
          port = 9229,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          resolveSourceMapLocations = {
            "${workspaceFolder}/**",
            "!**/node_modules/**",
            "${workspaceFolder}/.next/**",
          },
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        })
        table.insert(dap.configurations[ft], {
          type = "pwa-node",
          request = "launch",
          name = "Next.js: launch dev server",
          runtimeExecutable = "npm",
          runtimeArgs = { "run", "dev" },
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          sourceMaps = true,
        })
      end
```

(Run Next.js with `NODE_OPTIONS='--inspect' npm run dev` to use the attach config; the existing `pwa-chrome` config covers browser-side breakpoints.)

- [ ] **Step 3: Add neotest-vitest**

Resolve pin: `git ls-remote https://github.com/marilari88/neotest-vitest HEAD`.
In `lua/plugins/testing.lua`, find the neotest spec's `dependencies` (currently includes `nvim-neotest/neotest-jest`). Add `"marilari88/neotest-vitest",` to that dependencies list, and in the `require('neotest').setup{ adapters = { ... } }` table add alongside the existing jest adapter:

```lua
        require("neotest-vitest"),
```

Add the pinned spec to the dependencies array form if the file uses pinned specs; otherwise add a standalone pinned spec:

```lua
  { "marilari88/neotest-vitest", commit = "<NEOTEST_VITEST_SHA>" },
```

- [ ] **Step 4: Verify gate**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2 && scripts/verify-nvim.sh /tmp/verify_sample.ts`
Expected: sync clean; `VERIFY: PASS`.

- [ ] **Step 5: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/dap.lua lua/plugins/testing.lua lazy-lock.json
git commit -m "$(printf 'feat(ts): Next.js DAP attach/launch + neotest-vitest adapter\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

**PHASE 2 GATE:** `scripts/verify-nvim.sh /tmp/verify_sample.ts` → PASS; `vtsls` attaches; typescript-tools gone. User confirms before Phase 3.

---

## Phase 3 — Go

### Task 3.1: gopls server settings (native vim.lsp.config — additive, does not touch setup.lua)

**Files:**
- Create: `lua/config/lsp/servers/gopls.lua`

- [ ] **Step 1: Create the gopls settings module**

Create `lua/config/lsp/servers/gopls.lua`:

```lua
local M = {}

M.settings = {
  gopls = {
    gofumpt = true,
    staticcheck = true,
    semanticTokens = true,
    usePlaceholders = true,
    completeUnimported = true,
    vulncheck = "Imports",
    directoryFilters = { "-**/node_modules", "-**/.git", "-**/vendor" },
    analyses = {
      unusedparams = true,
      unusedwrite = true,
      nilness = true,
      shadow = true,
      useany = true,
    },
    hints = {
      assignVariableTypes = true,
      compositeLiteralFields = true,
      compositeLiteralTypes = true,
      constantValues = true,
      functionTypeParameters = true,
      parameterNames = true,
      rangeVariableTypes = true,
    },
    codelenses = {
      generate = true,
      test = true,
      tidy = true,
      upgrade_dependency = true,
      vendor = true,
      run_govulncheck = true,
      regenerate_cgo = true,
    },
  },
}

return M
```

### Task 3.2: Go plugin file (gopls enable + go.nvim + dap-go + neotest-golang)

**Files:**
- Create: `lua/plugins/languages/go.lua`

- [ ] **Step 1: Resolve pins**

Run:
```bash
git ls-remote https://github.com/ray-x/go.nvim HEAD
git ls-remote https://github.com/ray-x/guihua.lua HEAD
git ls-remote https://github.com/leoluz/nvim-dap-go HEAD
git ls-remote https://github.com/fredrikaverpil/neotest-golang HEAD
```
Record SHAs.

- [ ] **Step 2: Create `lua/plugins/languages/go.lua`**

```lua
return {
  -- gopls via native 0.12 LSP API (additive; does not touch mason-lspconfig setup.lua)
  {
    "neovim/nvim-lspconfig",
    ft = { "go", "gomod", "gowork", "gotmpl" },
    config = function()
      local caps = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("gopls", {
        cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls" },
        capabilities = caps,
        settings = require("config.lsp.servers.gopls").settings,
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local work = vim.fs.find({ "go.work" }, { upward = true, path = vim.fs.dirname(fname) })[1]
          on_dir(work and vim.fs.dirname(work)
            or vim.fs.root(bufnr, { "go.mod", ".git" }))
        end,
        on_attach = function(_, bufnr)
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end,
      })
      vim.lsp.enable("gopls")
    end,
  },

  {
    "ray-x/go.nvim",
    branch = "master",
    commit = "<GO_NVIM_SHA>",
    dependencies = {
      { "ray-x/guihua.lua", commit = "<GUIHUA_SHA>", build = "cd lua/fzy && make" },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,          -- we configure gopls ourselves above
      lsp_inlay_hints = { enable = false }, -- handled by on_attach
      dap_debug = true,
      dap_debug_keymap = false, -- avoid clobbering LeerVim keymaps
      trouble = false,
      luasnip = false,
    },
  },

  {
    "leoluz/nvim-dap-go",
    commit = "<NVIM_DAP_GO_SHA>",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-go").setup({
        delve = { detached = vim.fn.has("win32") == 0 },
      })
    end,
  },

  {
    "fredrikaverpil/neotest-golang",
    commit = "<NEOTEST_GOLANG_SHA>",
    ft = "go",
    dependencies = { "nvim-neotest/neotest", "leoluz/nvim-dap-go" },
  },
}
```

- [ ] **Step 3: Register neotest-golang adapter**

In `lua/plugins/testing.lua`, in the `require('neotest').setup{ adapters = { ... } }` table, add:

```lua
        require("neotest-golang")({
          runner = "gotestsum",
          dap_go_enabled = true,
        }),
```

### Task 3.3: Mason tools + conform + nvim-lint for Go

**Files:**
- Modify: `lua/plugins/formatting.lua:9` (conform `formatters_by_ft`)
- Modify: `lua/plugins/linting.lua:11` (`lint.linters_by_ft`)
- Modify: `lua/config/lsp/setup.lua` (mason ensure_installed already covers LSPs; tools installed via Mason CLI here)

- [ ] **Step 1: Install Go Mason tools**

Run:
```bash
nvim --headless -c 'MasonInstall gopls delve golangci-lint gofumpt goimports-reviser gomodifytags impl gotests gotestsum' -c 'qa' 2>&1 | tail -5
```
Expected: each package reports installed. Verify: `ls ~/.local/share/nvim/mason/bin | grep -E 'gopls|dlv|golangci-lint|gofumpt|goimports-reviser|gomodifytags|impl|gotests|gotestsum'` lists all.

- [ ] **Step 2: Add Go formatters to conform**

In `lua/plugins/formatting.lua`, inside `formatters_by_ft = {` add:

```lua
          go = { "goimports_reviser", "gofumpt" },
```

- [ ] **Step 3: Add golangci-lint to nvim-lint**

In `lua/plugins/linting.lua`, inside `lint.linters_by_ft = {` add:

```lua
        go = { "golangcilint" },
```

- [ ] **Step 4: Sync + verify gate on a real Go file**

Run:
```bash
cd ~/.config/nvim
nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2
mkdir -p /tmp/gomod && cd /tmp/gomod && [ -f go.mod ] || go mod init verify 2>/dev/null
printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("hi") }\n' > /tmp/gomod/main.go
cd ~/.config/nvim && VERIFY_WAIT_MS=14000 scripts/verify-nvim.sh /tmp/gomod/main.go
```
Expected: `VERIFY: PASS`. Then confirm gopls attaches:
```bash
nvim --headless /tmp/gomod/main.go -c 'lua vim.defer_fn(function() local c=vim.lsp.get_clients({bufnr=0}); local n={} for _,x in ipairs(c) do n[#n+1]=x.name end print("go_clients="..table.concat(n,",")); vim.cmd("qa!") end, 9000)' 2>&1 | grep go_clients
```
Expected: `go_clients=` contains `gopls`.

- [ ] **Step 5: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/languages/go.lua lua/config/lsp/servers/gopls.lua \
        lua/plugins/testing.lua lua/plugins/formatting.lua lua/plugins/linting.lua lazy-lock.json
git commit -m "$(printf 'feat(go): gopls + go.nvim + nvim-dap-go + neotest-golang + conform/lint\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

**PHASE 3 GATE:** verify PASS; gopls attaches on a `.go` file; `:GoTest`/dap-go available. User confirms before Phase 4.

---

## Phase 4 — Java / Spring Boot

### Task 4.1: Mason Java tools

**Files:** none (Mason CLI)

- [ ] **Step 1: Install jdtls + debug/test + Spring bundles**

Run:
```bash
nvim --headless -c 'MasonInstall jdtls java-debug-adapter java-test vscode-spring-boot-tools google-java-format' -c 'qa' 2>&1 | tail -6
```
Expected: all five installed. Verify: `ls ~/.local/share/nvim/mason/packages | grep -E 'jdtls|java-debug-adapter|java-test|vscode-spring-boot-tools|google-java-format'` lists all.

### Task 4.2: jdtls launcher (ftplugin) — the required nvim-jdtls pattern

**Files:**
- Create: `lua/plugins/languages/java.lua` (plugin specs only)
- Create: `ftplugin/java.lua` (start_or_attach — runs per Java buffer)
- Create: `lua/config/lsp/servers/jdtls.lua` (settings/bundles builder)

- [ ] **Step 1: Resolve pins**

Run:
```bash
git ls-remote https://github.com/mfussenegger/nvim-jdtls HEAD
git ls-remote https://github.com/JavaHello/spring-boot.nvim HEAD
git ls-remote https://github.com/rcasia/neotest-java HEAD
```
Record SHAs.

- [ ] **Step 2: Create `lua/plugins/languages/java.lua`**

```lua
return {
  { "mfussenegger/nvim-jdtls", commit = "<NVIM_JDTLS_SHA>", ft = "java" },
  {
    "JavaHello/spring-boot.nvim",
    commit = "<SPRING_BOOT_NVIM_SHA>",
    ft = "java",
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {},
  },
  {
    "rcasia/neotest-java",
    commit = "<NEOTEST_JAVA_SHA>",
    ft = "java",
    dependencies = { "nvim-neotest/neotest", "mfussenegger/nvim-jdtls" },
  },
}
```

- [ ] **Step 3: Create `lua/config/lsp/servers/jdtls.lua`**

```lua
local M = {}

local mason = vim.fn.stdpath("data") .. "/mason/packages"

local function jdk(home) return vim.fn.isdirectory(home) == 1 and home or nil end

M.runtimes = (function()
  local r = {}
  local map = {
    ["JavaSE-17"] = "/opt/homebrew/Cellar/openjdk@17/17.0.19/libexec/openjdk.jdk/Contents/Home",
    ["JavaSE-21"] = "/opt/homebrew/Cellar/openjdk@21/21.0.11/libexec/openjdk.jdk/Contents/Home",
    ["JavaSE-23"] = vim.fn.expand("~/Library/Java/JavaVirtualMachines/openjdk-23.0.2/Contents/Home"),
  }
  for name, home in pairs(map) do
    if jdk(home) then
      r[#r + 1] = { name = name, path = home, default = (name == "JavaSE-21") or nil }
    end
  end
  return r
end)()

-- Combine java-debug + java-test + spring-boot bundles into one list.
function M.bundles()
  local b = {}
  vim.list_extend(b, vim.split(
    vim.fn.glob(mason .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
    "\n", { trimempty = true }))
  for _, jar in ipairs(vim.split(
    vim.fn.glob(mason .. "/java-test/extension/server/*.jar", true), "\n", { trimempty = true })) do
    if not jar:match("com.microsoft.java.test.runner%-jar%-with%-dependencies.jar")
      and not jar:match("jacocoagent.jar") then
      b[#b + 1] = jar
    end
  end
  local ok, springboot = pcall(require, "spring_boot")
  if ok then vim.list_extend(b, springboot.java_extensions()) end
  return b
end

function M.lombok_javaagent()
  local jar = mason .. "/jdtls/lombok.jar"
  return vim.fn.filereadable(jar) == 1 and ("--jvm-arg=-javaagent:" .. jar) or nil
end

return M
```

- [ ] **Step 4: Create `ftplugin/java.lua`**

```lua
local ok, jdtls = pcall(require, "jdtls")
if not ok then return end

local cfgmod = require("config.lsp.servers.jdtls")
local mason = vim.fn.stdpath("data") .. "/mason/packages"

local root = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
if not root then return end
local project = vim.fn.fnamemodify(root, ":p:h:t")
local workspace = vim.fn.expand("~/.cache/jdtls/workspace/") .. project

local launcher = vim.fn.glob(mason .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar", true)
local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

local cmd = { jdtls_bin, "-data", workspace }
local lombok = cfgmod.lombok_javaagent()
if lombok then table.insert(cmd, lombok) end

local config = {
  cmd = cmd,
  root_dir = root,
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  init_options = { bundles = cfgmod.bundles() },
  settings = {
    java = {
      configuration = { runtimes = cfgmod.runtimes },
      import = { gradle = { wrapper = { enabled = true } }, maven = { enabled = true } },
      format = { enabled = false }, -- conform owns formatting
      inlayHints = { parameterNames = { enabled = "all" } },
    },
  },
  on_attach = function(_, bufnr)
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    jdtls.setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()
    -- Spring Boot remote-attach DAP config
    local dap = require("dap")
    dap.configurations.java = dap.configurations.java or {}
    table.insert(dap.configurations.java, {
      type = "java", request = "attach", name = "Spring Boot: attach (jdwp :5005)",
      hostName = "127.0.0.1", port = 5005,
    })
  end,
}

jdtls.start_or_attach(config)
```

- [ ] **Step 5: Register neotest-java adapter**

In `lua/plugins/testing.lua` neotest adapters table add:

```lua
        require("neotest-java")({}),
```

- [ ] **Step 6: Sync + verify gate on a real Java file**

Run:
```bash
cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2
mkdir -p /tmp/javaproj/src && cd /tmp/javaproj && [ -f pom.xml ] || printf '<project><modelVersion>4.0.0</modelVersion><groupId>v</groupId><artifactId>v</artifactId><version>1</version></project>\n' > pom.xml
printf 'public class App { public static void main(String[] a){ System.out.println("hi"); } }\n' > /tmp/javaproj/src/App.java
cd ~/.config/nvim && VERIFY_WAIT_MS=20000 scripts/verify-nvim.sh /tmp/javaproj/src/App.java
```
Expected: `VERIFY: PASS` (jdtls indexing is slow; the 20s wait covers attach). Then:
```bash
nvim --headless /tmp/javaproj/src/App.java -c 'lua vim.defer_fn(function() local c=vim.lsp.get_clients({bufnr=0}); local n={} for _,x in ipairs(c) do n[#n+1]=x.name end print("java_clients="..table.concat(n,",")); vim.cmd("qa!") end, 18000)' 2>&1 | grep java_clients
```
Expected: `java_clients=` contains `jdtls`.

- [ ] **Step 7: Java formatter in conform**

In `lua/plugins/formatting.lua` `formatters_by_ft` add:

```lua
          java = { "google-java-format" },
```

- [ ] **Step 8: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/languages/java.lua ftplugin/java.lua \
        lua/config/lsp/servers/jdtls.lua lua/plugins/testing.lua lua/plugins/formatting.lua lazy-lock.json
git commit -m "$(printf 'feat(java): nvim-jdtls + spring-boot.nvim + java-debug/test + neotest-java\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

**PHASE 4 GATE:** verify PASS; jdtls attaches on a `.java` file; Spring bundles load; DAP `java` config present. User confirms before Phase 5.

---

## Phase 5 — Cross-cutting tooling

### Task 5.0: Remove the tooling placeholder

- [ ] **Step 1:** `rm ~/.config/nvim/lua/plugins/tooling/_placeholder.lua`

### Task 5.1: Database (vim-dadbod trio)

**Files:**
- Create: `lua/plugins/tooling/database.lua`

- [ ] **Step 1: Resolve pins**

Run:
```bash
git ls-remote https://github.com/tpope/vim-dadbod HEAD
git ls-remote https://github.com/kristijanhusak/vim-dadbod-ui HEAD
git ls-remote https://github.com/kristijanhusak/vim-dadbod-completion HEAD
```

- [ ] **Step 2: Create `lua/plugins/tooling/database.lua`**

```lua
return {
  {
    "kristijanhusak/vim-dadbod-ui",
    commit = "<DADBOD_UI_SHA>",
    dependencies = {
      { "tpope/vim-dadbod", commit = "<DADBOD_SHA>", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", commit = "<DADBOD_CMP_SHA>", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
    end,
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.per_filetype = opts.sources.per_filetype or {}
      opts.sources.per_filetype.sql = { "dadbod", "buffer" }
      opts.sources.per_filetype.mysql = { "dadbod", "buffer" }
      opts.sources.per_filetype.plsql = { "dadbod", "buffer" }
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" }
      return opts
    end,
  },
}
```

- [ ] **Step 3: Verify gate + commit**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2 && scripts/verify-nvim.sh`
Expected: `VERIFY: PASS`.
```bash
git add lua/plugins/tooling/database.lua lazy-lock.json
git commit -m "$(printf 'feat(db): vim-dadbod ui + completion (blink source)\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 5.2: REST client (kulala.nvim)

**Files:**
- Create: `lua/plugins/tooling/rest.lua`
- Modify: `.gitignore` (ignore kulala env files — already added in baseline `.gitignore`; verify line `http-client.env.json` present, add `**/http-client.private.env.json` if missing)

- [ ] **Step 1: Resolve pin** — `git ls-remote https://github.com/mistweaverco/kulala.nvim HEAD`

- [ ] **Step 2: Create `lua/plugins/tooling/rest.lua`**

```lua
return {
  {
    "mistweaverco/kulala.nvim",
    commit = "<KULALA_SHA>",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "REST: send request", ft = { "http", "rest" } },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "REST: toggle body/headers", ft = { "http", "rest" } },
      { "<leader>Rp", function() require("kulala").jump_prev() end, desc = "REST: prev request", ft = { "http", "rest" } },
      { "<leader>Rn", function() require("kulala").jump_next() end, desc = "REST: next request", ft = { "http", "rest" } },
    },
    opts = { default_view = "body", default_env = "dev" },
  },
}
```

- [ ] **Step 3: Verify gate + commit**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2 && scripts/verify-nvim.sh`
Expected: `VERIFY: PASS`.
```bash
git add lua/plugins/tooling/rest.lua lazy-lock.json
git commit -m "$(printf 'feat(rest): kulala.nvim http client\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 5.3: Task runner (overseer.nvim)

**Files:**
- Create: `lua/plugins/tooling/tasks.lua`

- [ ] **Step 1: Resolve pin** — `git ls-remote https://github.com/stevearc/overseer.nvim HEAD`

- [ ] **Step 2: Create `lua/plugins/tooling/tasks.lua`**

```lua
return {
  {
    "stevearc/overseer.nvim",
    commit = "<OVERSEER_SHA>",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerQuickAction", "OverseerRunCmd" },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: run task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer: toggle panel" },
    },
    opts = {
      strategy = "terminal",
      templates = { "builtin" },
    },
  },
}
```

- [ ] **Step 3: Verify gate + commit**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2 && scripts/verify-nvim.sh`
Expected: `VERIFY: PASS`. (Check `<leader>o` does not collide: `grep -rn '"<leader>o' ~/.config/nvim/lua/plugins/which-key` — if taken, use `<leader>jo`/`<leader>jt`.)
```bash
git add lua/plugins/tooling/tasks.lua lazy-lock.json
git commit -m "$(printf 'feat(tasks): overseer.nvim task runner\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 5.4: Containers (Docker/K8s LSPs) + monorepo nav

**Files:**
- Create: `lua/plugins/tooling/containers.lua`
- Modify: `lua/config/lsp/setup.lua:49-59` (ensure_installed)

- [ ] **Step 1: Add container/yaml LSPs to ensure_installed**

In `lua/config/lsp/setup.lua` `ensure_installed`, add:

```lua
    "dockerls",
    "docker_compose_language_service",
    "helm_ls",
    "yamlls",
```

(mason-lspconfig maps these to Mason packages `dockerfile-language-server`, `docker-compose-language-service`, `helm-ls`, `yaml-language-server`.)

- [ ] **Step 2: Resolve pin** — `git ls-remote https://github.com/imNel/monorepo.nvim HEAD`

- [ ] **Step 3: Create `lua/plugins/tooling/containers.lua`**

```lua
return {
  -- yamlls with Kubernetes + CRD catalog schemas; filetype-gated vs helm-ls
  {
    "neovim/nvim-lspconfig",
    ft = { "yaml", "yaml.docker-compose", "helm", "dockerfile" },
    config = function()
      local caps = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("yamlls", {
        capabilities = caps,
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = {
              kubernetes = "*.k8s.{yml,yaml}",
              ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/all.json"] = "/*.crd.{yml,yaml}",
            },
          },
        },
      })
      vim.lsp.enable("yamlls")
    end,
  },
  {
    "imNel/monorepo.nvim",
    commit = "<MONOREPO_SHA>",
    dependencies = { "nvim-telescope/telescope.nvim" },
    cmd = { "Telescope monorepo" },
    keys = { { "<leader>fm", "<cmd>Telescope monorepo<cr>", desc = "Monorepo: switch sub-root" } },
    config = function()
      require("monorepo").setup({ silent = false })
      require("telescope").load_extension("monorepo")
    end,
  },
}
```

- [ ] **Step 4: Install Mason packages + verify gate**

Run:
```bash
nvim --headless -c 'MasonInstall dockerfile-language-server docker-compose-language-service helm-ls yaml-language-server' -c 'qa' 2>&1 | tail -4
cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2
printf 'apiVersion: v1\nkind: Pod\n' > /tmp/verify.k8s.yaml
scripts/verify-nvim.sh /tmp/verify.k8s.yaml
```
Expected: `VERIFY: PASS`.

- [ ] **Step 5: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/tooling/containers.lua lua/config/lsp/setup.lua lazy-lock.json
git commit -m "$(printf 'feat(infra): docker/k8s LSPs + monorepo.nvim nav\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

**PHASE 5 GATE:** verify PASS on yaml/sql/http buffers; no `<leader>` collisions. User confirms before Phase 6.

---

## Phase 6 — AI consolidation

### Task 6.1: Remove redundant AI plugins

**Files:**
- Delete: `lua/plugins/ai/copilot-chat.lua`
- Delete: `lua/plugins/ai/avante.lua`

- [ ] **Step 1: Find keymap/command references to remove**

Run: `grep -rn "CopilotChat\|avante\|<leader>a" ~/.config/nvim/lua | grep -v 'ai/codecompanion\|ai/copilot.lua'`
Note every `<leader>a*` binding tied to avante/copilot-chat so Task 6.2 can reclaim them.

- [ ] **Step 2: Delete the two plugin files**

Run: `rm ~/.config/nvim/lua/plugins/ai/copilot-chat.lua ~/.config/nvim/lua/plugins/ai/avante.lua`

- [ ] **Step 3: Remove dangling references**

For each reference found in Step 1 that lives outside the deleted files (e.g. which-key groups), remove the avante/CopilotChat lines. Leave `<leader>a` as a free prefix for codecompanion.

- [ ] **Step 4: Verify gate**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3 && scripts/verify-nvim.sh`
Expected: sync shows `avante.nvim`, `CopilotChat.nvim` removed (clean); `VERIFY: PASS`.

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add -A
git commit -m "$(printf 'refactor(ai): drop redundant copilot-chat + avante\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

### Task 6.2: Tune codecompanion (Claude backend + per-stack context)

**Files:**
- Modify: `lua/plugins/ai/codecompanion.lua`

- [ ] **Step 1: Inspect current codecompanion spec**

Run: `cat ~/.config/nvim/lua/plugins/ai/codecompanion.lua`
Identify the `opts`/`config` and any existing adapter/keymap setup.

- [ ] **Step 2: Set Anthropic as the default chat/inline adapter**

In the codecompanion `opts`, set:

```lua
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = { api_key = "ANTHROPIC_API_KEY" },
          })
        end,
      },
      strategies = {
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
        cmd = { adapter = "anthropic" },
      },
```

Keep any existing Copilot adapter entry as a secondary (do not delete it). Add a note comment that `ANTHROPIC_API_KEY` must be exported in the shell; if absent, codecompanion falls back to the Copilot adapter.

- [ ] **Step 3: Reclaim `<leader>a` keymaps for codecompanion**

Add (or align existing) keys in the codecompanion spec:

```lua
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: chat toggle" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI: inline" },
    },
```

- [ ] **Step 4: Confirm copilot.lua stays inline-only**

Run: `grep -n "suggestion\|panel\|enabled" ~/.config/nvim/lua/plugins/ai/copilot.lua | head`
Ensure copilot.lua provides inline suggestions only and codecompanion does NOT also enable an inline suggestion provider (only one inline provider). No change if already inline-only.

- [ ] **Step 5: Verify gate**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa 2>&1 | tail -2 && scripts/verify-nvim.sh`
Expected: `VERIFY: PASS`. Sanity: `nvim --headless -c 'lua print(pcall(require,"codecompanion"))' -c 'qa' 2>&1 | tail -1` → `true`.

- [ ] **Step 6: Pin lockfile + commit**

```bash
cd ~/.config/nvim
git add lua/plugins/ai/codecompanion.lua lazy-lock.json
git commit -m "$(printf 'feat(ai): codecompanion Claude backend + reclaimed <leader>a keymaps\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>')"
```

**PHASE 6 GATE:** verify PASS; only copilot.lua + codecompanion remain; `<leader>a` works; no keymap errors.

---

## Final acceptance (after Phase 6)

- [ ] **Run the full per-stack smoke matrix**

```bash
cd ~/.config/nvim
for f in /tmp/verify_sample.ts /tmp/gomod/main.go /tmp/javaproj/src/App.java /tmp/verify.k8s.yaml; do
  echo "### $f"; VERIFY_WAIT_MS=18000 scripts/verify-nvim.sh "$f" | tail -1
done
```
Expected: `VERIFY: PASS` for every file.

- [ ] **Confirm success criteria from spec §6:** each stack LSP attaches (hover/completion/inlay/code-action), DAP config present, neotest adapter loaded, conform+lint wired, EcoVim/LeerVim JS keymaps intact except intentional vtsls swap, AI reduced to two plugins.

- [ ] **Tag the finished state**

```bash
cd ~/.config/nvim
git tag -a fullstack-ide-v1 -m "Full-stack IDE overlay complete (JS/TS, Go, Java/Spring, tooling, AI)"
```

---

## Self-review notes (addressed)

- **Spec coverage:** every spec §3/§4 component maps to a task (vtsls→2.1-2.4, Next.js DAP/vitest→2.5, Go→3.1-3.3, Java/Spring→4.1-4.2, DB/REST/tasks/containers/monorepo→5.1-5.4, AI→6.1-6.2, guardrails/verify→1.1-1.3).
- **Spec deviation:** `ts_ls`→ actually `typescript-tools`→`vtsls`; flagged in header and handled in 2.0/2.4. **Requires user confirmation before Phase 2.**
- **Reality adjustments:** `dap.lua` already wires pwa-node/pwa-chrome → Task 2.5 only adds Next.js attach/launch/compound (no duplicate adapter). `plugins.tooling` not auto-imported → Task 1.2 adds the import. LeerVim (not EcoVim) global used throughout.
- **Pins:** every new plugin spec carries `commit = "<SHA>"`; SHAs resolved per-task via `git ls-remote` (placeholders `<...>` are resolve-at-implementation tokens, not omissions).
- **Type/name consistency:** module names (`config.lsp.servers.vtsls`/`gopls`/`jdtls`), exported fields (`.settings`, `.on_attach`, `.root_dir`, `.bundles`, `.runtimes`, `.lombok_javaagent`) are consistent across tasks.
