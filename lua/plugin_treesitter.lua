require('nvim-treesitter').setup({
  install_dir = vim.fn.stdpath('data') .. '/site',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'c',
    'lua',
    'vim',
    'query',
    'markdown',
    'haskell',
  },
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if vim.treesitter.language.add(lang or args.match) then
      vim.treesitter.start(args.buf)
    end
  end,
})

vim.keymap.set("n", "\\rn", vim.lsp.buf.rename)
vim.keymap.set("n", "\\ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "\\gd", vim.lsp.buf.definition)