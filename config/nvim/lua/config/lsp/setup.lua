-- Setup installer & lsp configs
local mason = require("mason")
local mason_lsp = require("mason-lspconfig")
local ufo_utils = require("utils._ufo")
local ufo_config_handler = ufo_utils.handler
local lspconfig = require("lspconfig")

-- 1. Setup Mason
mason.setup({
  ui = {
    border = LeerVim.ui.float.border or "rounded",
  },
})

-- 2. Define Capabilities, Handlers, and OnAttach FIRST (so they are available below)
-- Local replacement for vim.lsp.with(), which was removed in Nvim 0.12.
-- Same behavior: returns a handler that merges the override config.
local function with(handler, override_config)
  return function(err, result, ctx, config)
    return handler(err, result, ctx, vim.tbl_deep_extend("force", config or {}, override_config))
  end
end

local handlers = {
  ["textDocument/hover"] = with(vim.lsp.handlers.hover, {
    silent = true,
    border = LeerVim.ui.float.border,
  }),
  ["textDocument/signatureHelp"] = with(vim.lsp.handlers.signature_help, { border = LeerVim.ui.float.border }),
}

local capabilities = require('blink.cmp').get_lsp_capabilities()

local function on_attach(client, bufnr)
  vim.lsp.inlay_hint.enable(true, { bufnr })
end

-- Global override for floating preview border
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or LeerVim.ui.float.border or "rounded" -- default to LeerVim border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- 2b. Register vtsls via the vim.lsp.config framework.
-- mason-lspconfig v2 ignores the legacy `handlers` table below and starts
-- vtsls through `vim.lsp.enable("vtsls")`, which resolves `vim.lsp.config.vtsls`
-- (the native nvim-lspconfig `lsp/vtsls.lua`, whose root_dir falls back to
-- getcwd() and which has no on_attach). vim.lsp.config() deep-merges, so this
-- override layers our root_dir / on_attach / settings on top and takes effect.
do
  local vt = require("config.lsp.servers.vtsls")
  vim.lsp.config("vtsls", {
    capabilities = capabilities,
    handlers = handlers,
    on_attach = vt.on_attach,
    settings = vt.settings,
    root_dir = vt.root_dir,
  })
end

-- 2b-go. Register gopls via the vim.lsp.config framework (same proven path as
-- vtsls above). The nvim-lspconfig `go.lua` plugin spec cannot own this: Lazy
-- merges duplicate nvim-lspconfig specs and keeps only one `config` function
-- (the canonical lazy=false one in lua/plugins/lsp.lua, which loads THIS file),
-- so a second `config` in go.lua is silently dropped. Registering here is the
-- supported mechanism: vim.lsp.config() deep-merges our Mason-pinned cmd,
-- LeerVim settings, Go-aware root_dir and inlay-hint on_attach onto the native
-- nvim-lspconfig gopls config, and vim.lsp.enable("gopls") starts it.
do
  local gopls = require("config.lsp.servers.gopls")
  vim.lsp.config("gopls", {
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls" },
    capabilities = capabilities,
    handlers = handlers,
    settings = gopls.settings,
    root_dir = gopls.root_dir,
    on_attach = gopls.on_attach,
  })
  vim.lsp.enable("gopls")
end

