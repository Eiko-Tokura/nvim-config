" Define a syntax region for inline math ($...$)
syntax region markdownMathInline start="\$" skip="\\\\\|\\\$" end="\$" contains=@NoSpell keepend
" Define a syntax region for display math ($$...$$)
syntax region markdownMathDisplay start="\$\$" skip="\\\\\|\\\$\$" end="\$\$" contains=@NoSpell keepend

"highlight link markdownMathInline Statement
"highlight link markdownMathDisplay Statement
