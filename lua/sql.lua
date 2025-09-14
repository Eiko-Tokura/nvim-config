--[[
sql.lua ─ A tiny yet flexible Neovim helper that turns any buffer into an ad‑hoc SQL client.

🎯 **Purpose**
    • Let you select text in Neovim, hit a command (e.g. :SQL) and see the query result instantly.
    • Work over SSH so you can query remote SQLite (or any shell‑invoked) DB without leaving the editor.
    • Stay dependency‑free (pure Lua ‑ no plugins needed).

📐 **Design at a glance**
    1.  Collect SQL text from either the whole buffer or the current visual range.
    2.  Ship that text to an external command (`ssh … sqlite3 …`).
    3.  Drop the *stdout* back into Neovim using one of three targets:
        • **scratch**  – append to a reusable split.
        • **new**      – open a fresh split each time.
        • **here**     – append right in the current buffer.
    4.  Optionally add visual separators so successive results are easy to spot.

    All heavy‑lifting happens in a single async callback so the UI never blocks.

🛠  **Quickstart**
    1.  Save this file under *lua/my/sql.lua*.
    2.  `require("my.sql")` from your `init.lua` (or equivalent).
    3.  Run `:SQL`, `:SQLN`, or `:SQLH` in any `*.sql` buffer.

    (Feel free to map them, e.g. `nnoremap <leader>q :SQL<CR>`.)

────────────────────────────────────────────────────────────────────────────]]

local M = {}

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                               CONFIG                                  ║
-- ╚═══════════════════════════════════════════════════════════════════════╝
-- Everything here is safe to tweak without reading the rest of the file.
M.cfg = {
  -- Where to run the query --------------------------------------------------
  host    = "Asuka",            -- SSH hostname (empty string → local)
  db_path = "/opt/meowbot/meowbot.db",    -- Path *on the remote host* to the DB file

  -- Visual separators -------------------------------------------------------
  -- These strings are inserted *around each* query result when we **append**
  -- to a buffer (scratch or here).  Multi‑line is fine – embed \n if you like.
  separator_start_enabled = true,
  separator_start         = "/*---ResultBlock---owo-----",            -- e.g. "-- ⇩⇩⇩ result ⇩⇩⇩"

  separator_end_enabled   = true,
  separator_end           = "-----ResultBlock---end---*/",  -- e.g. "-- ⇧⇧⇧ end ⇧⇧⇧"

  -- Behaviour tweaks --------------------------------------------------------
  trim_trailing_newlines       = true,   -- strip blank line(s) at EOF of stdout
  newline_after_start_separator = false, -- add blank line *after* start separator
}

-- Handle of the reusable scratch buffer (nil until first use)
M.last_buf = nil

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                     INTERNAL UTILITY FUNCTIONS                        ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

--[[
collect_lines(range?) → string
    • *range* is either nil (meaning the *whole* buffer) or a two‑element
      0‑based, end‑exclusive table: {start_line, end_line}.
    • Returns those lines concatenated by newlines — perfect as SQLite stdin.
]]
local function collect_lines(range)
  local s, e = unpack(range or { 0, -1 })
  return table.concat(vim.api.nvim_buf_get_lines(0, s, e, false), "\n")
end

--[[
ensure_scratch() → buffer handle
    • Returns the existing scratch buffer if it’s still valid.
    • Otherwise creates a new split + buffer, configures it (nofile, filetype
      sql, no swap) and remembers it in M.last_buf.
]]
local function ensure_scratch()
  if M.last_buf and vim.api.nvim_buf_is_valid(M.last_buf) then
    return M.last_buf
  end

  vim.cmd("new")                       -- open horizontal split
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype  = "nofile"
  vim.bo[buf].filetype = "sql"
  vim.bo[buf].swapfile = false
  M.last_buf = buf
  return buf
end

