# Design: LeerVim → Modern Full-Stack IDE

- **Date:** 2026-05-18
- **Status:** Approved (design); pending spec review → implementation plan
- **Base:** LeerVim distro, Neovim 0.12.2, lazy.nvim, blink.cmp, conform.nvim, nvim-lint, nvim-dap, neotest
- **Goal:** Turn the existing LeerVim config into a modern full-stack IDE focused on JS/TypeScript, Next.js, Go, and Java/Spring Boot, with debugging, test runners, refactoring/code actions, and surrounding project tooling for every target stack.

## 1. Decisions (locked)

| Decision | Choice |
|---|---|
| Change strategy | Augment LeerVim in place (strictly additive overlay; no LeerVim internal rewrites) |
| IDE capabilities | Debugging (DAP), test runners, refactoring/code actions, project/run tooling — for all 4 stacks |
| TS server | Swap `ts_ls` → `vtsls` (+ `nvim-vtsls`); keep `ts_ls` config as documented fallback |
| AI layer | Modernize for these stacks: consolidate to `copilot.lua` + `codecompanion.nvim`; remove `copilot-chat`, `avante` |
| Surrounding tools | DB UI, REST client, task/build runner, Docker/K8s + monorepo — all in scope |
| Rollout | Phased per-stack with a verification gate after each phase |

## 2. Architecture & principles

Strictly additive overlay. Every change is either a new self-contained file or an *append* to an existing config table — never a rewrite of LeerVim internals. Existing keymaps, UI, and JS/TS behavior remain intact except the intentional `ts_ls→vtsls` swap. Each new plugin file must be independently loadable and removable.

**File layout (new / modified):**

```
lua/plugins/languages/
  typescript.lua   MODIFY: ts_ls→vtsls, add nvim-vtsls, ts-error-translator
  go.lua           NEW
  java.lua         NEW: nvim-jdtls + spring-boot.nvim
lua/plugins/tooling/
  database.lua     NEW: vim-dadbod trio
  rest.lua         NEW: kulala.nvim
  tasks.lua        NEW: overseer.nvim
  containers.lua   NEW: docker/k8s LSPs
  monorepo.lua     NEW: monorepo.nvim + root_dir helpers
lua/plugins/ai/    MODIFY: remove copilot-chat.lua, avante.lua; tune codecompanion.lua + copilot.lua
lua/config/lsp/
  setup.lua        MODIFY: add servers to ensure_installed + handlers
  servers/gopls.lua, jdtls.lua, ...  NEW per-server settings
ftplugin/java.lua  NEW: jdtls start_or_attach (required nvim-jdtls pattern)
lua/config/compat.lua  EXTEND: documented home for Neovim 0.12 shims/guardrails
scripts/verify-nvim.sh NEW: formalized clean-startup verification gate
docs/superpowers/specs/2026-05-18-nvim-fullstack-ide-design.md  this spec
```

## 3. Per-stack components

