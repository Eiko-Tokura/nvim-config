-- Eiko's Neovim Configuration

-- Load the essential vim movements, these are plugin independent settings
-- fallback version: vim.cmd 'source ~/.config/nvim/essential.vim'
require('essential')

-- Load the plugins and their settings (keymaps, etc)
vim.cmd 'source ~/.config/nvim/plugin/plugins.vim'

-- Commands for creating new tex files
require('texcommands')

-- Shortcuts for LaTeX
require('latex-shortcuts')
--require('latex-shortcuts-new')

-- Load the plugin settings
require('plugin_treesitter')
require('plugin_gitsigns')
require('plugin_avante')
require('plugin_opencode')
require('plugin_mason')
require('sql')
vim.cmd [[
  autocmd BufRead,BufNewFile *.lean lua require('plugin_lean')
]] -- only load lean plugin when opening lean files
--require('plugin_llm')
--require('plugin_codecompanion')
