-- Helper function to get the visual selection as a raw string
-- It uses a temporary register ('v') to avoid overwriting your main clipboard
local function get_visual_selection()
    vim.cmd('noautocmd normal! "vy')
    local text = vim.fn.getreg('v')

    -- IMPORTANT: Clean up the text for the command line
    -- 1. Escape backslashes first (so we don't double escape later)
    text = text:gsub("\\", "\\\\")
    -- 2. Escape slashes (because they are the delimiter for %s/ and /search)
    text = text:gsub("/", "\\/")
    -- 3. Replace newlines with \n so the command line doesn't break
    text = text:gsub("\n", "\\n")

    return text
end

local function put_in_search_register(text)
    vim.fn.setreg('/', '\\V' .. text)
end

-- Usage: Select text, press <Leader>r. 
-- Result: :%s/\V<selection>/<cursor>
vim.keymap.set("x", "<Leader>8", function()
    local text = get_visual_selection()
    put_in_search_register(text)
    -- <Esc> exits visual mode so we can type the command
    -- \V tells Vim to treat the following text literally (not as regex)
    local cmd = ":%s/\\V" .. text .. "/"
    
    -- Feed the keys into the command line
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>" .. cmd, true, false, true), 
        "n", false
    )
end, { desc = "Search and Replace selection globally" })

-- Project-wide Grep (using :vim or :grep)
-- Usage: Select text, press <Leader>* (Find)
-- Result: :vim /\V<selection>/ **/*
vim.keymap.set("x", "<Leader>*", function()
    local text = get_visual_selection()
    put_in_search_register(text)
    -- Adjust this command if you use fzf, telescope, or standard grep
    -- This example uses standard standard vimgrep
    local cmd = ":vim /\\V" .. text .. "/ "
    
    -- We leave the cursor before the **/* so you can edit the file glob if needed
    -- <Left> x 5 moves cursor back
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>" .. cmd, true, false, true), 
        "n", false
    )
end, { desc = "Grep selection in project" })
