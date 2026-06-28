local snippet_trigger_text = ";"

return {
  {
    'saghen/blink.cmp',
    lazy = false, -- lazy loading handled internally
    -- CHANGE: Use v0.* to download pre-built binaries instead of building from source
    version = "v0.*", 
    dependencies = {
      {
        "saghen/blink.compat",
        opts = { impersonate_nvim_cmp = true },
      },
      "rafamadriz/friendly-snippets",
      "fang2hou/blink-copilot",
      -- "David-Kunz/cmp-npm",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        -- OPTIONAL: If this still fails (from your previous error), comment this line out:
        build = "make install_jsregexp",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
        end,
      },
    },

    -- CHANGE: Comment out or remove the build command to avoid the Rust nightly error
    -- build = 'cargo build --release',

    ---@module 'blink.cmp'
    opts = {
      -- ... (rest of your configuration remains the same)
      keymap = {
        preset = 'super-tab',
        ["<S-k>"] = { "scroll_documentation_up", "fallback" },
        ["<S-j>"] = { "scroll_documentation_down", "fallback" }
      },

      snippets = {
        preset = 'luasnip',
        expand = function(snippet) require('luasnip').lsp_expand(snippet) end,
        active = function(filter)
          if filter and filter.direction then
            return require('luasnip').jumpable(filter.direction)
          end
          return require('luasnip').in_snippet()
        end,
        jump = function(direction) require('luasnip').jump(direction) end,
      },

      sources = {
        default = {
          'lsp',
          'path',
          'snippets',
          'buffer',
          'codecompanion',
          'copilot',
        },
        
        -- FIX: Ensure cmdline is properly configured (from previous fix)
        providers = {
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
          },
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            opts = {
              max_completions = 3,
              max_attempts = 4,
            },
            score_offset = 100,
            async = true,
            transform_items = function(_, items)
              local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Copilot"
              for _, item in ipairs(items) do
                item.kind = kind_idx
              end
              return items
            end,
          },
        }
      },
      
      -- Moved cmdline config here as per recent blink.cmp updates
      cmdline = {
        sources = function() return { 'cmdline' } end
      },

      completion = {
        trigger = {
          show_on_trigger_character = true,
          show_on_insert_on_trigger_character = true,
          show_on_x_blocked_trigger_characters = { "'", '"', '(', '{' },
        },
        menu = {
          border = LeerVim.ui.float.border,
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
            treesitter = {},
          },
        },
        accept = {
          auto_brackets = { enabled = false },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          treesitter_highlighting = true,
          window = {
            border = LeerVim.ui.float.border,
          }
        },
        ghost_text = {
          enabled = true,
        },
      },

      signature = {
        enabled = true,
        window = {
          border = LeerVim.ui.float.border,
        }
      },
    },
    opts_extend = { "sources.default" },
    appearance = {
      kind_icons = {
        Copilot = "",
        Text = '󰉿',
        Method = '󰊕',
        Function = '󰊕',
        Constructor = '󰒓',
        Field = '󰜢',
        Variable = '󰆦',
        Property = '󰖷',
        Class = '󱡠',
        Interface = '󱡠',
        Struct = '󱡠',
        Module = '󰅩',
        Unit = '󰪚',
        Value = '󰦨',
        Enum = '󰦨',
        EnumMember = '󰦨',
        Keyword = '󰻾',
        Constant = '󰏿',
        Snippet = '󱄽',
        Color = '󰏘',
        File = '󰈔',
        Reference = '󰬲',
        Folder = '󰉋',
        Event = '󱐋',
        Operator = '󰪚',
        TypeParameter = '󰬛',
      },
    },
  },
}
