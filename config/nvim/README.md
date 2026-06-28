# LeerVim

LeerVim is a Neovim configuration focused on frontend and full-stack development. It uses
Lua modules, Lazy.nvim plugin management, Snacks.nvim for the modern picker and explorer
workflow, strong LSP defaults, Git/GitHub tools, testing, debugging, formatting, linting,
and AI-assisted coding.

This README is the user guide for the configuration: installation, update workflow,
important files, installed tools, and the keymaps used to trigger the main workflows.

## Requirements

<details>
<summary><strong>Required and optional tools</strong></summary>

Install these tools before using the config.

| Tool | Why it is used |
| --- | --- |
| Neovim 0.10+ | Editor runtime |
| Git | Plugin installation, project workflow, Git integrations |
| Node.js and npm | JavaScript/TypeScript language tools and frontend projects |
| ripgrep (`rg`) | Fast text search used by pickers |
| fd | Fast file discovery used by pickers |
| lazygit | Terminal Git UI from inside Neovim |
| A Nerd Font | Icons in the UI |
| A C compiler | Required by some Treesitter parsers and native plugins |

Optional but recommended:

| Tool | Why it is useful |
| --- | --- |
| GitHub CLI (`gh`) | GitHub PR/issue workflow through Octo.nvim |
| Docker | Project-specific development environments |
| `prettier`, `eslint`, `stylua`, `goimports`, etc. | Project formatters and linters used through Conform and nvim-lint |

</details>

## Installation

Clone the repo into your Neovim config directory.

```sh
git clone https://github.com/OmarEhab007/nvim-config ~/.config/nvim
nvim
```

Lazy.nvim installs plugins automatically on the first start.

If you already have a Neovim config, back it up first:

```sh
mv ~/.config/nvim ~/.config/nvim.backup
git clone https://github.com/OmarEhab007/nvim-config ~/.config/nvim
```

## Updating

<details>
<summary><strong>Plugin updates and config sync workflow</strong></summary>

Update plugins from inside Neovim:

| Trigger | Action |
| --- | --- |
| `<leader>/i` | Open Lazy.nvim |
| `<leader>/u` | Update plugins with Lazy.nvim |

Update the config repo from the terminal:

```sh
cd ~/.config/nvim
git pull
```

If you keep your live config in `~/.config/nvim` and this repository in
`~/Developer/nvim-config`, use the shell helper:

```sh
sync-nvim-config
```

That copies the current live config into the repo, preserves `.git` and `.gitignore`, and
then shows `git status`.

</details>

## Project Layout

<details>
<summary><strong>Configuration file map</strong></summary>

| Path | Purpose |
| --- | --- |
| `init.lua` | Main entry point |
| `lua/config/LeerVim.lua` | Global LeerVim helpers and defaults |
| `lua/config/options.lua` | Editor options |
| `lua/config/keymappings.lua` | Global keymaps |
| `lua/config/autocmds.lua` | Autocommands |
| `lua/config/lazy.lua` | Lazy.nvim bootstrap and plugin loading |
| `lua/plugins/` | Plugin specs grouped by feature |
| `lua/plugins/which-key/setup.lua` | Which-key groups and many feature keymaps |
| `lazy-lock.json` | Locked plugin versions |

</details>

## Leader Keys

<details>
<summary><strong>Key notation guide</strong></summary>

| Key | Meaning |
| --- | --- |
| `<leader>` | Main command prefix |
| `<localleader>` | Buffer-local or plugin-local command prefix |
| `<C-x>` | Control + key |
| `<M-x>` | Alt/Meta + key |
| `<S-x>` | Shift + key |

Most commands are discoverable with which-key: press `<leader>` and pause.

</details>

## Main Plugins And Tools

<details>
<summary><strong>Core UI plugins and tools</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `folke/lazy.nvim` | Plugin manager |
| `folke/snacks.nvim` | Dashboard, explorer, picker, lazygit, notifier, terminal helpers, zen/zoom |
| `folke/which-key.nvim` | Keymap discovery |
| `akinsho/bufferline.nvim` | Buffer tabs |
| `nvim-lualine/lualine.nvim` | Statusline |
| `folke/noice.nvim` | Command line and message UI |
| `rcarriga/nvim-notify` | Notifications |
| `goolord/alpha-nvim` | Opening dashboard |
| `luukvbaal/statuscol.nvim` | Status column |
| `kevinhwang91/nvim-ufo` | Folding UI |

