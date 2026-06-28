-- DEAD CODE / FALLBACK ONLY: typescript-tools.nvim settings, kept for reference.
-- The active TypeScript server is vtsls (see lua/config/lsp/servers/vtsls.lua and
-- the vim.lsp.config("vtsls", ...) block in lua/config/lsp/setup.lua). Revert
-- instructions: lua/config/lsp/servers/_tsserver-typescript-tools.bak.lua.
local M = {}

local filter = require("config.lsp.utils.filter").filter
local filterReactDTS = require("config.lsp.utils.filterReactDTS").filterReactDTS

-- Local replacement for vim.lsp.with(), which was removed in Nvim 0.12.
local function with(handler, override_config)
  return function(err, result, ctx, config)
    return handler(err, result, ctx, vim.tbl_deep_extend("force", config or {}, override_config))
  end
end

local handlers = {
  ["textDocument/hover"] = with(vim.lsp.handlers.hover, {
    silent = true,
    border = LeerVim.ui.float.border or "rounded",
  }),
  ["textDocument/signatureHelp"] = with(
    vim.lsp.handlers.signature_help, {
      border = LeerVim.ui.float.border or "rounded",
    }
  ),
  ["textDocument/publishDiagnostics"] = with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    { virtual_text = true }
  ),
  ["textDocument/definition"] = function(err, result, method, ...)
    if vim.tbl_islist(result) and #result > 1 then
      local filtered_result = filter(result, filterReactDTS)
      return vim.lsp.handlers["textDocument/definition"](err, filtered_result, method, ...)
    end

    vim.lsp.handlers["textDocument/definition"](err, result, method, ...)
  end,
}


local settings = {
  -- Performance settings
  separate_diagnostic_server = true,
  publish_diagnostic_on = "insert_leave",
  tsserver_max_memory = "auto",

  -- Formatting preferences (from default_format_options)
  tsserver_format_options = {
    insertSpaceAfterCommaDelimiter = true,
    insertSpaceAfterConstructor = false,
    insertSpaceAfterSemicolonInForStatements = true,
    insertSpaceBeforeAndAfterBinaryOperators = true,
    insertSpaceAfterKeywordsInControlFlowStatements = true,
    insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
    insertSpaceBeforeFunctionParenthesis = false,
    insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
    insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
    insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
    insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = true,
    insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
    insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
    insertSpaceAfterTypeAssertion = false,
    placeOpenBraceOnNewLineForFunctions = false,
    placeOpenBraceOnNewLineForControlBlocks = false,
    semicolons = "ignore",
    indentSwitchCase = true,
  },

  -- File preferences (combining your inlay hints with default preferences)
  tsserver_file_preferences = {
    -- Your current inlay hint settings
    includeInlayParameterNameHints = "all",
    includeInlayParameterNameHintsWhenArgumentMatchesName = true,
    includeInlayFunctionParameterTypeHints = true,
    includeInlayVariableTypeHints = false,
    includeInlayVariableTypeHintsWhenTypeMatchesName = false,
    includeInlayPropertyDeclarationTypeHints = false,
    includeInlayFunctionLikeReturnTypeHints = false,
    includeInlayEnumMemberValueHints = true,

    -- Important default preferences
    quotePreference = "auto",
    importModuleSpecifierEnding = "auto",
    jsxAttributeCompletionStyle = "auto",
    allowTextChangesInNewFiles = true,
    providePrefixAndSuffixTextForRename = true,
    allowRenameOfImportPath = true,
    includeAutomaticOptionalChainCompletions = true,
    provideRefactorNotApplicableReason = true,
    generateReturnInDocTemplate = true,
    includeCompletionsForImportStatements = true,
    includeCompletionsWithSnippetText = true,
    includeCompletionsWithClassMemberSnippets = true,
    includeCompletionsWithObjectLiteralMethodSnippets = true,
    useLabelDetailsInCompletionEntries = true,
    allowIncompleteCompletions = true,
    displayPartsForJSDoc = true,
    disableLineTextInReferences = true,
  },

  -- Feature settings
  expose_as_code_action = "all",
  complete_function_calls = false,
  include_completions_with_insert_text = true,
  code_lens = "implementations_only",
}

local on_attach = function(client, bufnr)
  vim.lsp.inlay_hint.enable(true, { bufnr })
  require("plugins.which-key.setup").attach_typescript(bufnr)
end

M.handlers = handlers
M.settings = settings
M.on_attach = on_attach

return M
