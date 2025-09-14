require('gitsigns').setup {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 0,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
}

-- Gitsigns setup
local gs = require('gitsigns')
local map = vim.keymap.set
local opts = { silent = true }

-- ── Navigation ───────────────────────────────────────────────
map('n', '<leader>gj', function()
  if vim.wo.diff then return ':normal ]c<CR>' end
  gs.next_hunk()
end, vim.tbl_extend('force', opts, { desc = 'Next hunk' }))

map('n', '<leader>gk', function()
  if vim.wo.diff then return ':normal [c<CR>' end
  gs.prev_hunk()
end, vim.tbl_extend('force', opts, { desc = 'Prev hunk' }))

-- ── Stage / Unstage ──────────────────────────────────────────
map('n', '<leader>gs', gs.stage_hunk,   vim.tbl_extend('force', opts, { desc = 'Stage hunk' }))
map('n', '<leader>gS', gs.stage_buffer, vim.tbl_extend('force', opts, { desc = 'Stage buffer' }))
map('n', '<leader>gu', gs.undo_stage_hunk, vim.tbl_extend('force', opts, { desc = 'Undo stage hunk' }))

-- ── Restore / Reset ──────────────────────────────────────────
map('n', '<leader>gr', gs.reset_hunk,   vim.tbl_extend('force', opts, { desc = 'Reset hunk' }))
map('n', '<leader>gR', gs.reset_buffer, vim.tbl_extend('force', opts, { desc = 'Reset buffer' }))

-- ── Blame ────────────────────────────────────────────────────
map('n', '<leader>gb', gs.blame_line, vim.tbl_extend('force', opts, { desc = 'Blame line' }))
map('n', '<leader>gB', function() gs.blame_line({ full = true }) end,
  vim.tbl_extend('force', opts, { desc = 'Blame full' }))

-- ── Preview ──────────────────────────────────────────────────
map('n', '<leader>gp', gs.preview_hunk, vim.tbl_extend('force', opts, { desc = 'Preview hunk' }))

-- ── Diff ─────────────────────────────────────────────────────
map('n', '<leader>gd', gs.diffthis, vim.tbl_extend('force', opts, { desc = 'Diff (index)' }))
map('n', '<leader>gD', function() gs.diffthis('~') end,
  vim.tbl_extend('force', opts, { desc = 'Diff (HEAD~)' }))

-- ── Toggle ───────────────────────────────────────────────────
map('n', '<leader>gt', gs.toggle_deleted, vim.tbl_extend('force', opts, { desc = 'Toggle deleted' }))