</details>

<details>
<summary><strong>Navigation and editing plugins</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `folke/flash.nvim` | Fast jump/search motions |
| `ThePrimeagen/harpoon` | Mark and jump between important files |
| `mrjones2014/smart-splits.nvim` | Resize and move between splits |
| `echasnovski/mini.ai` | Better text objects |
| `echasnovski/mini.align` | Alignment operator |
| `numToStr/Comment.nvim` | Comment toggling |
| `L3MON4D3/LuaSnip` | Snippets |
| `chrisgrieser/nvim-scissors` | Create and edit snippets |
| `Wansmer/treesj` | Split/join syntax nodes |
| `johmsalas/text-case.nvim` | Text case conversion |
| `andymass/vim-matchup` | Matching pairs and tags |

</details>

<details>
<summary><strong>LSP, completion, formatting, and linting tools</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `neovim/nvim-lspconfig` | Language server setup |
| `williamboman/mason.nvim` | External tool installer |
| `hrsh7th/nvim-cmp` | Completion engine |
| `hrsh7th/cmp-nvim-lsp` | LSP completion source |
| `stevearc/conform.nvim` | Formatting |
| `mfussenegger/nvim-lint` | Linting |
| `folke/trouble.nvim` | Diagnostics and references UI when enabled |
| `nvim-treesitter/nvim-treesitter` | Syntax tree parsing |

</details>

<details>
<summary><strong>Git and GitHub tools</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `lewis6991/gitsigns.nvim` | Hunk signs and hunk actions |
| `sindrets/diffview.nvim` | Git diff and file history UI |
| `akinsho/git-conflict.nvim` | Merge conflict helpers |
| `ThePrimeagen/git-worktree.nvim` | Worktree management |
| `pwntester/octo.nvim` | GitHub issues and pull requests |
| `lazygit` | Terminal Git UI |

</details>

<details>
<summary><strong>Frontend, TypeScript, and Markdown tools</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `pmizio/typescript-tools.nvim` | TypeScript language actions |
| `dmmulroy/tsc.nvim` | TypeScript compiler diagnostics |
| `luckasRanarison/tailwind-tools.nvim` | Tailwind CSS tools |
| `iamcco/markdown-preview.nvim` | Markdown preview |
| `nvim-neotest/neotest` | Test runner framework |
| Jest adapter | JavaScript/TypeScript tests |

</details>

<details>
<summary><strong>Debugging and AI tools</strong></summary>

| Plugin/tool | Purpose |
| --- | --- |
| `mfussenegger/nvim-dap` | Debug Adapter Protocol |
| `rcarriga/nvim-dap-ui` | Debug UI |
| `zbirenbaum/copilot.lua` | GitHub Copilot completion |
| `CopilotC-Nvim/CopilotChat.nvim` | Copilot chat actions |
| `olimorris/codecompanion.nvim` | CodeCompanion chat and inline actions |

</details>

## Daily Workflow

<details>
<summary><strong>Open a project workflow</strong></summary>

Start Neovim from the project root:

```sh
cd path/to/project
nvim
```

Use the dashboard, picker, or explorer to enter the project:

| Trigger | Action |
| --- | --- |
| `<leader>//` | Open dashboard |
| `<C-e>` | Open Snacks explorer |
| `<C-p>` | Find files intelligently |
| `<S-p>` | Search text in project |
| `<leader>pl` | Open project list |

Hidden files and gitignored files are enabled in the Snacks picker and explorer by default.

</details>

<details>
<summary><strong>Edit code workflow</strong></summary>

| Trigger | Action |
| --- | --- |
| `<C-s>` | Save from normal or insert mode |
| `<leader>f` | Format current file or visual selection |
| `<leader>l` | Lint current file |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | LSP format current buffer or visual range |
| `<leader>ct` | Toggle format-on-save |

</details>

<details>
<summary><strong>Search and navigation workflow</strong></summary>

| Trigger | Action |
| --- | --- |
| `<C-p>` | Smart file picker |
| `<S-p>` | Grep project |
| `<leader>pw` | Grep word under cursor or visual selection |
| `<leader>sf` | Find files |
| `<leader>sb` | Pick open buffers |
| `<leader>sh` | Recent files |
| `<leader>sH` | Command history |
| `<leader>ss` | Search history |
| `<leader>sq` | Quickfix picker |
| `<leader>sc` | Colorscheme picker |
| `<leader>sd` | Dotfiles picker |

