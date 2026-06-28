-- Compatibility shims for removed Neovim APIs.
--
-- galaxyline.nvim (abandoned upstream, last commit 2021) and some other older
-- plugins still call vim.lsp.get_active_clients() / vim.lsp.buf_get_clients(),
-- which were deprecated and slated for removal in Nvim 0.12. On every LSP
-- attach this triggered a noisy deprecation notification.
--
-- Re-point the old names at the modern vim.lsp.get_clients() API so the legacy
-- call sites keep working without emitting deprecation warnings. This mirrors
-- the existing monkey-patch style used in config/lsp/setup.lua.
if vim.lsp.get_clients then
  vim.lsp.get_active_clients = function(filter)
    return vim.lsp.get_clients(filter)
  end

  vim.lsp.buf_get_clients = function(bufnr)
    return vim.lsp.get_clients({ bufnr = bufnr or 0 })
  end
end