### JS/TS/Next.js (modify `typescript.lua`)
- `vtsls` + `yioneko/nvim-vtsls`: organize/sort/add-missing imports, fix-all, source actions, go-to-source-definition, file references.
- `dmmulroy/ts-error-translator.nvim`; keep `vuki656/package-info.nvim`.
- ESLint flat-config auto-detect (`vscode-eslint-language-server`); Prettier via existing conform (don't double-format).
- DAP: wire `js-debug-adapter` directly via `jay-babu/mason-nvim-dap`; **drop** unmaintained `nvim-dap-vscode-js`. Configs: Next.js server (`pwa-node` attach to `node --inspect`), client (`pwa-chrome` → `localhost:3000`), and a compound to start both.
- Testing: add `marilari88/neotest-vitest` alongside existing `neotest-jest`; neotest auto-selects per package; test debug via `strategy = "dap"`.
- `root_dir` anchored at `turbo.json` / `pnpm-workspace.yaml` / `.git` so each Turborepo package gets its own server.
- `ts_ls` settings retained as commented, documented fallback in the same file.

### Go (new `go.lua`)
- `gopls` via native `vim.lsp.config` / `vim.lsp.enable` with 2026 settings: `gofumpt`, `staticcheck`, full inlay `hints`, `codelenses` (generate/test/tidy/upgrade_dependency/vendor/run_govulncheck), `semanticTokens=true`, `analyses` (unusedparams, unusedwrite, nilness, shadow, useany), `vulncheck="Imports"`, `directoryFilters`, build tags via `build.buildFlags`/`build.env`. Root at `go.work` when present else nearest `go.mod`.
- `ray-x/go.nvim` + `ray-x/guihua.lua`, pinned to `master` (requires Neovim 0.12 — satisfied by 0.12.2; no nvim-treesitter dep on master).
- `leoluz/nvim-dap-go` + Mason `delve` (debug nearest test, debug last, attach, binary launch).
- `fredrikaverpil/neotest-golang` with `runner = "gotestsum"`; pair with existing `nvim-coverage`.
- Formatting via conform: `{ "goimports_reviser", "gofumpt" }` (imports before gofumpt); disable LSP format for Go to avoid double-format.
- Linting via nvim-lint: `golangci-lint` v2 (ensure nvim-lint recent for v2 JSON output).
- Mason: `gopls`, `delve`, `golangci-lint`, `gofumpt`, `goimports-reviser`, `gomodifytags`, `impl`, `gotests`, `gotestsum`.

### Java/Spring Boot (new `java.lua` + `ftplugin/java.lua`)
- `mfussenegger/nvim-jdtls` launched from `ftplugin/java.lua` via `start_or_attach`. jdtls JVM = JDK 21 (JAVA_HOME). Per-project data dir `~/.cache/jdtls/workspace/<project_name>` (persistent, never `/tmp`). `root_dir` = git/`mvnw`/`gradlew`/reactor root.
- `settings.java.configuration.runtimes`: `JavaSE-17`, `JavaSE-21` (default), `JavaSE-23` mapped to the installed JDK paths; `:JdtSetRuntime` to switch.
- Lombok: `-javaagent:<lombok.jar>` resolved from the Mason jdtls install.
- Gradle: wrapper-only (`java.import.gradle.wrapper.enabled = true`, no Gradle Home); Maven import on.
- `JavaHello/spring-boot.nvim` + Mason `vscode-spring-boot-tools`: bean nav, `application.properties/.yml` completion + validation, actuator/live data; bundles contributed to jdtls `init_options.bundles` via `require("spring_boot").java_extensions()`.
- Debug/test: Mason `java-debug-adapter` + `java-test`, **wildcard-globbed** jars (version skew is a known issue), combined into one `init_options.bundles` list (exclude `*test.runner-jar-with-dependencies.jar` and `jacocoagent.jar`); `setup_dap()` + `setup_dap_main_class_configs()`. Spring profiles via DAP `config_overrides.vmArgs`; remote attach config for jdwp.
- Testing: `rcasia/neotest-java` (JUnit 5, Maven + Gradle wrapper aware; repo-level root markers for monorepos).
- Formatting: `google-java-format` via conform default; per-project Eclipse formatter XML override where a corporate style is mandated.

## 4. Cross-cutting tooling & AI

- **DB:** `tpope/vim-dadbod` + `kristijanhusak/vim-dadbod-ui` + `kristijanhusak/vim-dadbod-completion`; register `vim_dadbod_completion.blink` source for `sql`/`mysql`/`plsql`; connections via env vars, lazy-load on `sql` + `DBUI`.
- **REST:** `mistweaverco/kulala.nvim` (JetBrains `.http` compatible; never `rest.nvim` — archived). Per-app `.http` files; `http-client.env.json` env files gitignored.
- **Tasks:** `stevearc/overseer.nvim` (npm/go/maven/gradle; nvim-dap strategy + neotest consumer). Test loop stays in neotest adapters; overseer for build/lint/codegen.
- **Containers:** Mason `dockerfile-language-server`, `docker-compose-language-service`, `helm-ls`, `yaml-language-server` + datreeio CRDs-catalog for K8s/CRD validation; filetype-gate yamlls vs helm-ls to avoid double diagnostics.
- **Monorepo:** native per-server `root_dir` strategy (turbo.json / `go.work` / Maven reactor) is the primary mechanism; optional `imNel/monorepo.nvim` for telescope-driven sub-root navigation (does not manage LSP roots).
- **AI:** Keep `zbirenbaum/copilot.lua` (inline only) + `olimorris/codecompanion.nvim` (v19+, native MCP/ACP — no mcphub.nvim required). **Remove** `copilot-chat.lua` and `avante.lua` (redundant; reclaim `<leader>a*`). Chat/agent backend → Anthropic Claude; Copilot inline/fallback. Per-stack context via slash-commands/variables (`#buffer`, `#lsp`, symbols); MCP filesystem/git scoped to the active package root to match the monorepo `root_dir` strategy. Only one inline provider enabled (copilot.lua).

## 5. Rollout, stability guardrails & verification

**Phases** (each is its own implementation chunk with a gate):

1. **Stability guardrails** (first, addresses recent breakage history)
2. JS/TS/Next.js (vtsls swap)
3. Go
4. Java/Spring Boot
5. Cross-cutting tools
6. AI consolidation

**Stability guardrails (Phase 1):**
- Every new plugin added with an explicit `commit`/`version` pin; `lazy-lock.json` committed after each phase.
- `lua/config/compat.lua` extended as the documented home for any Neovim 0.12 shims.
- `scripts/verify-nvim.sh` formalizes the PTY + `:checkhealth vim.deprecated` method: asserts zero red startup errors, zero `removed-in-0.12` deprecations, target plugins loaded, and LSP attaches on a sample file per stack.

**Per-phase gate:** implement → pin → run `verify-nvim.sh` → user confirms → next phase. Any failure triggers systematic-debugging before proceeding (no stacking fixes).

**Out of scope (YAGNI):** non-target languages; colorscheme/UI changes; LeerVim keymap redesign; the two cosmetic future-removal deprecations (`vim.highlight`, `vim.validate` — slated for Nvim 1.0/2.0, non-breaking).

**Risks & mitigations:**
- jdtls Mason version skew → wildcard-glob jars, pin Mason package versions.
- `ray-x/go.nvim` master requires Neovim 0.12 → satisfied by 0.12.2.
- vtsls behavioral differences vs ts_ls → keep documented ts_ls fallback in `typescript.lua`.
- Gradle not installed → wrapper-only (`./gradlew`); acceptable, jdtls prefers wrapper by default.
- New plugins pinned to known-good commits to prevent the stale-pin / Neovim-version breakage class that motivated this work.

## 6. Success criteria

- Each target stack: LSP attaches with hover/completion/inlay hints/code actions; debugging (breakpoint → step → inspect) works; tests run and debug from the editor; format-on-save and lint work.
- `scripts/verify-nvim.sh` passes after every phase (zero red errors, zero removed-in-0.12 deprecations).
- Existing LeerVim JS/TS workflow and keymaps unchanged except the intentional vtsls swap.
- AI layer reduced to two plugins, no keymap conflicts, Claude chat backend functional.