</details>

<details>
<summary><strong>Git workflow</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>gg` | Open Lazygit |
| `<leader>gla` | Lazygit log for current working directory |
| `<leader>glc` | Lazygit history for current file |
| `<leader>ga` | Git add current file |
| `<leader>gA` | Git add all files |
| `<leader>gb` | Toggle Git blame window |
| `<leader>gd` | Open Diffview file history |
| `<leader>gS` | Open Diffview status |
| `<leader>gi` | List GitHub issues |
| `<leader>gp` | List GitHub pull requests |

</details>

## Keymap Reference

<details>
<summary><strong>General editing keymaps</strong></summary>

| Mode | Trigger | Action |
| --- | --- | --- |
| Normal | `<C-s>` | Save file |
| Insert | `<C-s>` | Save file and return to normal mode |
| Normal | `<CR>` | Clear search highlights |
| Normal | `H` | Move to first non-blank character |
| Normal | `gx` | Open URL under cursor in browser |
| Normal | `<M-=>` | Increase GUI font size |
| Normal | `<M-->` | Decrease GUI font size |
| Visual | `J` | Move selected lines down |
| Visual | `K` | Move selected lines up |
| Visual | `<` | Indent left and keep selection |
| Visual | `>` | Indent right and keep selection |
| Visual | `` ` `` | Lowercase selection |
| Visual | `<M-`>` | Uppercase selection |
| Normal/Visual | `x` | Delete without yanking |
| Normal/Visual | `X` | Delete without yanking |
| Visual | `p` | Paste without yanking replaced text |

</details>

<details>
<summary><strong>Window and split keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>v` | Split right |
| `<leader>V` | Split below |
| `<leader>=` | Increase vertical split width |
| `<leader>-` | Decrease vertical split width |
| `<C-h>` | Move to left split |
| `<C-j>` | Move to lower split |
| `<C-k>` | Move to upper split |
| `<C-l>` | Move to right split |
| `<C-\>` | Move to previous split |
| `<M-h>` | Resize split left |
| `<M-j>` | Resize split down |
| `<M-k>` | Resize split up |
| `<M-l>` | Resize split right |
| `<leader><leader>h` | Swap buffer left |
| `<leader><leader>j` | Swap buffer down |
| `<leader><leader>k` | Swap buffer up |
| `<leader><leader>l` | Swap buffer right |

</details>

<details>
<summary><strong>Buffer keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<Tab>` | Next buffer |
| `gn` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `gp` | Previous buffer |
| `<S-q>` | Close current buffer |
| `<leader>bc` | Close all buffers except current |
| `<leader>bf` | Go to first buffer |
| `<leader>bb` | Move current buffer backward |
| `<leader>bn` | Move current buffer forward |
| `<leader>bp` | Pick buffer |
| `<leader>bP` | Pin or unpin buffer |
| `<leader>bl` | Close buffers to the left |
| `<leader>br` | Close buffers to the right |
| `<leader>bsd` | Sort buffers by directory |
| `<leader>bse` | Sort buffers by extension |
| `<leader>bsr` | Sort buffers by relative directory |

</details>

<details>
<summary><strong>Explorer and picker keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<C-e>` | Open Snacks explorer |
| `<C-p>` | Smart file picker |
| `<S-p>` | Project grep |
| `<leader>sf` | File picker |
| `<leader>sb` | Buffer picker |
| `<leader>sh` | Recent files picker |
| `<leader>pw` | Grep word or selection |
| `<leader>pl` | Projects picker |
| `<leader>cd` | Diagnostics picker |
| `<leader>gf` | Git files picker |
| `<leader>gs` | Git status picker |
| `<leader>glA` | Git log picker |
| `<leader>glC` | Git file commits picker |
| Explorer: `H` | Toggle hidden files |
| Explorer: `I` | Toggle ignored files |
| Explorer: `<C-]>` | Change explorer root to selected directory |

</details>

