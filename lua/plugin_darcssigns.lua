require('darcssigns').setup {
    sign_style = 'minimal',
    preview = { ui = { default = 'float' } },
}

vim.keymap.set('n', '<leader>dp', require('darcssigns').preview_hunk, { desc = 'Preview Darcs hunk' })
