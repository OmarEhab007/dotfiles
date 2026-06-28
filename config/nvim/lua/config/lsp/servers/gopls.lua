local M = {}

-- Resolve the Go module/workspace root. Prefer a go.work (multi-module
-- workspace) so the whole workspace shares one gopls; otherwise anchor at the
-- nearest go.mod, falling back to .git.
--
-- Dual-contract on purpose (same as vtsls): mason-lspconfig v2 /
-- vim.lsp.enable() drive gopls through the async `(bufnr, on_dir)` contract;
-- the legacy `lspconfig.gopls.setup{}` path calls `(fname)` and expects a
-- return value. Supporting both keeps the root correct regardless of path.
local function resolve_root(fname)
  local start = vim.fs.dirname(fname)
  local work = vim.fs.find({ "go.work" }, { upward = true, path = start })[1]
  if work then
    return vim.fs.dirname(work)
  end
  local mod = vim.fs.find({ "go.mod", ".git" }, { upward = true, path = start })[1]
  return mod and vim.fs.dirname(mod) or nil
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

M.on_attach = function(_, bufnr)
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

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
