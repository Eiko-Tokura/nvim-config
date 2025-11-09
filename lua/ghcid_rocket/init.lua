-- ghcid_rocket/init.lua
local M = {}
local uv = vim.loop

-- ========================
-- ## Module State
-- ========================
-- Centralized state variables for the module

-- Watcher state
local watcher = nil ---@type uv_fs_poll_t|nil
local last_sig = nil ---@type string|nil

-- Jump-back state
local last_jump_origin = nil ---@type {win: integer, pos: {integer, integer}}|nil

-- User activity state
local last_activity_ms = uv.now()
local last_save_ms = uv.now()

-- Buffer ignore list
local ignored_buffers = {} ---@type table<integer, boolean>

-- ========================
-- Robust GHC/ghcid errorformat
-- ========================
M.efm = table.concat({
  -- == Errors ==

  -- Matches: /path/to/File.hs:(79,12)-(85,13): error: ...
  "%E%f:(%l,%c)-(%*[0-9],%*[0-9]): error: %m",
  "%E%f:(%l,%c)-(%*[0-9],%*[0-9]):error: %m", -- no-space variant

  -- Matches: /path/to/File.hs:45:12-16: error: ...
  "%E%f:%l:%c-%*[0-9]: error: %m",
  "%E%f:%l:%c-%*[0-9]:error: %m", -- no-space variant

  -- Matches: /path/to/File.hs:(79,12): error: ... (single tuple)
  "%E%f:(%l,%c): error: %m",
  "%E%f:(%l,%c):error: %m", -- no-space variant

  -- Matches: /path/to/File.hs:45:12: error: ... (simple col)
  "%E%f:%l:%c: error: %m",
  "%E%f:%l:%c:error: %m", -- no-space variant

  -- == Warnings ==

  -- Matches: /path/to/File.hs:(29,15)-(33,2): warning: ...
  "%W%f:(%l,%c)-(%*[0-9],%*[0-9]): warning: %m",
  "%W%f:(%l,%c)-(%*[0-9],%*[0-9]):warning: %m", -- no-space variant

  -- Matches: /path/to/File.hs:3:1-27: warning: ...
  "%W%f:%l:%c-%*[0-9]: warning: %m",
  "%W%f:%l:%c-%*[0-9]:warning: %m", -- no-space variant

  -- Matches: /path/to/File.hs:(29,15): warning: ... (single tuple)
  "%W%f:(%l,%c): warning: %m",
  "%W%f:(%l,%c):warning: %m", -- no-space variant

  -- Matches: /path/to/File.hs:3:1: warning: ... (simple col)
  "%W%f:%l:%c: warning: %m",
  "%W%f:%l:%c:warning: %m", -- no-space variant

  -- == Continuations (Order is important!) ==

  -- Matches: 45 |   botId <- query
  "%C%\\d%# | %m",

  -- Matches:    |            ^^^^^
  -- (Note: also catches `  | ^^^^^^^^^...` lines)
  "%C%\\s%#| %m",

  -- Matches:     • Couldn't match...
  "%C%\\s%#• %m",

  -- Matches:       from the context: ...
  -- (Catches any other indented line as a fallback)
  "%C%\\s%#%m",
}, ",")

-- ========================
-- ## Quickfix Helpers
-- ========================

--- Loads an error file into the quickfix list using the custom GHC errorformat.
--- @param errfile string The path to the error file.
local function cfile_with_ghc_efm(errfile)
  local prev = vim.o.errorformat
  vim.o.errorformat = M.efm
  vim.cmd(("silent keepjumps cfile %s"):format(vim.fn.fnameescape(errfile)))
  vim.o.errorformat = prev
end

--- Saves the current cursor position before a jump.
local function save_jump_origin()
  last_jump_origin = {
    win = vim.api.nvim_get_current_win(),
    pos = vim.api.nvim_win_get_cursor(0), -- {lnum, col}
  }
end

