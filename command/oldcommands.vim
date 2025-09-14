
function! NumDigits(n)
  let l:number = a:n
  let l:digits = 0
  while l:number
    let l:number = l:number / 10
    let l:digits += 1
  endwhile
  return l:digits
endfunction

function! IncChar()
  let l:char = getline('.')[col('.') - 1]
  let l:charnr = char2nr(l:char)
  if l:charnr >= char2nr('a') && l:charnr < char2nr('z')
    let l:charnr = l:charnr + 1
  elseif l:charnr == char2nr('z')
    let l:charnr = char2nr('a')
  endif
  let l:newchar = nr2char(l:charnr)
  let l:newline = substitute(getline('.'), '\%'.col('.').'c.', l:newchar, '')
  call setline('.', l:newline)
endfunction

function! InsertLaTeXBlock(start, end)
    " Store current position
    let l:save_pos = getpos(".")

    " Insert the start block, an empty line, and the end block
    call append(line("."), a:start)
    call append(line(".")+1, "      ")
    call append(line(".")+2, a:end)

    " Move the cursor to the empty line in the middle
    call cursor(line(".") + 2, 6)

    " Restore the view to keep the cursor centered if possible
    " normal zz
endfunction

function! SaveSelectedLines()
    " Ask for the new file name
    let l:newfile = input('Enter new file name: ')

    " Write the visually selected lines to the new file
    normal! gv"xy
    call writefile(split(@x, "\n"), l:newfile)

    " Open the new file for editing
    execute 'tabedit' l:newfile
endfunction

" Map this function to a key combination in visual mode, for example, <leader>s
function! ExecuteAnkiCommands()
    let l:thisfile = expand('%:p')

    " Execute anki commands with quotes around the file path
    execute '!ankic --import --use-tex-path  "' . l:thisfile . '"'
endfunction

" Map this function to a key combination, for example, <leader>e

function! EncloseWithCurlyBraces()
    let l:visualSelection = &selection ==# 'inclusive' ? 'gv' : 'lv'
    normal! `<"ay`>l
    let l:selectedText = @a
    if len(l:selectedText) > 0
	    let l:newText = "{{{ " . l:selectedText . " }}}"
        execute "normal! " . l:visualSelection . 'c' . l:newText
    endif
endfunction