<details>
<summary><strong>Quickfix keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>,` | Previous quickfix item |
| `<leader>.` | Next quickfix item |
| `<leader>q` | Toggle quickfix list |
| `<leader>sq` | Open quickfix picker |

</details>

<details>
<summary><strong>LSP and diagnostics keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | Find references |
| `gy` | Go to type definition |
| `K` | Hover documentation, or peek folded lines |
| `L` | Signature help |
| `<C-Space>` | Code action |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | Format buffer or visual range |
| `<leader>cl` | Show line diagnostics |
| `gl` | Show line diagnostics |
| `]g` | Next diagnostic |
| `[g` | Previous diagnostic |
| `<leader>cR` | Restart LSP |
| `<leader>ct` | Toggle format-on-save |

</details>

<details>
<summary><strong>Git hunk keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `]c` | Next Git hunk |
| `[c` | Previous Git hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghS` | Stage buffer |
| `<leader>ghu` | Undo stage hunk |
| `<leader>ghR` | Reset buffer |
| `<leader>ghp` | Preview hunk |
| `<leader>gm` | Blame current line |
| `<leader>ghd` | Diff current hunk |
| `<leader>ght` | Toggle deleted lines |
| `ih` | Select hunk text object |

</details>

<details>
<summary><strong>Git conflict and worktree keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>gcn` | Next conflict |
| `<leader>gcp` | Previous conflict |
| `<leader>gcc` | Choose current/ours |
| `<leader>gci` | Choose incoming/theirs |
| `<leader>gcb` | Choose both |
| `<leader>gww` | List worktrees |
| `<leader>gwc` | Create worktree |

</details>

<details>
<summary><strong>Harpoon keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>H` | Add current file to Harpoon |
| `<leader>h` | Open Harpoon menu |
| `<leader>1` | Open Harpoon item 1 |
| `<leader>2` | Open Harpoon item 2 |
| `<leader>3` | Open Harpoon item 3 |
| `<leader>4` | Open Harpoon item 4 |
| `<leader>[` | Previous Harpoon item |
| `<leader>]` | Next Harpoon item |

</details>

<details>
<summary><strong>Motion and text object keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `s` | Flash jump |
| Operator `r` | Remote Flash |
| `gcc` | Toggle line comment |
| `gc` | Toggle comment operator or visual selection |
| `gco` | Add comment below |
| `gcO` | Add comment above |
| `ga` | Align with mini.align |
| `gu...` | Convert text case with text-case.nvim |
| `guo...` | Text-case operator |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `za` | Toggle fold under cursor |

Mini.ai also adds enhanced text objects such as quotes, brackets, functions, arguments,
and surrounding syntax-aware selections.

</details>

<details>
<summary><strong>Refactoring keymaps</strong></summary>

| Mode | Trigger | Action |
| --- | --- | --- |
| Visual | `<leader>re` | Extract function |
| Visual | `<leader>rf` | Extract function to file |
| Visual | `<leader>rv` | Extract variable |
| Visual/Normal | `<leader>ri` | Inline variable |
| Normal | `<leader>rI` | Inline function |
| Normal | `<leader>rb` | Extract block |
| Normal | `<leader>rf` | Extract block to file |

</details>

<details>
<summary><strong>TypeScript and Tailwind keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>ce` | Show TypeScript workspace errors |
| `<leader>ci` | Add missing imports |
| `<leader>co` | Organize imports |
| `<leader>cs` | Sort imports |
| `<leader>cu` | Remove unused declarations |
| `<leader>cR` | Rename file and update imports |
| `<leader>cv` | Show Tailwind CSS values |
| `<leader>cS` | Toggle Tailwind class sorting on save |

</details>

<details>
<summary><strong>NPM package buffer keymaps</strong></summary>

These mappings apply in package management buffers.

| Trigger | Action |
| --- | --- |
| `<leader>nc` | Change package version |
| `<leader>nd` | Delete package |
| `<leader>nh` | Hide package info |
| `<leader>ni` | Install new package |
| `<leader>nr` | Reinstall dependencies |
| `<leader>ns` | Show package info |
| `<leader>nu` | Update package |

</details>

<details>
<summary><strong>Test keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>jf` | Run current test file |
| `<leader>jj` | Run nearest test |
| `<leader>jl` | Run last test |
| `<leader>ji` | Toggle test summary/info |
| `<leader>jo` | Open test output |
| `<leader>js` | Stop running test |

</details>

<details>
<summary><strong>Debugging keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>da` | Continue debugging |
| `<leader>dd` | Continue debugging |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint |
| `<leader>di` | Step into |
| `<leader>do` | Step out |
| `<leader>dO` | Step over |
| `<leader>dt` | Terminate debug session |
| `<leader>du` | Open DAP UI |
| `<leader>dc` | Close DAP UI |
| `<leader>dh` | Evaluate expression |
| `<leader>dw` | Open watches |
| `<leader>ds` | Open scopes |
| `<leader>dr` | Open REPL |

</details>

<details>
<summary><strong>Snippet keymaps</strong></summary>

| Mode | Trigger | Action |
| --- | --- | --- |
| Normal | `<leader>asa` | Add new snippet |
| Visual | `<leader>asa` | Add snippet from selection |
| Normal | `<leader>ase` | Edit snippet |

</details>

<details>
<summary><strong>Markdown keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>am` | Toggle Markdown preview |

</details>

<details>
<summary><strong>AI keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>ccl` | CodeCompanion inline action |
| `<leader>ccc` | AI chat action |
| `<leader>cce` | Explain code with Copilot Chat |
| `<leader>cct` | Generate tests with Copilot Chat |
| `<leader>ccf` | Fix diagnostic with Copilot Chat |
| Insert `<C-w>` | Accept Copilot word |
| Insert `<C-l>` | Accept Copilot line |
| Insert `<C-j>` | Next Copilot suggestion |
| Insert `<C-k>` | Previous Copilot suggestion |

Note: `<leader>ccc` is currently configured by both CodeCompanion and Copilot Chat. The
effective command depends on plugin load order.

</details>

<details>
<summary><strong>LeerVim and UI action keymaps</strong></summary>

| Trigger | Action |
| --- | --- |
| `<leader>//` | Open dashboard |
| `<leader>/c` | Open LeerVim config |
| `<leader>/i` | Open Lazy.nvim |
| `<leader>/u` | Update plugins |
| `<leader>an` | Toggle absolute line numbers |
| `<leader>ar` | Toggle relative line numbers |
| `<leader>ac` | Create a comment box |
| `<leader>z` | Toggle Zen mode |
| `<leader>Z` | Toggle Zoom mode |

</details>

## Common Commands

<details>
<summary><strong>Useful Neovim commands</strong></summary>

| Command | Purpose |
| --- | --- |
| `:Lazy` | Open plugin manager |
| `:Lazy update` | Update plugins |
| `:Mason` | Install and manage external language tools |
| `:checkhealth` | Diagnose Neovim/plugin/provider issues |
| `:ConformInfo` | Inspect formatter setup |
| `:LspInfo` | Inspect active language servers |
| `:Telescope` | Open Telescope commands if needed |

</details>

## Customization

<details>
<summary><strong>Files to edit when customizing LeerVim</strong></summary>

Start with these files:

| File | What to change |
| --- | --- |
| `lua/config/options.lua` | Editor behavior |
| `lua/config/keymappings.lua` | Global mappings |
| `lua/plugins/which-key/setup.lua` | Leader groups and feature mappings |
| `lua/plugins/snacks.lua` | Dashboard, picker, explorer, lazygit, zen |
| `lua/plugins/lsp.lua` | Language server behavior |
| `lua/plugins/formatting.lua` | Formatters |
| `lua/plugins/linting.lua` | Linters |
| `lua/plugins/languages/` | Language-specific tooling |

After changing plugins, restart Neovim and run:

```vim
:Lazy sync
```

After changing language tools, run:

```vim
:Mason
```

</details>

## Troubleshooting

<details>
<summary><strong>Common problems and fixes</strong></summary>

| Problem | Fix |
| --- | --- |
| Plugins do not install | Run `:Lazy sync`, then restart Neovim |
| LSP does not attach | Run `:LspInfo` and `:Mason`; install the missing server |
| Formatter does not run | Run `:ConformInfo` and check project config files |
| Search is empty or slow | Install `ripgrep` and `fd` |
| Icons look broken | Use a Nerd Font in the terminal |
| GitHub PRs/issues do not load | Install and authenticate `gh` |
| Hidden or ignored files are missing | In Snacks explorer press `H` for hidden files or `I` for ignored files |

</details>

## Maintenance Checklist

Use this when changing the configuration.

1. Edit the config in `~/.config/nvim`.
2. Start Neovim and check for startup errors.
3. Run `:Lazy sync` if plugins changed.
4. Run `sync-nvim-config` to copy the live config into the repo.
5. Review `git diff`.
6. Commit and push the repo.

Headless startup check:

```sh
nvim --headless '+qa'
```

Repo config startup check:

```sh
XDG_CONFIG_HOME=~/Developer NVIM_APPNAME=nvim-config nvim --headless '+qa'
```
