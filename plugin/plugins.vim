source ~/.config/nvim/command/oldcommands.vim

set number relativenumber

let mapleader=" "

let $TERM='konsole-256color'            

let g:Copilot_enable = 0

let g:airline#extensions#whitespace#enabled = 0

noremap <LEADER><F5> :source $MYVIMRC<CR>
noremap <LEADER><F3> :colorscheme colorful<CR>:hi Normal ctermbg=White ctermfg=Black guifg=Black<CR>:highlight NormalFloat guifg=#FF91AF<CR>:highlight CocNotification ctermfg=red guifg=red<CR>

noremap <LEADER><F2> :colorscheme flexoki-dark<CR>
noremap <LEADER><F6> :Copilot enable<CR> 
noremap <LEADER><A-F6> :Copilot disable<CR> 

noremap <C-h> :TmuxNavigateLeft<CR>
noremap <C-j> :TmuxNavigateDown<CR>
noremap <C-k> :TmuxNavigateUp<CR>
noremap <C-l> :TmuxNavigateRight<CR>

noremap <LEADER><Enter> :AIChat<CR>
vnoremap <leader>s :<C-u>call SaveSelectedLines()<CR>
imap <M-;> <Plug>(copilot-suggest)

noremap <F7> :call RunPy()<CR>
"noremap <expr><LEADER>b (strpart(getline('.'), col('.')-1, 1) == "(")?"i\\left<Esc>l%i\\right<Esc>":"i\\right<Esc>l%i\\left<Esc>"
noremap <LEADER>b :call BraceLRChange()<CR>
noremap <LEADER>\e :call InsertLaTeXBlock('\begin{enumerate}', '\end{enumerate}')<CR>
noremap <LEADER>\i :call InsertLaTeXBlock('\begin{itemize}', '\end{itemize}')<CR>
noremap <LEADER>\ad :call InsertLaTeXBlock('\anki{defn}', '\ankiend{defn}')<CR>
noremap <LEADER>\ap :call InsertLaTeXBlock('\anki{prop}', '\ankiend{prop}')<CR>

nnoremap <leader>e :call ExecuteAnkiCommands()<CR>
vnoremap <LEADER>c :call EncloseWithCurlyBraces()<CR>
vnoremap <LEADER>t :Tabularize /

nnoremap <silent> <M-l> :execute 'normal! ' . (winwidth(0) - NumDigits(line('.')) - 1) . 'l'<CR>
nnoremap <silent> <M-h> :execute 'normal! ' . (winwidth(0) - NumDigits(line('.')) - 1) . 'h'<CR>
"20j

" Agda config
au BufRead,BufNewFile *.agda call AgdaFiletype()
au QuitPre *.agda :CornelisCloseInfoWindows
function! AgdaFiletype()
    nnoremap <buffer> <localleader>l :CornelisLoad<CR>
    nnoremap <buffer> <localleader>g :CornelisGoals<CR>
    nnoremap <buffer> <localleader>r :CornelisRefine<CR>
    nnoremap <buffer> <localleader>c :CornelisMakeCase<CR>
    nnoremap <buffer> <localleader>, :CornelisTypeContext<CR>
    nnoremap <buffer> <localleader>. :CornelisTypeContextInfer<CR>
    nnoremap <buffer> <localleader>n :CornelisNormalize<CR>
    nnoremap <buffer> <localleader>h :CornelisHelperFunc<CR>
    nnoremap <buffer> <localleader>s :CornelisSolve<CR>
    nnoremap <buffer> <localleader>a :CornelisAuto<CR>
    nnoremap <buffer> gd        :CornelisGoToDefinition<CR>
    nnoremap <buffer> [g        :CornelisPrevGoal<CR>
    nnoremap <buffer> ]g        :CornelisNextGoal<CR>
    nnoremap <buffer> <C-A>     :CornelisInc<CR>
    nnoremap <buffer> <C-X>     :CornelisDec<CR>
endfunction

autocmd FileType agda let b:maplocalleader="\\"

if exists(':GuiFont')
  autocmd VimEnter * GuiFont! Noto Sans Mono:h12
  autocmd VimEnter * GuiWindowOpacity 0.8
endif

"*****************************************************************************
"" Vim-Plug core
"*****************************************************************************
let vimplug_exists=expand('~/.config/nvim/autoload/plug.vim')
if has('win32')&&!has('win64')
  let curl_exists=expand('C:\Windows\Sysnative\curl.exe')
else
  let curl_exists=expand('curl')
endif

let g:vim_bootstrap_langs = "haskell,python"
let g:vim_bootstrap_editor = "nvim"				" nvim or vim
let g:vim_bootstrap_theme = "molokai"
let g:vim_bootstrap_frams = ""

if !filereadable(vimplug_exists)
  if !executable(curl_exists)
    echoerr "You have to install curl or first install vim-plug yourself!"
    execute "q!"
  endif
  echo "Installing Vim-Plug..."
  echo ""
  silent exec "!"curl_exists" -fLo " . shellescape(vimplug_exists) . " --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  let g:not_finish_vimplug = "yes"

  autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.vim/plugged/')
        Plug 'MunifTanjim/nui.nvim'
	Plug 'rhysd/vim-grammarous'
	Plug 'derekelkins/agda-vim'
 	Plug 'whonore/Coqtail'

	" Python
	Plug 'mason-org/mason.nvim'
	Plug 'mason-org/mason-lspconfig.nvim'

	" Git
	Plug 'tpope/vim-fugitive' 
	Plug 'lewis6991/gitsigns.nvim' 

	Plug 'nvim-lua/plenary.nvim'
	Plug 'nvim-telescope/telescope.nvim'
	
	Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' , 'branch': 'master' }

	Plug 'lambdalisue/suda.vim'
	Plug 'madox2/vim-ai', {'branch': 'main'}

	Plug 'github/copilot.vim'
	"Plug 'supermaven-inc/supermaven-nvim'
	"
	"Plug 'dense-analysis/neural'
        Plug 'elpiloto/significant.nvim'

	Plug 'rmagatti/auto-session'

"	Plug 'ashinkarov/nvim-agda'
	Plug 'kana/vim-textobj-user'
	Plug 'pbrisbin/vim-syntax-shakespeare'
	Plug 'neovimhaskell/nvim-hs.vim'
	Plug 'isovector/cornelis', { 'do' : 'stack build' }

	Plug 'tpope/vim-surround'

	" If you don't have nodejs and yarn
	" use pre build, add 'vim-plug' to the filetype list so vim-plug can update this plugin
	" see: https://github.com/iamcco/markdown-preview.nvim/issues/50
	Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

	"Plug 'MrcJkb/haskell-tools.nvim'
	"Plug 'twinside/vim-hoogle'
	Plug 'monkoose/fzf-hoogle.vim'

	Plug 'neoclide/coc.nvim', {'branch': 'release'}

	Plug 'vim-airline/vim-airline'
	Plug 'flazz/vim-colorschemes'
	Plug 'kepano/flexoki-neovim'

	Plug 'lervag/vimtex'
	Plug 'HakonHarnes/img-clip.nvim'

	Plug 'scrooloose/nerdtree', {'on': 'NERDTreeToggle'}
	Plug 'godlygeek/tabular'

	Plug 'DreamMaoMao/yazi.nvim'

	"Plug 'Julian/lean.nvim'
	Plug 'neovim/nvim-lspconfig'
	Plug 'hrsh7th/nvim-cmp'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'hrsh7th/cmp-buffer'
	Plug 'hrsh7th/vim-vsnip'       " For snippets
	Plug 'andrewradev/switch.vim'  " For Lean switch support
	Plug 'tomtom/tcomment_vim'     " For commenting motions

	" Plug 'Shatur/neovim-session-manager'

	Plug 'christoomey/vim-tmux-navigator'  " For tmux navigation

	Plug 'stevearc/dressing.nvim'
	Plug 'MeanderingProgrammer/render-markdown.nvim'
	Plug 'echasnovski/mini.pick'
	Plug 'ibhagwan/fzf-lua'
	Plug 'nvim-tree/nvim-web-devicons'
	Plug 'yetone/avante.nvim', { 'branch': 'main', 'do': 'make' }

	Plug 'NickvanDyke/opencode.nvim'

	Plug 'yuratomo/w3m.vim'

	Plug 'Eiko-Tokura/darcssigns.nvim'
	" Experimental
	" Plug '/home/eiko/Documents/Lua/darcssigns'
call plug#end()

let g:coqtail_noimap = 1

let g:vim_ai_chat = {
\  "options": {
\    "model": "o3-mini",
\    "endpoint_url": "https://api.openai.com/v1/chat/completions",
\    "initial_prompt": "",
\  },
\}

let initial_prompt =<< trim END
>>> user

You are going to play a role of a completion engine with following parameters:
Task: Provide compact code/text completion, generation, transformation or explanation
Topic: general programming and text editing
Style: Plain result without any commentary, unless commentary is necessary
Audience: Users of text editor and programmers that need to transform/generate text
END

" temperature changed from 0.1 to 1 due to o1-mini doesn't support temperature
let g:vim_ai_complete = {
\  "engine": "chat",
\  "options": {
\    "model": "o3-mini",
\    "endpoint_url": "https://api.openai.com/v1/chat/completions",
\    "max_tokens": 0,
\    "temperature": 1,
\    "request_timeout": 30,
\    "initial_prompt": initial_prompt,
\    "enable_auth": 1,
\    "selection_boundary": "",
\  },
\  "ui": {
\    "paste_mode": 1,
\  },
\}

let g:vim_ai_edit = {
\  "engine": "chat",
\  "options": {
\    "model": "o3-mini",
\    "endpoint_url": "https://api.openai.com/v1/chat/completions",
\    "max_tokens": 0,
\    "temperature": 1,
\    "request_timeout": 30,
\    "initial_prompt": initial_prompt,
\    "enable_auth": 1,
\    "selection_boundary": "",
\  },
\  "ui": {
\    "paste_mode": 1,
\  },
\}

" Colors
" Colors
" Colors
" Define a variable for the mode
" Use 1 for light mode, 0 for dark mode
let g:isLightMode = 0

" Check if we are in light mode or dark mode
if g:isLightMode == 1
    " Settings for light mode
    colorscheme colorful
    hi Normal ctermbg=White ctermfg=Black guifg=Black
else
    " Settings for dark mode
    colorscheme flexoki-dark
endif

"hi Normal ctermbg=White ctermfg=Black guifg=Black
"colorscheme papercolor
" Colors
" Colors
" Colors


" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc
" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc
" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc

let g:coc_global_extensions = ['coc-pyright', 'coc-yank', 'coc-rust-analyzer']
" Highlight the symbol and its references when holding the cursor
"autocmd CursorHold * silent call CocActionAsync('highlight')

highlight NormalFloat guifg=#FF91AF
highlight CocNotification ctermfg=red guifg=red

  " 使用 Alt+j, Alt+k 来上下翻动补全
  " 你可能需要检查你的终端或 GUI 是否支持使用 Alt 键
  " 对于一些终端，你可能需要使用 <Esc> 键代替 <M> (即 Alt)
  " imap <silent><expr> <M-j> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-n>"
  " imap <silent><expr> <M-k> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-p>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <M-j>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<M-j>" :
      \ coc#refresh()
inoremap <silent><expr> <M-k> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Diagnostic

nmap <silent> 'k <Plug>(coc-diagnostic-prev)
nmap <silent> 'j <Plug>(coc-diagnostic-next)
nmap <silent> 'K :CocPrev<CR>
nmap <silent> 'J :CocNext<CR>
nmap <silent> 'd :<C-u>CocList diagnostics<CR>

" Remap keys for applying refactor code actions
nmap <silent> 'a <Plug>(coc-codeaction-cursor)
nmap <silent> 'f <Plug>(coc-fix-current)
nmap <silent> 'c <Plug>(coc-codelens-action)

nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)

