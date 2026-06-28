return {
  {
    "mistweaverco/kulala.nvim",
    commit = "6656c9d332735ca6a27725e0fb45a1715c4372d9",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "REST: send request", ft = { "http", "rest" } },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "REST: toggle body/headers", ft = { "http", "rest" } },
      { "<leader>Rp", function() require("kulala").jump_prev() end, desc = "REST: prev request", ft = { "http", "rest" } },
      { "<leader>Rn", function() require("kulala").jump_next() end, desc = "REST: next request", ft = { "http", "rest" } },
    },
    opts = { default_view = "body", default_env = "dev" },
  },
}
