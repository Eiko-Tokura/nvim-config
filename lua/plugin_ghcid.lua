-- =========================
-- Robust GHC/ghcid errorformat
-- =========================
-- Covers:
--   /path/File.hs:45:12: error: ...
--   /path/File.hs:45:12-16: error: ...
--   /path/File.hs:(45,12)-(47,2): error: ...
-- and same for warnings. Continuations (indented lines and caret bars) are attached.

local efm = table.concat({
  -- Errors (single col, col range, tuple spans)
  "%E%f:%l:%c: %trror: %m",
  "%E%f:%l:%c-%*[0-9]: %trror: %m",
  "%E%f:(%l,%c)-(%*\\d,%*\\d): %trror: %m",

  -- Warnings (single col, col range, tuple spans)
  "%W%f:%l:%c: %tarning: %m",
  "%W%f:%l:%c-%*[0-9]: %tarning: %m",
  "%W%f:(%l,%c)-(%*\\d,%*\\d): %tarning: %m",

  -- Continuation: any indented line (includes "• ..." and the caret blocks with pipes)
  "%C%\\s%#%m",
}, ",")

-- Only set for Haskell buffers so we don't break other languages
vim.opt_local.errorformat = efm

-- =========================
-- Commands + smarter watcher (no deferred jumps)
-- =========================

-- Jump helper that also moves to the exact column
local function safe_jump_to_qf_item(idx)
  vim.cmd("silent! cc " .. idx) -- open buffer + rough pos
  local qf = vim.fn.getqflist()
  local it = qf[idx]
  if not it or not it.lnum then return end
  local line = vim.api.nvim_get_current_line()
  local col0 = math.max(0, math.min((it.col or 1) - 1, #line))
  pcall(vim.api.nvim_win_set_cursor, 0, { it.lnum, col0 })
end

-- Prefer first error; if none, first warning. Return signature + index.
local function pick_target_signature()
  local qf = vim.fn.getqflist()
  local first_warn
  for i, it in ipairs(qf) do
    if it.type == "E" then
      local id = it.bufnr and ("b:"..it.bufnr) or ("f:"..(it.filename or ""))
      return string.format("%s:%d:%d", id, it.lnum or 0, it.col or 0), i
    elseif not first_warn and it.type == "W" then
      first_warn = { it = it, idx = i }
    end
  end
  if first_warn then
    local it = first_warn.it
    local id = it.bufnr and ("b:"..it.bufnr) or ("f:"..(it.filename or ""))
    return string.format("%s:%d:%d", id, it.lnum or 0, it.col or 0), first_warn.idx
  end
  return nil, nil
end

-- Load file -> open quickfix -> jump to first error, else first warning (exact column)
local function qf_open_first_issue(errfile)
  errfile = errfile or "errors.err"
  if vim.fn.filereadable(errfile) ~= 1 then
    vim.notify(("No %s found"):format(errfile), vim.log.levels.WARN)
    return
  end
  vim.cmd(("silent cfile %s"):format(errfile))
  vim.cmd("cwindow")
  local sig, idx = pick_target_signature()
  if idx then safe_jump_to_qf_item(idx) end
end

vim.api.nvim_create_user_command("GhcidQF", function(opts)
  qf_open_first_issue(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

-- Next/prev *error only* (kept as-is, exact column)
local function qf_jump_error(delta)
  local qf = vim.fn.getqflist()
  if #qf == 0 then return end
  local cur = vim.fn.getqflist({ idx = 0 }).idx
  local i = cur + delta
  while i >= 1 and i <= #qf do
    if qf[i].type == "E" then
      safe_jump_to_qf_item(i); return
    end
    i = i + delta
  end
  vim.notify(delta > 0 and "No next error" or "No previous error", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("QfNextError", function() qf_jump_error(1) end, {})
vim.api.nvim_create_user_command("QfPrevError", function() qf_jump_error(-1) end, {})

-- Keys (buffer-local)
vim.keymap.set("n", "<leader>e", function() qf_open_first_issue() end,
  { buffer = true, silent = true, desc = "Load ghcid diagnostics and jump (E else W)" })
vim.keymap.set("n", "]e", "<cmd>QfNextError<CR>", { buffer = true, silent = true, desc = "Next error" })
vim.keymap.set("n", "[e", "<cmd>QfPrevError<CR>", { buffer = true, silent = true, desc = "Prev error" })

-- =========================
-- “Active” detection (skip jumps while you’re moving/typing)
-- =========================
local uv = vim.loop
local last_activity_ms = uv.now()

if not vim.g._ghcid_activity_autocmd then
  vim.g._ghcid_activity_autocmd = true
  vim.api.nvim_create_augroup("GhcidActivity", { clear = true })
  for _, ev in ipairs({
    "CursorMoved", "CursorMovedI",
    "InsertEnter", "InsertLeave",
    "TextChanged", "TextChangedI",
    "ModeChanged",
  }) do
    vim.api.nvim_create_autocmd(ev, {
      group = "GhcidActivity",
      callback = function() last_activity_ms = uv.now() end,
      desc = "Track user activity for GhcidWatch",
    })
  end
end

-- Consider “active” if you moved/typed within this many ms (tweakable)
-- e.g. vim.g.ghcid_watch_idle_ms = 200
local function user_is_active()
  local idle_ms = (vim.g.ghcid_watch_idle_ms or 200)
  return (uv.now() - last_activity_ms) < idle_ms
end

-- =========================
-- Watcher: no deferred jumps; skip if active; jump to E else W
-- =========================
local watcher, last_sig

vim.api.nvim_create_user_command("GhcidWatch", function(opts)
  local errfile = opts.args ~= "" and opts.args or "errors.err"
  if watcher then watcher:stop(); watcher = nil end

  watcher = uv.new_fs_poll()
  watcher:start(errfile, 300, vim.schedule_wrap(function()
    if vim.fn.filereadable(errfile) ~= 1 then return end
    vim.cmd(("silent cfile %s"):format(errfile))  -- refresh QF
    local sig, idx = pick_target_signature()
    if not sig or not idx then
      last_sig = nil
      return
    end
    if user_is_active() then
      -- You’re busy; do not jump, and do not update last_sig.
      return
    end
    if sig ~= last_sig then
      safe_jump_to_qf_item(idx)
      last_sig = sig
    end
  end))

  vim.notify(("Watching %s for ghcid updates"):format(errfile))
end, { nargs = "?" })

vim.api.nvim_create_user_command("GhcidUnwatch", function()
  if watcher then watcher:stop(); watcher = nil end
  last_sig = nil
  vim.notify("Stopped watching errors.err")
end, {})
