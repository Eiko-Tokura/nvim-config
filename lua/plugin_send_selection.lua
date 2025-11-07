-- send_to_terminal.lua

--[[
We provide two commands:

:SendCmd  -- send visual selection to terminal, stay where you are
:RunCmd   -- send visual selection to terminal, then focus that terminal window

Both:
1. read visual selection
2. find or create terminal
3. send text

We add a tiny difference in step 4.
]]

------------------------------------------------------------
-- 1. get visual selection
------------------------------------------------------------

---Get the current visual selection as a string (with trailing newline).
---@return string|nil
local function get_visual_text()
  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col     = unpack(vim.fn.getpos("'>"))

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then return nil end

  -- trim first line
  lines[1] = string.sub(lines[1], start_col)
  if #lines == 1 then
    -- selection on one line
    lines[1] = string.sub(lines[1], 1, end_col - start_col + 1)
  else
    -- trim last line
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, "\n") .. "\n"
end

------------------------------------------------------------
-- 2. find existing terminal buffer / window
------------------------------------------------------------

---Return buffer number of an existing terminal, or nil.
---@return integer|nil
local function find_terminal_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
      return buf
    end
  end
  return nil
end

---Return window id that is currently showing a given buffer, or nil.
---@param buf integer
---@return integer|nil
local function find_window_with_buf(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
  return nil
end

------------------------------------------------------------
-- 3. open a bottom terminal
------------------------------------------------------------

---Open a bottom split terminal and return its buffer AND window.
---If stay == true, we'll go back to previous window.
---@param stay boolean
---@return integer term_buf
---@return integer term_win
local function open_bottom_terminal(stay)
  -- remember current window
  local prev_win = vim.api.nvim_get_current_win()
  vim.cmd("botright split | terminal")
  local term_win = vim.api.nvim_get_current_win()
  local term_buf = vim.api.nvim_get_current_buf()
  if stay then
    vim.api.nvim_set_current_win(prev_win)
  end
  return term_buf, term_win
end

------------------------------------------------------------
-- 4. send text to terminal
------------------------------------------------------------

---Send text to terminal buffer.
---@param term_buf integer
---@param text string
local function send_to_terminal(term_buf, text)
  local job_id = vim.b[term_buf].terminal_job_id
  if not job_id then
    vim.notify("Target buffer is not an active terminal", vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_chan_send(job_id, text)
end

------------------------------------------------------------
-- 5a. main action for :SendCmd  (don't jump)
------------------------------------------------------------

---Send selection, do not move cursor.
local function send_cmd()
  local text = get_visual_text()
  if not text or text == "" then
    vim.notify("No visual selection to send", vim.log.levels.WARN)
    return
  end

  local term_buf = find_terminal_buf()
  if not term_buf then
    -- open but return to current window
    term_buf = open_bottom_terminal(true)
  end

  send_to_terminal(term_buf, text)
end

------------------------------------------------------------
-- 5b. main action for :RunCmd  (jump to terminal)
------------------------------------------------------------

---Send selection, then focus the terminal window.
local function run_cmd()
  local text = get_visual_text()
  if not text or text == "" then
    vim.notify("No visual selection to run", vim.log.levels.WARN)
    return
  end

  local term_buf = find_terminal_buf()
  local term_win = nil

  if not term_buf then
    -- open and STAY in the terminal (stay = false)
    term_buf, term_win = open_bottom_terminal(false)
  else
    -- we already have a terminal buffer; find its window
    term_win = find_window_with_buf(term_buf)
    if not term_win then
      -- terminal buffer exists but not visible -> open a split showing it
      -- simplest is to open a new terminal again:
      term_buf, term_win = open_bottom_terminal(false)
    else
      -- focus that window
      vim.api.nvim_set_current_win(term_win)
    end
  end

  send_to_terminal(term_buf, text)

  -- ensure we are in terminal window
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_set_current_win(term_win)
  end
end

------------------------------------------------------------
-- 6. Ex commands
------------------------------------------------------------

vim.api.nvim_create_user_command("SendCmd", function()
  send_cmd()
end, { range = true })

vim.api.nvim_create_user_command("RunCmd", function()
  run_cmd()
end, { range = true })