--[[
write(buf, text, mode)
    • *buf*  – destination buffer handle.
    • *text* – raw stdout from sqlite (may end with \n\n).
    • *mode* – "replace" → clobber whole buffer; "append" → add below.

    Implements: trimming trailing newlines, inserting configurable separators.
]]
local function write(buf, text, mode)
  ---------------------------------------------------------------------------
  -- 1️⃣  Massage the raw stdout into a clean «lines» table
  ---------------------------------------------------------------------------
  if M.cfg.trim_trailing_newlines then
    text = text:gsub("\n+$", "")         -- drop *all* trailing \n
    -- Edge‑case: command produced only newlines → keep a single blank line
    if text == "" then text = " " end
  end

  local lines = vim.split(text, "\n", { plain = true })

  ---------------------------------------------------------------------------
  -- 2️⃣  Choose append vs replace strategy
  ---------------------------------------------------------------------------
  if mode == "replace" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return
  end

  ---------------------------------------------------------------------------
  -- 3️⃣  APPEND mode – insert start separator ▸ result ▸ end separator
  ---------------------------------------------------------------------------
  local dst = vim.api.nvim_buf_line_count(buf)  -- first free line (0‑based)

  -- (a) optional start separator – only if buffer already has content
  if dst > 0 and M.cfg.separator_start_enabled and M.cfg.separator_start ~= "" then
    vim.api.nvim_buf_set_lines(buf, dst, dst, false,
      vim.split(M.cfg.separator_start, "\n"))
    dst = dst + 1

    if M.cfg.newline_after_start_separator then
      vim.api.nvim_buf_set_lines(buf, dst, dst, false, { "" })
      dst = dst + 1
    end
  end

  -- (b) the actual query result
  vim.api.nvim_buf_set_lines(buf, dst, dst, false, lines)
  dst = dst + #lines

  -- (c) optional end separator (always shown if enabled)
  if M.cfg.separator_end_enabled and M.cfg.separator_end ~= "" then
    vim.api.nvim_buf_set_lines(buf, dst, dst, false,
      vim.split(M.cfg.separator_end, "\n"))
  end
end

--[[
run_query(sql_text, callback)
    • Spawns the shell command *asynchronously* via vim.system().
    • On completion invokes *callback* with the process result table.
]]
local function run_query(sql, cb)
  local cmd = { "ssh", M.cfg.host, "sqlite3", M.cfg.db_path }
  vim.system(cmd, { stdin = sql, text = true }, cb)
end

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                        PUBLIC ENTRY POINT                             ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

--[[
M.run{ range?, target }
    *range*  – nil or {start, finish} (0‑based).
    *target* – "scratch" | "new" | "here".

    Dispatches to run_query() and routes stdout to the chosen destination.
]]
function M.run(opts)
  local sql    = collect_lines(opts.range)
  local target = opts.target

  -- 1️⃣ launch subprocess
  run_query(sql, function(res)
    -- 2️⃣ hop back to main loop – safe to touch UI state now
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify(res.stderr, vim.log.levels.ERROR)
        return
      end

      if target == "new" then                      -- :SQLN
        vim.cmd("new")
        local buf = vim.api.nvim_get_current_buf()
        vim.bo[buf].buftype  = "nofile"
        vim.bo[buf].filetype = "sql"
        write(buf, res.stdout, "replace")
        M.last_buf = buf     -- remember for :SQL reuse

      elseif target == "here" then                  -- :SQLH
        write(vim.api.nvim_get_current_buf(), res.stdout, "append")

      else                                          -- default :SQL (scratch)
        local buf = ensure_scratch()
        -- If scratch buffer is hidden, open it in a split so user sees result
        if #vim.fn.win_findbuf(buf) == 0 then
          vim.cmd("split | b" .. buf)
        end
        write(buf, res.stdout, "append")
      end
    end)
  end)
end

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                         USER COMMAND SETUP                           ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

-- Convert UserCmd range info into the {start,finish} table expected upstream
local function range_tbl(o)
  if o.range == 0 then return nil end            -- no range → whole buffer
  -- line1/line2 are 1‑based inclusive → convert to 0‑based exclusive
  return { o.line1 - 1, o.line2 }
end

-- Main command: reuse or create a scratch window, *append* result
vim.api.nvim_create_user_command("S", function(o)
  M.run { range = range_tbl(o), target = "scratch" }
end, {
  range = true,
  desc  = "Run SQL and append to last scratch buffer",
})

-- Always open a **new** scratch window, *replace* its content each time
vim.api.nvim_create_user_command("SN", function(o)
  M.run { range = range_tbl(o), target = "new" }
end, {
  range = true,
  desc  = "Run SQL in a new scratch window",
})

-- Append result directly **here**, below current buffer content
vim.api.nvim_create_user_command("SH", function(o)
  M.run { range = range_tbl(o), target = "here" }
end, {
  range = true,
  desc  = "Run SQL and append in current buffer",
})

return M
