-- cSpell:disable

if vim.o.compatible then
  vim.o.compatible = false
end

-- Leaderを<space>に設定
vim.g.mapleader = ' '

-- lazy.nvim Init
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Vim内で利用するシェルを明示的にZshに変更 (PATH から解決して環境差異を吸収)
local zsh_path = vim.fn.exepath('zsh')
if zsh_path ~= '' then
  vim.o.shell = zsh_path
  vim.env.SHELL = zsh_path
end

-- Plugins
require("lazy").setup({
  -- Completion and Language Server
  {
    "neoclide/coc.nvim",
    branch = "release",
    init = function()
      -- 起動時に未インストール拡張を自動インストールさせる
      vim.g.coc_global_extensions = {
        -- Web frontend
        'coc-tsserver',
        'coc-eslint',
        'coc-prettier',
        'coc-json',
        'coc-html',
        'coc-css',
        -- UI / 補助
        'coc-explorer',
        'coc-pairs',
        'coc-snippets',
        'coc-spell-checker',
        'coc-marketplace',
        -- その他言語
        'coc-pyright',
        'coc-rust-analyzer',
        'coc-go',
      }
    end,
    config = function()
      vim.g.coc_node_path = vim.fn.exepath('node')
    end
  },

  -- nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate"
  },

  -- File search and fuzzy finder (fzf binary comes from Nix; skip plugin's installer)
  "junegunn/fzf",

  -- Language support
  "sheerun/vim-polyglot",
  "pantharshit00/vim-prisma",

  -- Status line
  "vim-airline/vim-airline",
  "vim-airline/vim-airline-themes",

  -- Git integration
  "airblade/vim-gitgutter",

  -- Color schemes
  "rcarriga/nvim-notify",
  "bluz71/vim-moonfly-colors",
  "beikome/cosme.vim",

  -- oklch color display & picker
  {
    "eero-lehtinen/oklch-color-picker.nvim",
    event = "VeryLazy",
    version = "*",
    keys = {
      -- One handed keymap recommended, you will be using the mouse
      {
        "<leader>v",
        function() require("oklch-color-picker").pick_under_cursor() end,
        desc = "Color pick under cursor",
      },
    },
    ---@type oklch.Opts
    opts = {},
  },

  -- Display buffers as tabs
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      vim.opt.termguicolors = true
      require("bufferline").setup {}
    end
  },

  -- Navigation
  {
    "smoka7/hop.nvim",
    config = function()
      require('hop').setup()
    end
  },

  -- AI assistance
  "github/copilot.vim",

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npx --yes yarn install"
  },

  -- Telescope and dependencies
  "nvim-lua/plenary.nvim",
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "fannheyward/telescope-coc.nvim",
    },
    config = function()
      require('telescope').setup({
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = false,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
        defaults = {
          layout_config = {
            prompt_position = "top",
            preview_width = 0.6,
          },
        }
      })
      require('telescope').load_extension('fzf')
      require('telescope').load_extension('coc')
    end
  },
  -- Laravel support
  {
    "yaegassy/coc-laravel",
    build = "npx --yes yarn install --frozen-lockfile"
  },

  -- Claude Code
  "folke/snacks.nvim",
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    lazy = false,
    config = true,
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.35,
        provider = "auto", -- "auto", "snacks", "native", "external", or custom provider table
      }
    },
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" }
    },
  }
})

-- Create :CC command as alias for :ClaudeCode
vim.api.nvim_create_user_command('CC', 'ClaudeCode', { nargs = 0 })
vim.api.nvim_create_user_command('CCC', 'ClaudeCode --continue', { nargs = 0 })
vim.api.nvim_create_user_command('CCR', 'ClaudeCode --resume', { nargs = 0 })

-- Color scheme
vim.cmd('syntax on')
vim.cmd('colorscheme cosme')

-- 背景色を透過する
vim.cmd([[
  highlight Normal guibg=none
  highlight Normal ctermbg=none
  highlight NonText guibg=none
  highlight NonText ctermbg=none
  highlight LineNr guibg=none
  highlight LineNr ctermbg=none
  highlight Folded guibg=none
  highlight Folded ctermbg=none
  highlight EndOfBuffer guibg=none
  highlight EndOfBuffer ctermbg=none
]])

