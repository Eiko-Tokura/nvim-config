---@param s string
---@return string trimmed
---@return integer removed_bytes
local function trim_left_whitespace(s)
  local trimmed = s:gsub('^%s+', '')
  return trimmed, #s - #trimmed
end

---@param prev_line string
---@param next_line_trimmed string
---@return string glue Either `" "` or `""`.
local function join_glue(prev_line, next_line_trimmed)
  ---@class JoinGlueContext
  ---@field prev_line string
  ---@field next_line_trimmed string

  ---@alias JoinGlueRule fun(ctx: JoinGlueContext): string|nil

  ---@type JoinGlueContext
  local ctx = { prev_line = prev_line, next_line_trimmed = next_line_trimmed }

  ---@type JoinGlueRule[]
  local rules = {
    ---No content means no glue.
    function(c)
      if c.next_line_trimmed == '' then
        return ''
      end
      return nil
    end,

    ---If the next token is a comma, do not add filler.
    function(c)
      if c.next_line_trimmed:sub(1, 1) == ',' then
        return ''
      end
      return nil
    end,

    ---If previous line already ends in whitespace, no filler is needed.
    function(c)
      if c.prev_line:match('%s$') then
        return ''
      end
      return nil
    end,

    ---Default: a single space as filler.
    function(_c)
      return ' '
    end,
  }

  for _, rule in ipairs(rules) do
    local res = rule(ctx)
    if res ~= nil then
      return res
    end
  end

  return ''
end

---@param prev_line string
---@param glue string
---@param cursor_col integer 0-based byte column in the current line
---@param removed_indent_bytes integer
---@return integer new_cursor_col 0-based byte column in the joined line
local function compute_joined_cursor_col(prev_line, glue, cursor_col, removed_indent_bytes)
  local prev_len = #prev_line
  local glue_len = #glue
  local shifted = cursor_col - removed_indent_bytes
  if shifted < 0 then
    shifted = 0
  end
  return prev_len + glue_len + shifted
end

---Smart backspace join for normal mode.
---
---Semantics:
---- Pressing `<BS>` on any column joins the current line into the previous line.
---- Leading whitespace on the current line is removed (indentation is dropped).
---- If the previous line does not end in whitespace, inserts a single space as filler.
---- Exception: if the trimmed current line starts with `,`, does not insert filler.
---- Cursor stays on the same character (modulo removed indentation) after the join.
local function smart_backspace_join()
  local buf = 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row_1based, col_0based = cursor[1], cursor[2]

  if row_1based == 1 then
    vim.cmd('normal! h')
    return
  end

  local prev_idx0 = row_1based - 2
  local curr_idx0 = row_1based - 1

  local prev_line = vim.api.nvim_buf_get_lines(buf, prev_idx0, prev_idx0 + 1, false)[1] or ''
  local curr_line = vim.api.nvim_buf_get_lines(buf, curr_idx0, curr_idx0 + 1, false)[1] or ''

  local curr_trimmed, removed_indent_bytes = trim_left_whitespace(curr_line)
  local glue = join_glue(prev_line, curr_trimmed)
  local joined = prev_line .. glue .. curr_trimmed

  -- Replace the two-line range with the joined line in a single undo step.
  vim.api.nvim_buf_set_lines(buf, prev_idx0, curr_idx0 + 1, false, { joined })

  local new_col = compute_joined_cursor_col(prev_line, glue, col_0based, removed_indent_bytes)
  vim.api.nvim_win_set_cursor(0, { row_1based - 1, new_col })
end

vim.keymap.set('n', '<BS>', smart_backspace_join, {
  noremap = true,
  silent = true,
  desc = 'Join current line into previous (with spacer)',
})