-- 2b-yaml. Register yamlls (Kubernetes / CRD schemas) via the vim.lsp.config
-- framework, same proven path as gopls/vtsls above. mason-lspconfig v2
-- auto-enables it once it is in ensure_installed; this block layers our
-- LeerVim capabilities + bordered handlers + k8s/CRD schema settings on top
-- of the native nvim-lspconfig yamlls config. (A second nvim-lspconfig plugin
-- spec cannot own this -- Lazy keeps only one `config` fn.)
vim.lsp.config("yamlls", {
  capabilities = capabilities,
  handlers = handlers,
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = {
        kubernetes = "*.k8s.{yml,yaml}",
        ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/all.json"] = "/*.crd.{yml,yaml}",
      },
      validate = true,
      format = { enable = false },
    },
  },
})

-- 2c. Register the remaining servers via the vim.lsp.config framework.
-- mason-lspconfig v2 ignores the legacy `handlers` table that used to live in
-- mason_lsp.setup({...}); it auto-enables installed servers via
-- vim.lsp.enable(). vim.lsp.config() (called BEFORE mason_lsp.setup) is the
-- supported way to layer our LeerVim-tuned config. These ports preserve the
-- previous per-server config exactly -- only the mechanism changed.

-- Global defaults: blink.cmp capabilities + inlay-hint on_attach + bordered
-- handlers for every server (replaces the dead unnamed default handler).
vim.lsp.config("*", {
  capabilities = capabilities,
  on_attach = on_attach,
  handlers = handlers,
})

do
  local cssls = require("config.lsp.servers.cssls")
  vim.lsp.config("cssls", {
    capabilities = capabilities,
    handlers = handlers,
    on_attach = cssls.on_attach,
    settings = cssls.settings,
  })
end

do
  local eslint = require("config.lsp.servers.eslint")
  vim.lsp.config("eslint", {
    capabilities = capabilities,
    handlers = handlers,
    on_attach = eslint.on_attach,
    settings = eslint.settings,
    flags = {
      allow_incremental_sync = false,
      debounce_text_changes = 1000,
      exit_timeout = 1500,
    },
  })
end

do
  local jsonls = require("config.lsp.servers.jsonls")
  vim.lsp.config("jsonls", {
    capabilities = capabilities,
    handlers = handlers,
    on_attach = on_attach,
    settings = jsonls.settings,
  })
end

do
  local lua_ls = require("config.lsp.servers.lua_ls")
  vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    handlers = handlers,
    on_attach = on_attach,
    settings = lua_ls.settings,
  })
end

do
  local vuels = require("config.lsp.servers.vuels")
  vim.lsp.config("vuels", {
    handlers = handlers,
    filetypes = vuels.filetypes,
    init_options = vuels.init_options,
    on_attach = vuels.on_attach,
    settings = vuels.settings,
  })
end

do
  -- Same capabilities tweaks the old ["tailwindcss"] handler applied.
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.colorProvider = { dynamicRegistration = false }
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  local tailwindcss = require("config.lsp.servers.tailwindcss")
  vim.lsp.config("tailwindcss", {
    capabilities = capabilities,
    handlers = handlers,
    filetypes = tailwindcss.filetypes,
    init_options = tailwindcss.init_options,
    on_attach = tailwindcss.on_attach,
    settings = tailwindcss.settings,
    flags = {
      debounce_text_changes = 1000,
    },
  })
end

-- 3. Setup Mason LSP. mason-lspconfig v2 auto-enables installed servers via
-- vim.lsp.enable(); the legacy `handlers` table is intentionally omitted
-- because v2 ignores it (all per-server config is wired above via
-- vim.lsp.config).
mason_lsp.setup({
  -- A list of servers to automatically install if they're not already installed
  ensure_installed = {
    "bashls",
    "cssls",
    "docker_compose_language_service",
    "dockerls",
    "eslint",
    "gopls",
    "graphql",
    "helm_ls",
    "html",
    "jsonls",
    "lua_ls",
    "prismals",
    "tailwindcss",
    "vtsls",
    "terraformls",
    "yamlls",
  },
  automatic_installation = true,
  -- jdtls is driven by nvim-jdtls (ftplugin/java.lua + start_or_attach), NOT
  -- mason-lspconfig. The standalone `java-language-server` Mason package
  -- (georgewfraser) would otherwise be auto-enabled here and attach a second,
  -- conflicting Java client whose malformed client/unregisterCapability
  -- requests crash Neovim 0.12.2 core (_unregister_dynamic, nil table).
  automatic_enable = { exclude = { "java_language_server" } },
})

-- 4. Setup UFO
require("ufo").setup({
  fold_virt_text_handler = ufo_config_handler,
  close_fold_kinds_for_ft = { default = { "imports" } },
})
