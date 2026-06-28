-- gopls is wired via vim.lsp.config/vim.lsp.enable in lua/config/lsp/setup.lua
-- (the same proven path as vtsls). It cannot live in a second nvim-lspconfig
-- plugin spec here: Lazy merges duplicate specs for one plugin and keeps only
-- a single `config` function (the canonical lazy=false spec in
-- lua/plugins/lsp.lua), so any `config` added here is silently dropped.
return {
  {
    "ray-x/go.nvim",
    branch = "master",
    commit = "5c741a26f5df77c95d42d8f48e7008aea10e5f4f",
    dependencies = {
      { "ray-x/guihua.lua", commit = "ae1a09035709a5952ae6f2fab742c2097c31a8f2", build = "cd lua/fzy && make" },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,
      lsp_inlay_hints = { enable = false },
      dap_debug = true,
      dap_debug_keymap = false,
      trouble = false,
      luasnip = false,
    },
  },

  {
    "leoluz/nvim-dap-go",
    commit = "b4421153ead5d726603b02743ea40cf26a51ed5f",
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
    commit = "84c1f3be59f85a2f5bbb9290040077bc8a68a00c",
    ft = "go",
    dependencies = { "nvim-neotest/neotest", "leoluz/nvim-dap-go" },
  },
}
