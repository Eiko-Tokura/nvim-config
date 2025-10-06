-- auto-register commands on startup
require("ghcid_rocket").setup()

-- Haskell-only tweaks (buffer-local)
local ok, ghcid = pcall(require, "ghcid_rocket")
if ok then
  -- Use robust efm in this buffer (parsing is also forced during :cfile)
  vim.opt_local.errorformat = ghcid.efm
end

-- Handy keys (buffer-local)
vim.keymap.set("n", "<leader>e", ":GhcidQF<CR>",
  { buffer = true, silent = true, desc = "Load ghcid QF (Error else Warning) and jump" })
vim.keymap.set("n", "]e", ":QfNextError<CR>", { buffer = true, silent = true, desc = "Next error" })
vim.keymap.set("n", "[e", ":QfPrevError<CR>", { buffer = true, silent = true, desc = "Prev error" })

-- Optional: how long you need to be idle before watcher may auto-jump (ms).
-- The watcher NEVER queues a deferred jump; it simply skips if you're active.
-- Example:
-- vim.g.ghcid_watch_idle_ms = 200
