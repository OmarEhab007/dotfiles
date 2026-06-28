return {
  { "mfussenegger/nvim-jdtls", commit = "77ccaeb422f8c81b647605da5ddb4a7f725cda90", ft = "java" },
  {
    "JavaHello/spring-boot.nvim",
    commit = "98c6ff1dcdda943d341bba3c00ae9d190a2e5f7d",
    ft = "java",
    dependencies = { "mfussenegger/nvim-jdtls" },
    opts = {},
  },
  {
    "rcasia/neotest-java",
    commit = "9555068794cc08512354656089485e61ce706de6",
    ft = "java",
    dependencies = { "nvim-neotest/neotest", "mfussenegger/nvim-jdtls" },
  },
}