" Use M-; to show documentation in preview window
nnoremap <silent> <M-;> :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    " call feedkeys('K', 'in')
  endif
endfunction

" Formatting selected code
xmap <leader><S-F>  <Plug>(coc-format-selected)
nmap <leader><S-F>  <Plug>(coc-format-selected)
" /home/eiko/.ghcup/bin/
  call coc#config('suggest.noselect', "true")
  call coc#config('languageserver', {
			  \  'haskell': {
  			  \    "command": "haskell-language-server-wrapper",
  			  \    "args": ["--lsp"],
  			  \    "rootPatterns": ["*.cabal", "stack.yaml", "cabal.project", "package.yaml", "hie.yaml"],
  			  \    "filetypes": ["haskell", "lhaskell"],
                          \    "settings": {
	                  \      "haskell": {
	                  \        "formattingProvider": "ormolu",
                          \        "maxCompletions": 40,
                          \        "plugin": {
	                  \          "stan": { "globalOn": "true" },
                          \          "rename": { "config": { "crossModule": "true" } },
                          \          "hlint" : { "config" : { "flags" :
                          \                        [ "--with-group=use-lens"
                          \                        , "--with-group=use-th-quotes"
                          \                        , "--with-group=generalize"
                          \                        ]
                          \                      }
                          \          }
                          \        }
                          \      }
                          \    }
  			  \  }
  			  \})

" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc
" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc
" Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc " Coc

" VimTex Options
let g:vimtex_view_general_viewer = 'zathura'
"let g:vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
" let g:vimtex_view_general_options_latexmk = '-reuse-instance'

" Tabularize Mappings
" nmap <LEADER>a :Tabularize /&<CR>
" vmap <LEADER>a :Tabularize /&<CR>

" Auto commands
augroup progamming_settings
	autocmd!
	autocmd FileType markdown,cabal,tex,haskell,python,hamlet setlocal expandtab
	autocmd FileType tex,haskell,python,hamlet setlocal autoindent
	autocmd FileType markdown,haskell,python,agda setlocal shiftwidth=2
	autocmd FileType markdown,haskell,python,agda setlocal softtabstop=2
	autocmd FileType hamlet,tex setlocal shiftwidth=4
	autocmd FileType cabal,hamlet,tex setlocal softtabstop=4
	autocmd FileType markdown,tex setlocal spell
augroup end

augroup markdownFormula
	autocmd FileType markdown syntax region markdownMathInline start="\$" skip="\\\\\|\\\$" end="\$" contains=@NoSpell keepend
	autocmd FileType markdown syntax region markdownMathDisplay start="\$\$" skip="\\\\\|\\\$\$" end="\$\$" contains=@NoSpell keepend
	autocmd FileType markdown syntax region markdownMathDisplay start="^\s*\\begin{align\*}" end="^\s*\\end{align\*}" contains=@NoSpell keepend
	autocmd FileType markdown syntax region markdownBlockquote start="^\s*```" end="^\s*```" contains=@NoSpell keepend
	" autocmd FileType markdown TSDisable highlight

	" Exclude spell checking in inline code (`...`)
	autocmd FileType markdown syntax region markdownCodeInline start="`" skip="\\\\\|\\\`" end="`" contains=@NoSpell keepend
	
	" Exclude spell checking in fenced code blocks (```...```)
	autocmd FileType markdown syntax region markdownCodeBlock start="^\s*```" end="^\s*```" contains=@NoSpell keepend
	
	" Exclude spell checking in indented code blocks (    ...)
	autocmd FileType markdown syntax region markdownCodeBlockIndented start="^\s\{4,\}\S" end="^\(\s*$\)\@=" contains=@NoSpell keepend
	
	" Highlighting for math regions
	autocmd FileType markdown highlight link markdownMathInline          Special
	autocmd FileType markdown highlight link markdownMathDisplay         Statement
	
	" Highlighting for code regions
	autocmd FileType markdown highlight link markdownCodeInline          String
	autocmd FileType markdown highlight link markdownCodeBlock           String
	autocmd FileType markdown highlight link markdownCodeBlockIndented   String

augroup END

