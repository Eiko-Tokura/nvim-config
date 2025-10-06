-- ghcid_rocket/init.lua
local M = {}

-- Robust GHC/ghcid errorformat (supports :l:c, :l:c-c2, (l,c)-(l2,c2))
M.efm = table.concat({
  -- Errors
  "%E%f:%l:%c: %trror: %m",
  "%E%f:%l:%c-%*[0-9]: %trror: %m",
  "%E%f:(%l,%c)-(%*\\d,%*\\d): %trror: %m",
  -- Warnings
  "%W%f:%l:%c: %tarning: %m",
  "%W%f:%l:%c-%*[0-9]: %tarning: %m",
  "%W%f:(%l,%c)-(%*\\d,%*\\d): %tarning: %m",
  -- Continuations (indented lines incl. bullets and carets)
  "%C%\\s%#%m",
}, ",")

-- ---------- helpers ----------
local function cfile_with_ghc_efm(errfile)
  local prev = vim.o.errorformat
  vim.o.errorformat = M.efm
  vim.cmd(("silent keepjumps cfile %s"):format(errfile))
  vim.o.errorformat = prev
end

local function safe_jump_to_qf_item(idx)
  vim.cmd("silent! cc " .. idx) -- open buffer & rough pos
  local qf = vim.fn.getqflist()
  local it = qf[idx]
  if not it or not it.lnum then return end
  local line = vim.api.nvim_get_current_line()
  local col0 = math.max(0, math.min((it.col or 1) - 1, #line))
  pcall(vim.api.nvim_win_set_cursor, 0, { it.lnum, col0 })
end

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

-- ---------- public actions ----------
function M.open_first_issue(errfile)
  errfile = errfile or "errors.err"
  if vim.fn.filereadable(errfile) ~= 1 then
    vim.notify(("No %s found"):format(errfile), vim.log.levels.WARN)
    return
  end
  cfile_with_ghc_efm(errfile)
  vim.cmd("cwindow")
  local _, idx = pick_target_signature()
  if idx then safe_jump_to_qf_item(idx) end
end

function M.next_error() qf_jump_error(1) end
function M.prev_error() qf_jump_error(-1) end

-- ---------- activity tracking (skip auto-jumps while you're active) ----------
local uv = vim.loop
local last_activity_ms = uv.now()

local function setup_activity_autocmd()
  if vim.g._ghcid_activity_autocmd then return end
  vim.g._ghcid_activity_autocmd = true
  local grp = vim.api.nvim_create_augroup("GhcidActivity", { clear = true })
  for _, ev in ipairs({
    "CursorMoved", "CursorMovedI", "InsertEnter", "InsertLeave",
    "TextChanged", "TextChangedI", "ModeChanged",
  }) do
    vim.api.nvim_create_autocmd(ev, {
      group = grp,
      callback = function() last_activity_ms = uv.now() end,
      desc = "Track user activity for GhcidWatch",
    })
  end
end

local function user_is_active()
  local idle_ms = (vim.g.ghcid_watch_idle_ms or 200)
  return (uv.now() - last_activity_ms) < idle_ms
end

-- ---------- watcher ----------
local watcher, last_sig

function M.watch(errfile)
  errfile = errfile or "errors.err"
  if watcher then watcher:stop(); watcher = nil end

  watcher = uv.new_fs_poll()
  watcher:start(errfile, 300, vim.schedule_wrap(function()
    if vim.fn.filereadable(errfile) ~= 1 then return end
    cfile_with_ghc_efm(errfile)                 -- refresh QF with correct efm
    local sig, idx = pick_target_signature()    -- prefer first E else first W
    if not sig or not idx then last_sig = nil; return end
    if user_is_active() then return end         -- do not jump if you're busy
    if sig ~= last_sig then
      safe_jump_to_qf_item(idx)
      last_sig = sig
    end
  end))

  vim.notify(("Watching %s for ghcid updates"):format(errfile))
end

function M.unwatch()
  if watcher then watcher:stop(); watcher = nil end
  last_sig = nil
  vim.notify("Stopped watching ghcid output")
end

-- ---------- setup (commands + qf window tweaks) ----------
function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  setup_activity_autocmd()

  vim.api.nvim_create_user_command("GhcidQF", function(opts)
    M.open_first_issue(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GhcidWatch", function(opts)
    M.watch(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GhcidUnwatch", function()
    M.unwatch()
  end, {})

  -- QF window: show multi-line entries; keep default continuation "|| ..." lines
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
      vim.wo.wrap        = true
      vim.wo.linebreak   = true
      vim.wo.breakindent = true
      -- DO NOT touch quickfixtextfunc here; it's a GLOBAL option.
      -- Leaving it nil preserves multi-line continuation lines.
    end,
  })
end

return M