--- Safely jumps to a quickfix item by its index.
--- @param idx number The 1-based index in the quickfix list.
local function safe_jump_to_qf_item(idx)
  -- Save position *before* jumping
  save_jump_origin()

  vim.cmd("silent! cc " .. idx) -- Open buffer & rough pos
  local qf = vim.fn.getqflist()
  local it = qf[idx]
  if not it or not it.lnum or it.lnum == 0 then return end

  -- Ensure cursor is placed at the correct column
  local line = vim.api.nvim_get_current_line()
  local col0 = math.max(0, math.min((it.col or 1) - 1, #line))
  pcall(vim.api.nvim_win_set_cursor, 0, { it.lnum, col0 })
end

--- Finds the "best" item to jump to in the quickfix list.
--- @return string|nil signature A unique signature (e.g., "b:1:10:5") for the target.
--- @return number|nil index The 1-based index of the target in the QF list.
local function pick_target_signature()
  local qf = vim.fn.getqflist()
  local first_warn_idx = nil

  for i, it in ipairs(qf) do
    if it.type == "E" then -- First Error
      local id = it.bufnr and ("b:" .. it.bufnr) or ("f:" .. (it.filename or ""))
      return string.format("%s:%d:%d", id, it.lnum or 0, it.col or 0), i
    elseif not first_warn_idx and it.type == "W" then -- First Warning
      first_warn_idx = i
    end
  end

  if first_warn_idx then
    local it = qf[first_warn_idx]
    local id = it.bufnr and ("b:" .. it.bufnr) or ("f:" .. (it.filename or ""))
    return string.format("%s:%d:%d", id, it.lnum or 0, it.col or 0), first_warn_idx
  end

  return nil, nil
end

--- Jumps to the next/previous error in the quickfix list.
--- @param delta number 1 for next, -1 for previous.
local function qf_jump_error(delta)
  local qf = vim.fn.getqflist()
  if #qf == 0 then return end

  local cur = vim.fn.getqflist({ idx = 0 }).idx
  local i = cur + delta

  while i >= 1 and i <= #qf do
    if qf[i].type == "E" then
      safe_jump_to_qf_item(i)
      return
    end
    i = i + delta
  end

  vim.notify(delta > 0 and "No next error" or "No previous error", vim.log.levels.INFO)
end

-- ========================
-- ## Public Actions
-- ========================

--- Manually loads the error file and jumps to the first issue.
--- @param errfile string|nil Path to error file. Defaults to "errors.err".
function M.open_first_issue(errfile)
  errfile = errfile or "errors.err"
  if vim.fn.filereadable(errfile) ~= 1 then
    vim.notify(("No %s found"):format(errfile), vim.log.levels.WARN)
    return
  end

  cfile_with_ghc_efm(errfile)
  vim.cmd("cwindow") -- Open the quickfix window
  local _, idx = pick_target_signature()
  if idx then
    safe_jump_to_qf_item(idx)
  end
end

--- Jumps to the next error in the quickfix list.
function M.next_error()
  qf_jump_error(1)
end

--- Jumps to the previous error in the quickfix list.
function M.prev_error()
  qf_jump_error(-1)
end

--- Jumps back to the position before the last automatic jump.
function M.jump_back()
  if not last_jump_origin then
    vim.notify("ghcid-rocket: No jump origin stored.", vim.log.levels.WARN)
    return
  end

  local origin = last_jump_origin
  -- Restore window focus first
  pcall(vim.api.nvim_set_current_win, origin.win)
  -- Then restore cursor
  pcall(vim.api.nvim_win_set_cursor, origin.win, origin.pos)
  -- Clear the origin so we don't jump back multiple times by mistake
  last_jump_origin = nil
end

--- Adds the current buffer to the "no jump on save" list.
function M.ignore_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if ignored_buffers[bufnr] then
    vim.notify("ghcid-rocket: Buffer " .. bufnr .. " is already ignored.", vim.log.levels.INFO)
    return
  end
  ignored_buffers[bufnr] = true
  vim.notify("ghcid-rocket: Ignoring saves from buffer " .. bufnr .. ".", vim.log.levels.INFO)
end

--- Removes the current buffer from the "no jump on save" list.
function M.unignore_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if not ignored_buffers[bufnr] then
    vim.notify("ghcid-rocket: Buffer " .. bufnr .. " was not ignored.", vim.log.levels.INFO)
    return
  end
  ignored_buffers[bufnr] = nil
  vim.notify("ghcid-rocket: No longer ignoring saves from buffer " .. bufnr .. ".", vim.log.levels.INFO)
end

--- Clears the "no jump on save" list.
function M.clear_ignored_buffers()
  ignored_buffers = {}
  vim.notify("ghcid-rocket: Cleared all ignored buffers.", vim.log.levels.INFO)
end

-- ========================
-- ## User State & Jump Logic
-- ========================

--- Sets up autocmds to track user activity (movement, typing) and saves.
local function setup_user_state_tracking()
  if vim.g._ghcid_activity_autocmd then return end
  vim.g._ghcid_activity_autocmd = true

  local grp = vim.api.nvim_create_augroup("GhcidActivity", { clear = true })

  -- Track general activity
  for _, ev in ipairs({
    "CursorMoved", "CursorMovedI", "InsertEnter", "InsertLeave",
    "TextChanged", "TextChangedI", "ModeChanged",
  }) do
    vim.api.nvim_create_autocmd(ev, {
      group = grp,
      callback = function()
        last_activity_ms = uv.now()
      end,
      desc = "Track user activity for GhcidWatch",
    })
  end

  -- Track saves
  -- This is now restored to its simple, faithful version.
  -- It *always* records the last activity and save time.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = grp,
    pattern = "*",
    callback = function()
      local now = uv.now()
      last_activity_ms = now
      last_save_ms = now
    end,
    desc = "Track last save time for GhcidWatch",
  })
end

