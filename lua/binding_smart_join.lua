-- Function to delete text before cursor and join with previous line
local function smart_delete_prev_line()
    -- Get the current cursor position (row is 1-based)
    local current_row = vim.api.nvim_win_get_cursor(0)[1]

    -- Guard clause: Do nothing if we are on the first line
    if current_row == 1 then
        return
    end

    -- Create an undo block so this entire sequence counts as one 'u' (undo)
    -- Note: 'normal!' handles this atomically usually, but good practice in scripts
    
    -- Execute the sequence:
    -- 1. "_d0 : Delete from cursor to start of line into black hole register (doesn't clog clipboard)
    -- 2. k    : Move up one line
    -- 3. gJ   : Join the current line (now empty of pre-cursor text) with the one above WITHOUT adding a space
    vim.cmd('normal! "_d0kgJ')
end

-- Map the function to a key
-- I've set it to <Leader>J, but <Backspace> is also a very popular choice for this behavior
vim.keymap.set('n', '<BS>', smart_delete_prev_line, { 
    noremap = true, 
    silent = true, 
    desc = "Delete to start of line and join with previous line" 
})
