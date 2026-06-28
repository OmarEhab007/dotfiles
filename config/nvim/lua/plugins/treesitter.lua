return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup()

      local ensure_installed = {
        "tsx",
        "typescript",
        "javascript",
        "html",
        "css",
        "vue",
        "astro",
        "svelte",
        "gitcommit",
        "graphql",
        "json",
        "json5",
        "lua",
        "markdown",
        "markdown_inline",
        "prisma",
        "vim",
        "vimdoc",
        "query",
        -- Infrastructure
        "dockerfile",
        "hcl",
        "toml",
        "helm",
        "bash",
        "ini",
      }

      -- Install/update parsers through the Neovim 0.12-compatible nvim-treesitter API.
      ts.install(ensure_installed)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end

          if vim.tbl_contains(ensure_installed, lang) and #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false) == 0 then
            ts.install({ lang })
          end

          pcall(vim.treesitter.start, args.buf, lang)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
    dependencies = {
      "hiphish/rainbow-delimiters.nvim",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
  },

  -- Textobjects - DISABLED: incompatible with new nvim-treesitter API
  -- TODO: Re-enable when nvim-treesitter-textobjects is updated
  -- See: https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    enabled = false,
  },

  -- Textsubjects - DISABLED: incompatible with new nvim-treesitter API
  -- TODO: Re-enable when nvim-treesitter-textsubjects is updated
  {
    "RRethy/nvim-treesitter-textsubjects",
    enabled = false,
  },

  {
    "windwp/nvim-ts-autotag",
    event = "BufReadPre",
    config = function()
      require('nvim-ts-autotag').setup({
        opts = {
          enable_close = false,          
          enable_rename = true,          
          enable_close_on_slash = true   
        },
      })
    end
  },

  {
    "wurli/contextindent.nvim",
    event = "BufReadPre",
    opts = { pattern = "*" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}