--- Implements the jump logic based on user state.
--- @return boolean true if the jump should be *prevented*, false if it should *proceed*.
local function should_prevent_jump()
  -- **NEW LOGIC: Rule 1**
  -- First, check if the user is currently in an ignored buffer.
  -- If so, *never* jump, regardless of other state.
  local current_bufnr = vim.api.nvim_get_current_buf()
  if ignored_buffers[current_bufnr] then
    return true -- Yes, prevent jump (in ignored buffer)
  end

  -- **ORIGINAL LOGIC: Rule 2**
  -- If not in an ignored buffer, proceed with the activity/save logic.
  local now = uv.now()
  local idle_ms_threshold = (vim.g.ghcid_watch_idle_ms or 200)

  local time_since_activity = now - last_activity_ms
  local time_since_save = now - last_save_ms

  local is_user_active = time_since_activity < idle_ms_threshold
  local is_recent_save = time_since_save < idle_ms_threshold

  -- We should NOT JUMP (prevent) *only* if:
  -- 1. The user is active (idle time < threshold)
  -- AND
  -- 2. The last save was NOT recent (save time >= threshold)
  if is_user_active and not is_recent_save then
    return true -- Yes, prevent jump (active, but not just saved)
  end

  -- Otherwise, we JUMP:
  -- Case 1: User is idle (is_user_active = false)
  -- Case 2: User is active AND just saved (is_user_active = true, is_recent_save = true)
  return false -- No, do not prevent jump
end

-- ========================
-- ## File Watcher
-- ========================

--- Starts watching the error file for changes.
--- @param errfile string|nil Path to error file. Defaults to "errors.err".
function M.watch(errfile)
  errfile = errfile or "errors.err"
  if watcher then
    watcher:stop()
    watcher = nil
  end

  watcher = uv.new_fs_poll()
  watcher:start(errfile, 300, vim.schedule_wrap(function()
    if vim.fn.filereadable(errfile) ~= 1 then return end
    if should_prevent_jump() then return end

    -- Reload the quickfix list from the file
    cfile_with_ghc_efm(errfile)

    local sig, idx = pick_target_signature() -- prefer first E else first W
    if not sig or not idx then
      last_sig = nil
      return
    end

    if sig ~= last_sig then
      safe_jump_to_qf_item(idx)
      last_sig = sig
    end
  end))

  vim.notify(("Watching %s for ghcid updates"):format(errfile))
end

--- Stops watching the error file.
function M.unwatch()
  if watcher then
    watcher:stop()
    watcher = nil
  end
  last_sig = nil
  vim.notify("Stopped watching ghcid output")
end

-- ========================
-- ## Setup
-- ========================

--- Main setup function, called by the user (e.g., from init.lua).
function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  setup_user_state_tracking()

  -- Register user commands
  vim.api.nvim_create_user_command("GQF", function(opts)
    M.open_first_issue(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GW", function(opts)
    M.watch(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GU", M.unwatch, {})

  -- New jump-back command
  vim.api.nvim_create_user_command("GB", M.jump_back, {})

  -- New ignore-buffer commands
  vim.api.nvim_create_user_command("GIB", M.ignore_current_buffer, {})
  vim.api.nvim_create_user_command("GUIB", M.unignore_current_buffer, {})
  vim.api.nvim_create_user_command("GCIB", M.clear_ignored_buffers, {})

  -- QF window settings for better readability
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.wo.wrap = true
      vim.wo.linebreak = true
      vim.wo.breakindent = true
    end,
  })

-- Optional status/debug helper
  vim.api.nvim_create_user_command("GWStatus", function()
    local idle_ms = (vim.g.ghcid_watch_idle_ms or 200)
    local now = uv.now()
    local since_activity = now - last_activity_ms
    local since_save = now - last_save_ms
    local is_active = since_activity < idle_ms
    local is_recent_save = since_save < idle_ms

    -- Add the new check
    local current_bufnr = vim.api.nvim_get_current_buf()
    local is_in_ignored_buffer = ignored_buffers[current_bufnr] or false

    local prevent_reason = "No"
    if is_in_ignored_buffer then
      prevent_reason = "YES (in ignored buffer)"
    elseif is_active and not is_recent_save then
      prevent_reason = "YES (active, no recent save)"
    end

    local ignore_count = 0
    for _ in pairs(ignored_buffers) do
      ignore_count = ignore_count + 1
    end

    vim.notify(string.format(
      "GhcidWatch Status:\n" ..
      "  Idle Threshold: %d ms\n" ..
      "  Since Activity: %d ms (Active? %s)\n" ..
      "  Since Save:     %d ms (Recent? %s)\n" ..
      "  Ignored Buffers: %d\n" ..
      "  In Ignored Buf?: %s\n" ..
      "  => Preventing Jump? %s",
      idle_ms,
      since_activity, is_active and "YES" or "no",
      since_save, is_recent_save and "YES" or "no",
      ignore_count,
      is_in_ignored_buffer and "YES" or "no",
      prevent_reason
    ))
  end, {})
end

return M
