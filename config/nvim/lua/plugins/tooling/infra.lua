return {
  -- ╭─────────────────────────────────────────────────────────╮
  -- │ Kubernetes interactive management                       │
  -- ╰─────────────────────────────────────────────────────────╯
  {
    "ramilito/kubectl.nvim",
    cmd = "Kubectl",
    keys = {
      { "<leader>K", function() require("kubectl").toggle() end, desc = "Kubectl: toggle" },
    },
    opts = {
      auto_refresh = {
        enabled = true,
        interval = 300,
      },
      hints = true,
      log_level = vim.log.levels.INFO,
      namespace = "All",
      notifications = {
        enabled = true,
        verbose = false,
        blend = 100,
      },
    },
  },

  -- ╭─────────────────────────────────────────────────────────╮
  -- │ Helm template filetype detection                        │
  -- │ Fixes yamlls misfiring on Go-template Helm files       │
  -- ╰─────────────────────────────────────────────────────────╯
  {
    "towolf/vim-helm",
    ft = { "helm" },
  },
}