-- Settings
-- バックアップファイルを作らない
vim.o.backup = false
-- スワップファイルを作らない
vim.o.swapfile = false
-- 編集中のファイルが変更されたら自動で読み直す
vim.o.autoread = true
-- バッファが編集中でもその他のファイルを開けるように
vim.o.hidden = true
-- 入力中のコマンドをステータスに表示する
vim.o.showcmd = true
-- 折り返さない
vim.o.wrap = false

-- 通常のyank / pasteでClipboardを有効にする
if vim.fn.has('mac') == 1 then
  vim.o.clipboard = 'unnamed'
elseif vim.fn.has('unix') == 1 then
  vim.o.clipboard = 'unnamedplus'
end

-- 見た目系
-- 行番号を表示
vim.o.number = true
-- 現在の行を強調表示
vim.o.cursorline = true
-- 行末の1文字先までカーソルを移動できるように
vim.o.virtualedit = 'onemore'
-- インデントはスマートインデント
vim.o.smartindent = true
-- 括弧入力時の対応する括弧を表示
vim.o.showmatch = true
-- ステータスラインを常に表示
vim.o.laststatus = 2
-- コマンドラインの補完
vim.o.wildmode = 'list:longest'
-- シンタックスハイライトの有効化
vim.cmd('syntax enable')

-- Tab系
vim.o.list = true
vim.o.listchars = 'tab:▸-'
-- Tab文字を半角スペースにする
vim.o.expandtab = true
-- 行頭以外のTab文字の表示幅（スペースいくつ分）
vim.o.tabstop = 2
-- 行頭でのTab文字の表示幅
vim.o.shiftwidth = 2

-- 検索系
-- 検索文字列が小文字の場合は大文字小文字を区別なく検索する
vim.o.ignorecase = true
-- 検索文字列に大文字が含まれている場合は区別して検索する
vim.o.smartcase = true
-- 検索文字列入力時に順次対象文字列にヒットさせる
vim.o.incsearch = true
-- 検索時に最後まで行ったら最初に戻る
vim.o.wrapscan = true
-- 検索語をハイライト表示
vim.o.hlsearch = true

-- マウス系
vim.o.mouse = 'a'

-- Key mappings
-- 折り返し時に表示行単位での移動できるようにする
vim.keymap.set('n', 'j', 'gj', { noremap = true })
vim.keymap.set('n', 'k', 'gk', { noremap = true })

-- ESC連打でハイライト解除
vim.keymap.set('n', '<Esc><Esc>', ':nohlsearch<CR><Esc>', { noremap = true })

-- Disable Arrow Keys
vim.keymap.set('', '<Up>', '<Nop>', { noremap = true })
vim.keymap.set('', '<Down>', '<Nop>', { noremap = true })
vim.keymap.set('', '<Left>', '<Nop>', { noremap = true })
vim.keymap.set('', '<Right>', '<Nop>', { noremap = true })

-- Allow jj to escape insert mode
vim.keymap.set('i', 'jj', '<ESC>', { noremap = true, silent = true })

-- Hで行頭, Lで行末へ
vim.keymap.set('n', 'H', '^', { noremap = true })
vim.keymap.set('n', 'L', '$', { noremap = true })

