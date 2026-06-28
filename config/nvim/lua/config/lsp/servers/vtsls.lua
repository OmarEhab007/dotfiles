local M = {}

-- Resolve the workspace/project root. Anchor at the monorepo/workspace marker
-- so each Turborepo package gets its own tsserver instance instead of one
-- giant root, then fall back to the nearest package.json / .git.
--
-- This is dual-contract on purpose: mason-lspconfig drives vtsls through
-- `vim.lsp.enable()`, whose root_dir contract is async `(bufnr, on_dir)`.
-- The legacy `lspconfig.vtsls.setup{}` path instead calls `(fname)` and
-- expects a return value. Supporting both keeps the root correct regardless
-- of which path wins the race.
local function resolve_root(fname)
  local start = vim.fs.dirname(fname)
  local markers = { "turbo.json", "pnpm-workspace.yaml", "nx.json", "lerna.json" }
  local ws = vim.fs.find(markers, { upward = true, path = start })[1]
  if ws then
    return vim.fs.dirname(ws)
  end
  local pkg = vim.fs.find({ "package.json", ".git" }, { upward = true, path = start })[1]
  return pkg and vim.fs.dirname(pkg) or nil
end

M.root_dir = function(a, b)
  -- vim.lsp.config contract: (bufnr, on_dir) -> call on_dir(root)
  if type(a) == "number" and type(b) == "function" then
    local fname = vim.api.nvim_buf_get_name(a)
    local root = resolve_root(fname)
    if root then
      b(root)
    end
    return
  end
  -- lspconfig.setup{} contract: (fname) -> dir|nil
  return resolve_root(a)
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
  local ok, wk = pcall(require, "plugins.which-key.setup")
  if ok and wk.attach_typescript then
    wk.attach_typescript(bufnr)
  end
end

return M
