return {
  {
    "yioneko/nvim-vtsls",
    commit = "0b5f73c9e50ce95842ea07bb3f05c7d66d87d14a",
    lazy = true,
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  },

  {
    "razak17/tailwind-fold.nvim",
    opts = {
      min_chars = 50,
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "html", "svelte", "astro", "vue", "typescriptreact" },
  },

  {
    "MaximilianLloyd/tw-values.nvim",
    keys = {
      { "<Leader>cv", "<CMD>TWValues<CR>", desc = "Tailwind CSS values" },
    },
    opts = {
      border = LeerVim.ui.float.border or "rounded", -- Valid window border style,
      show_unknown_classes = true                   -- Shows the unknown classes popup
    }
  },

  {
    "laytan/tailwind-sorter.nvim",
    cmd = {
      "TailwindSort",
      "TailwindSortOnSaveToggle"
    },
    keys = {
      { "<Leader>cS", "<CMD>TailwindSortOnSaveToggle<CR>", desc = "toggle Tailwind CSS classes sort on save" },

    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
    build = "cd formatter && npm i && npm run build",
    config = true,
  },

  {
    "axelvc/template-string.nvim",
    event = "InsertEnter",
    ft = {
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
    },
    config = true, -- run require("template-string").setup()
  },

  {
    "dmmulroy/tsc.nvim",
    cmd = { "TSC" },
    config = true,
  },

  {
    "dmmulroy/ts-error-translator.nvim",
    commit = "558abff11b9e8f4cefc0de09df780c56841c7a4b",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },
}
