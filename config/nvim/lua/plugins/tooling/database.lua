return {
  {
    "kristijanhusak/vim-dadbod-ui",
    commit = "07e92e22114cc5b1ba4938d99897d85b58e20475",
    dependencies = {
      { "tpope/vim-dadbod", commit = "6d1d41da4873a445c5605f2005ad2c68c99d8770", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", commit = "a8dac0b3cf6132c80dc9b18bef36d4cf7a9e1fe6", ft = { "sql", "mysql", "plsql" }, lazy = true },
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
