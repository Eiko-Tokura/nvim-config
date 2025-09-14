-- Set line numbering
vim.opt.number = true
vim.opt.relativenumber = true

-- Set leader key
vim.g.mapleader = " "

-- Remapping keys
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Accelerate cursor movement
keymap('', 'J', '4j', opts)
keymap('', 'K', '4k', opts)
keymap('', 'L', '6l', opts)
keymap('', 'H', '6h', opts)
keymap('', 'U', '<C-r>', opts)
keymap('', '<C-d>', '<C-d>zz', opts)
keymap('', '<C-u>', '<C-u>zz', opts)

-- Accelerate even more with Alt
keymap('', '<A-J>', '<C-d>zz', opts)
keymap('', '<A-K>', '<C-u>zz', opts)
keymap('', '<A-L>', '36l', opts)
keymap('', '<A-H>', '36h', opts)
keymap('', '<A-B>', '5B', opts)
keymap('', '<A-W>', '5W', opts)
keymap('', '<A-E>', '5E', opts)

-- Copy and paste to system clipboard
keymap('', '<Leader>y', '"+y', opts)
keymap('', '<Leader>p', '"+p', opts)
-- If you want to use the usual p command, you can use the Alt+p mapping.
keymap('', '<M-p>', 'p', opts)

-- Quick save and quit
keymap('n', '<Leader>q', ':q<CR>', opts)
keymap('n', '<Leader>s', ':w<CR>', opts)
keymap('n', '<Leader>w', ':w<CR>', opts)

-- Tab navigation
keymap('n', '<Leader>t', ':tabnew<CR>', opts)
keymap('n', '<Leader>T', ':tabclose<CR>', opts)
keymap('n', '<Leader>[', ':tabprev<CR>', opts)
keymap('n', '<Leader>]', ':tabnext<CR>', opts)
keymap('n', '<Leader>{', ':tabm -1<CR>', opts)
keymap('n', '<Leader>}', ':tabm +1<CR>', opts)
keymap('n', '<Leader>1', '1gt', opts)
keymap('n', '<Leader>2', '2gt', opts)
keymap('n', '<Leader>3', '3gt', opts)
keymap('n', '<Leader>4', '4gt', opts)
keymap('n', '<Leader>5', '5gt', opts)
keymap('n', '<Leader>6', '6gt', opts)
keymap('n', '<Leader>7', '7gt', opts)
keymap('n', '<Leader>8', '8gt', opts)
keymap('n', '<Leader>9', '9gt', opts)

-- Resize windows
keymap('n', '<C-Up>', ':res +5<CR>', {})
keymap('n', '<C-Down>', ':res -5<CR>', {})
keymap('n', '<C-Left>', ':vertical resize -5<CR>', {})
keymap('n', '<C-Right>', ':vertical resize +5<CR>', {})

-- Clear search highlights
keymap('n', '<Leader>/', ':noh<CR>', {})

-- Split windows
keymap('n', '<Leader>h', ':set nosplitright<CR>:vsplit<CR>', {})
keymap('n', '<Leader>l', ':set splitright<CR>:vsplit<CR>', {})
keymap('n', '<Leader>j', ':set splitbelow<CR>:split<CR>', {})
keymap('n', '<Leader>k', ':set nosplitbelow<CR>:split<CR>', {})

-- Paste without copying replaced text in visual mode
keymap('v', 'p', '"_dP', opts)

-- Move between windows
keymap('n', '<C-h>', ':TmuxNavigateLeft<CR>', {})
keymap('n', '<C-j>', ':TmuxNavigateDown<CR>', {})
keymap('n', '<C-k>', ':TmuxNavigateUp<CR>', {})
keymap('n', '<C-l>', ':TmuxNavigateRight<CR>', {})

-- Plugin specific keymaps
keymap('n', '<Leader>f', ':Yazi<CR>', opts)
keymap('n', '<Leader>m', ':MarkdownPreview<CR>', opts)
keymap('n', '<Leader><CR>', ':AIChat<CR>', opts)
