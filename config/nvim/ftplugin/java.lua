local ok, jdtls = pcall(require, "jdtls")
if not ok then return end

local cfgmod = require("config.lsp.servers.jdtls")
local mason = vim.fn.stdpath("data") .. "/mason/packages"

local root = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
if not root then return end
local project = vim.fn.fnamemodify(root, ":p:h:t")
local workspace = vim.fn.expand("~/.cache/jdtls/workspace/") .. project

local cmd = { vim.fn.stdpath("data") .. "/mason/bin/jdtls", "-data", workspace }
local lombok = cfgmod.lombok_javaagent()
if lombok then table.insert(cmd, lombok) end

local config = {
  cmd = cmd,
  root_dir = root,
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  init_options = { bundles = cfgmod.bundles() },
  settings = {
    java = {
      configuration = { runtimes = cfgmod.runtimes },
      import = { gradle = { wrapper = { enabled = true } }, maven = { enabled = true } },
      format = { enabled = false },
      inlayHints = { parameterNames = { enabled = "all" } },
    },
  },
  on_attach = function(_, bufnr)
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    jdtls.setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()
    local dap = require("dap")
    dap.configurations.java = dap.configurations.java or {}
    table.insert(dap.configurations.java, {
      type = "java", request = "attach", name = "Spring Boot: attach (jdwp :5005)",
      hostName = "127.0.0.1", port = 5005,
    })
  end,
}

jdtls.start_or_attach(config)
