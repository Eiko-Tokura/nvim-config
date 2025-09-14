
local function new_tex_file_on_this_window()
  vim.bo.filetype = 'tex'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    '\\documentclass{article}',
    '\\input{~/Documents/TEX/Headers/myheader.tex}',
    '',
    '\\title{}',
    '\\author{Eiko}',
    '',
    '\\begin{document}',
    '\\maketitle',
    '',
    '\\end{document}'
  })
  vim.fn.cursor(4, 7)
end

vim.api.nvim_create_user_command('Tex', new_tex_file_on_this_window, {})

local function new_tex_file()
  vim.cmd('tabnew')
  new_tex_file_on_this_window()
end

vim.api.nvim_create_user_command('NewTex', new_tex_file, {})

