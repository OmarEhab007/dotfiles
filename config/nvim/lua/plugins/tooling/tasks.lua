return {
  {
    "stevearc/overseer.nvim",
    commit = "3d0c7e7bbfe1a1c6f9bfecd0af8709171a97df71",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerQuickAction", "OverseerRunCmd" },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: run task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer: toggle panel" },
    },
    opts = {
      strategy = "terminal",
      templates = { "builtin" },
    },
  },
}
