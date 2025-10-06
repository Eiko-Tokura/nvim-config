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
-- Commands: load QF from errors.err and jump smartly
-- =========================

-- Load the file, open quickfix, and jump to the first *error* if any, else first item.
local function qf_open_first_error(errfile)
  errfile = errfile or "errors.err"
  if vim.fn.filereadable(errfile) ~= 1 then
    vim.notify(("No %s found"):format(errfile), vim.log.levels.WARN)
    return
  end
  vim.cmd(("silent cfile %s"):format(errfile))
  vim.cmd("cwindow")
  local qf = vim.fn.getqflist()
  for i, it in ipairs(qf) do
    if it.type == "E" then
      vim.cmd("cc " .. i)
      return
    end
  end
  -- Fallback: just go to the first entry
  if #qf > 0 then vim.cmd("cc 1") end
end

vim.api.nvim_create_user_command("GhcidQF", function(opts)
  qf_open_first_error(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })  -- optional arg: path to the err file

-- Next/prev *error* (skip warnings)
local function qf_jump_error(delta)
  local qfl = vim.fn.getqflist()
  if #qfl == 0 then return end
  local cur = vim.fn.getqflist({ idx = 0 }).idx
  local i = cur + delta
  while i >= 1 and i <= #qfl do
    if qfl[i].type == "E" then
      vim.cmd("cc " .. i)
      return
    end
    i = i + delta
  end
  vim.notify(delta > 0 and "No next error" or "No previous error", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("QfNextError", function() qf_jump_error(1) end, {})
vim.api.nvim_create_user_command("QfPrevError", function() qf_jump_error(-1) end, {})

-- Nice keys (buffer-local)
vim.keymap.set("n", "<leader>e", function() qf_open_first_error() end,
  { buffer = true, silent = true, desc = "Load ghcid errors and jump to first error" })
vim.keymap.set("n", "]e", "<cmd>QfNextError<CR>", { buffer = true, silent = true, desc = "Next error" })
vim.keymap.set("n", "[e", "<cmd>QfPrevError<CR>", { buffer = true, silent = true, desc = "Prev error" })

-- =========================
-- Optional: auto-refresh when errors.err changes
-- =========================
-- Call :GhcidWatch (and :GhcidUnwatch) if you like live updates.
local watcher
vim.api.nvim_create_user_command("GhcidWatch", function(opts)
  local errfile = opts.args ~= "" and opts.args or "errors.err"
  if watcher then watcher:stop(); watcher = nil end
  local uv = vim.loop
  watcher = uv.new_fs_poll()
  watcher:start(errfile, 300, vim.schedule_wrap(function()
    -- Refill quickfix but keep your cursor where it is unless there are no errors yet.
    local had = vim.fn.getqflist({ size = 0 }).size > 0
    vim.cmd(("silent cfile %s"):format(errfile))
    if not had then qf_open_first_error(errfile) end
  end))
  vim.notify(("Watching %s for ghcid updates"):format(errfile))
end, { nargs = "?" })

vim.api.nvim_create_user_command("GhcidUnwatch", function()
  if watcher then watcher:stop(); watcher = nil; vim.notify("Stopped watching errors.err") end
end, {})
