augroup MarkdownSpell
  autocmd!
  autocmd FileType markdown syntax region markdownMathInline start="\$" skip="\\\\\|\\\$" end="\$" contains=@NoSpell keepend
  autocmd FileType markdown syntax region markdownMathDisplay start="\$\$" skip="\\\\\|\\\$\$" end="\$\$" contains=@NoSpell keepend
augroup END
