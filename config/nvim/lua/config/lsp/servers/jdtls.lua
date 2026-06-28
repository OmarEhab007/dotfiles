local M = {}

local mason = vim.fn.stdpath("data") .. "/mason/packages"

local function jdk(home) return vim.fn.isdirectory(home) == 1 and home or nil end

M.runtimes = (function()
  local r = {}
  local map = {
    ["JavaSE-17"] = "/opt/homebrew/Cellar/openjdk@17/17.0.19/libexec/openjdk.jdk/Contents/Home",
    ["JavaSE-21"] = "/opt/homebrew/Cellar/openjdk@21/21.0.11/libexec/openjdk.jdk/Contents/Home",
    ["JavaSE-23"] = vim.fn.expand("~/Library/Java/JavaVirtualMachines/openjdk-23.0.2/Contents/Home"),
  }
  for name, home in pairs(map) do
    if jdk(home) then
      r[#r + 1] = { name = name, path = home, default = (name == "JavaSE-21") or nil }
    end
  end
  return r
end)()

function M.bundles()
  local b = {}
  vim.list_extend(b, vim.split(
    vim.fn.glob(mason .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
    "\n", { trimempty = true }))
  for _, jar in ipairs(vim.split(
    vim.fn.glob(mason .. "/java-test/extension/server/*.jar", true), "\n", { trimempty = true })) do
    if not jar:match("com.microsoft.java.test.runner%-jar%-with%-dependencies.jar")
      and not jar:match("jacocoagent.jar") then
      b[#b + 1] = jar
    end
  end
  local ok, springboot = pcall(require, "spring_boot")
  if ok then vim.list_extend(b, springboot.java_extensions()) end
  return b
end

function M.lombok_javaagent()
  local jar = mason .. "/jdtls/lombok.jar"
  return vim.fn.filereadable(jar) == 1 and ("--jvm-arg=-javaagent:" .. jar) or nil
end

return M