-- Ctrl + hjkl でウィンドウ間を移動
vim.keymap.set('n', '<C-h>', '<C-w>h', { noremap = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { noremap = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { noremap = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { noremap = true })

-- Commands
-- :Format でフォーマッタ実行
vim.api.nvim_create_user_command('Format', function()
  vim.fn.CocAction('format')
end, { nargs = 0 })

-- <leader> + iでも実行
vim.keymap.set('n', '<leader>i', ':Format<CR>', { noremap = true })

-- :LintfixでESLintの自動修正
vim.api.nvim_create_user_command('Lintfix', function()
  vim.fn.CocCommand('eslint.executeAutofix')
end, { nargs = 0 })

-- Filetype settings
local function set_filetype_options(pattern, sw, sts, ts, et)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = pattern,
    callback = function()
      vim.bo.shiftwidth = sw
      vim.bo.softtabstop = sts
      vim.bo.tabstop = ts
      vim.bo.expandtab = et
    end
  })
end

-- Enable filetype detection
vim.cmd('filetype plugin on')
vim.cmd('filetype indent on')

-- Set filetype-specific indentation
set_filetype_options('markdown', 4, 4, 4, true)
set_filetype_options('apache', 4, 4, 4, true)
set_filetype_options('aspvbs', 4, 4, 4, true)
set_filetype_options('c', 4, 4, 4, true)
set_filetype_options('cpp', 4, 4, 4, true)
set_filetype_options('cs', 4, 4, 4, true)
set_filetype_options('css', 2, 2, 2, true)
set_filetype_options('diff', 4, 4, 4, true)
set_filetype_options('go', 2, 2, 2, true)
set_filetype_options('eruby', 4, 4, 4, true)
set_filetype_options('html', 2, 2, 2, true)
set_filetype_options('java', 4, 4, 4, true)
set_filetype_options('javascript', 2, 2, 2, true)
set_filetype_options('json', 2, 2, 2, true)
set_filetype_options('typescript', 2, 2, 2, true)
set_filetype_options('typescriptreact', 2, 2, 2, true)
set_filetype_options('vue', 2, 2, 2, true)
set_filetype_options('perl', 4, 4, 4, true)
set_filetype_options('php', 2, 2, 2, true)
set_filetype_options('python', 4, 4, 4, true)
set_filetype_options('ruby', 2, 2, 2, true)
set_filetype_options('haml', 2, 2, 2, true)
set_filetype_options('sh', 4, 4, 4, true)
set_filetype_options('sql', 4, 4, 4, true)
set_filetype_options('vb', 4, 4, 4, true)
set_filetype_options('vim', 2, 2, 2, true)
set_filetype_options('wsh', 4, 4, 4, true)
set_filetype_options('xhtml', 4, 4, 4, true)
set_filetype_options('xml', 4, 4, 4, true)
set_filetype_options('yaml', 2, 2, 2, true)
set_filetype_options('zsh', 4, 4, 4, true)
set_filetype_options('scala', 2, 2, 2, true)
set_filetype_options('snippet', 4, 4, 4, true)

-- Telescope
vim.keymap.set('n', '<leader>p', '<cmd>Telescope find_files<cr>', { noremap = true })
vim.keymap.set('n', '<leader>g', '<cmd>Telescope live_grep<cr>', { noremap = true })
vim.keymap.set('n', '<leader>b', '<cmd>Telescope buffers<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { noremap = true })

-- hop
vim.keymap.set('n', 'f', '<cmd>HopWord<cr>', { noremap = true })
vim.keymap.set('n', '<Leader>l', '<cmd>HopLine<cr>', { noremap = true })
vim.keymap.set('n', '<Leader>/', '<cmd>HopPattern<cr>', { noremap = true })

-- coc-explorer
vim.keymap.set('n', '<Leader>e', '<Cmd>CocCommand explorer<CR>', { noremap = true })

-- coc-pair
-- 改行時にカーソル位置を調整する
vim.keymap.set('i', '<cr>', 'pumvisible() ? coc#_select_confirm() : "\\<C-g>u\\<CR>\\<c-r>=coc#on_enter()\\<CR>"',
  { noremap = true, silent = true, expr = true })

-- coc show documentation on hover
vim.keymap.set('n', 'K', ':call ShowDocumentation()<CR>', { noremap = true, silent = true })

-- ShowDocumentation function
vim.cmd([[
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
]])

-- GoTo code navigation
vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true })
vim.keymap.set('n', 'gy', '<Plug>(coc-type-definition)', { silent = true })
vim.keymap.set('n', 'gi', '<Plug>(coc-implementation)', { silent = true })
vim.keymap.set('n', 'gr', '<Plug>(coc-references)', { silent = true })

-- coc node version
vim.g.coc_node_path = '~/.proto/bin/node'

-- coc spell-checker
vim.keymap.set('v', '<leader>w', '<Plug>(coc-codeaction-selected)', { noremap = true })
vim.keymap.set('n', '<leader>w', '<Plug>(coc-codeaction-selected)', { noremap = true })
