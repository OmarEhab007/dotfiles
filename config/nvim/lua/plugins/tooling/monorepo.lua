return {
  {
    "imNel/monorepo.nvim",
    commit = "256a302900d6af6e032f1f2bf4f2407bd4569fe8",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = { { "<leader>fm", "<cmd>Telescope monorepo<cr>", desc = "Monorepo: switch sub-root" } },
    config = function()
      require("monorepo").setup({ silent = false })
      require("telescope").load_extension("monorepo")
    end,
  },
}
