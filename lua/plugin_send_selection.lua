-- send_selection.lua
-- Drop this in your init.lua or require it from somewhere.

--[[
Functional-style helpers + type annotations.
We:
1. get visual text
2. find or create terminal
3. send text
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
-- 2. find existing terminal
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

------------------------------------------------------------
-- 3. open a bottom terminal
------------------------------------------------------------

---Open a bottom split terminal and return its buffer number.
---@return integer
local function open_bottom_terminal()
  vim.cmd("botright split | terminal")
  local term_buf = vim.api.nvim_get_current_buf()
  -- go back to previous window
  vim.cmd("wincmd p")
  return term_buf
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
-- 5. main action
------------------------------------------------------------

---Send current visual selection to a terminal (create if missing).
local function run_selection()
  local text = get_visual_text()
  if not text or text == "" then
    vim.notify("No visual selection to run", vim.log.levels.WARN)
    return
  end

  local term_buf = find_terminal_buf()
  if not term_buf then
    term_buf = open_bottom_terminal()
  end

  send_to_terminal(term_buf, text)
end

------------------------------------------------------------
-- 6. Ex commands
------------------------------------------------------------
-- Use in visual mode:
--   :Run
--   :Exec
--   :RunSelection

vim.api.nvim_create_user_command("RunSelection", function()
  run_selection()
end, { range = true })

vim.api.nvim_create_user_command("Run", function()
  run_selection()
end, { range = true })

vim.api.nvim_create_user_command("Exec", function()
  run_selection()
end, { range = true })
