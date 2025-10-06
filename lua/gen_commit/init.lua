-- lua/gen_commit/init.lua
local M = {}

-- ---------- Configuration ----------
local defaults = {
  -- Which backend :GenCommit should use: "ollama" or "llm"
  default_backend  = "ollama",

  -- Global behavior
  max_diff_bytes   = 200000,      -- fall back to summary if diff is huge
  conventional     = true,        -- ask for Conventional Commits style
  open_in_scratch  = true,        -- open a scratch gitcommit buffer when needed
  notify           = true,        -- show notifications
  timeout_ms       = 180000,      -- 3 minutes

  -- Per-backend configs
  backends = {
    -- Remote Ollama via SSH (reads prompt from stdin, writes raw stdout)
    ollama = {
      ssh_host   = "AsukaLocal",
      model      = "qwen3:30b",
      args       = { "--hidethinking" },  -- keep model’s thoughts out of stdout
      -- If you run Ollama locally, set ssh_host = nil and it will run without ssh.
    },

    -- "llm" CLI (e.g. pip install llm — uses OpenAI etc.)
    -- We send prompt via stdin and read raw stdout.
    llm = {
      cmd       = "llm",
      model     = "gpt-4o-mini",  -- change to your preferred model
      args      = {},             -- add flags if you like; keep simple for stdin/stdout
    },
  },
}

local cfg = vim.deepcopy(defaults)

-- Pretty multi-line quickfix rendering that preserves continuation lines
_G.GhcidRocketQFTF = function(info)
  local qf = vim.fn.getqflist({ id = info.id, items = 1 }).items
  local out = {}
  for i = info.start_idx, info.end_idx do
    local it = qf[i] or {}
    local text = it.text or ""
    if it.valid == 1 and (it.lnum or 0) > 0 then
      local fname = it.filename ~= "" and it.filename or vim.fn.bufname(it.bufnr or 0)
      local typ = (it.type == "E" and "error") or (it.type == "W" and "warning") or ""
      local lnum = it.lnum or 0
      local col  = it.col or 0
      -- Header line (keep it compact; you can drop 'col %d' if you prefer)
      out[#out+1] = string.format("%s|%d col %d %s| %s", fname, lnum, col, typ, text)
    else
      -- Continuation lines (from %C) — show as multi-line with "|| "
      out[#out+1] = "|| " .. text
    end
  end
  return out
end

function M.setup(opts)
  if opts then
    -- shallow-merge top-level, then merge backends if provided
    for k, v in pairs(opts) do
      if k == "backends" and type(v) == "table" then
        for bk, bv in pairs(v) do
          cfg.backends[bk] = vim.tbl_deep_extend("force", cfg.backends[bk] or {}, bv)
        end
      else
        cfg[k] = v
      end
    end
  end

  vim.api.nvim_create_user_command("GenCommit", function()
    M.gen_commit({ backend = cfg.default_backend, commit_now = false })
  end, {})

  vim.api.nvim_create_user_command("GenCommitNow", function()
    M.gen_commit({ backend = cfg.default_backend, commit_now = true })
  end, {})

  vim.api.nvim_create_user_command("GenCommitOllama", function()
    M.gen_commit({ backend = "ollama", commit_now = false })
  end, {})

  vim.api.nvim_create_user_command("GenCommitNowOllama", function()
    M.gen_commit({ backend = "ollama", commit_now = true })
  end, {})

  vim.api.nvim_create_user_command("GenCommitLLM", function()
    M.gen_commit({ backend = "llm", commit_now = false })
  end, {})

  vim.api.nvim_create_user_command("GenCommitNowLLM", function()
    M.gen_commit({ backend = "llm", commit_now = true })
  end, {})

  -- Optional mapping examples:
  -- vim.keymap.set("n", "<leader>gc", function() M.gen_commit() end, { desc = "Generate commit message" })
  -- vim.keymap.set("n", "<leader>gC", function() M.gen_commit({ commit_now = true }) end, { desc = "Generate & commit" })
end

-- ---------- Utilities ----------
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function notify(level, msg)
  if not cfg.notify then return end
  vim.notify(msg, level or vim.log.levels.INFO, { title = "GenCommit" })
end

local function has_vim_system()
  return type(vim.system) == "function"
end

local function run_cmd(cmd, opts)
  opts = opts or {}
  if has_vim_system() then
    local res = vim.system(cmd, {
      text    = true,
      stdin   = opts.stdin or nil,
      timeout = cfg.timeout_ms,
      cwd     = opts.cwd,
    }):wait()
    return res.code, res.stdout or "", res.stderr or ""
  else
    -- Neovim < 0.10 fallback
    local cmdline = table.concat(cmd, " ")
    local out = vim.fn.system(cmdline, opts.stdin or "")
    local code = vim.v.shell_error
    local err = code ~= 0 and out or ""
    return code, out or "", err or ""
  end
end

local function git_ok()
  local code = run_cmd({ "git", "rev-parse", "--is-inside-work-tree" })
  return code == 0
end

local function staged_any()
  local code, out = run_cmd({ "git", "diff", "--cached", "--name-only" })
  if code ~= 0 then return false end
  return trim(out) ~= ""
end

local function get_repo_info()
  local _, root = run_cmd({ "git", "rev-parse", "--show-toplevel" })
  local _, branch = run_cmd({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
  return trim(root), trim(branch)
end

local function get_staged_diff(max_bytes)
  local code, diff = run_cmd({ "git", "diff", "--cached", "--no-color", "-U3" })
  if code ~= 0 then
    return nil, "Failed to read staged diff."
  end
  if #diff <= max_bytes then
    return diff, nil
  end
  -- Fallback to compact summaries if the diff is very large
  local _, stat  = run_cmd({ "git", "diff", "--cached", "--stat" })
  local _, names = run_cmd({ "git", "diff", "--cached", "--name-status" })
  local summary = ("[DIFF TOO LARGE — using summaries]\n\n[NAME-STATUS]\n%s\n[STAT]\n%s"):format(trim(names), trim(stat))
  return summary, nil
end

local function build_prompt(repo_root, branch, diff)
  local rules
  if cfg.conventional then
    rules = [[
Follow Conventional Commits. Output ONLY the commit message text.
Format:
type(scope?): subject

Body lines wrapped to ~72 chars explaining what/why.
Use imperative mood. Include "BREAKING CHANGE:" if relevant.
No code fences, no roles, no markdown, no extra commentary.
]]
  else
    rules = [[
Write a clear commit subject (< 72 chars), then a wrapped body (~72 chars/line)
explaining what and why. Output ONLY the commit message text. No code fences or extra commentary.
]]
  end

  return ([[
You write excellent Git commit messages from diffs.

Repository: %s
Branch: %s

Rules:
%s

Here is the staged diff (or summary):
<diff>
%s
</diff>
]]):format(repo_root, branch, rules, diff)
end

-- Try to clean up common wrappers if a model still adds them.
local function sanitize_output(s)
  s = s or ""
  s = s:gsub("^%s*[Rr]ole:%s*assistant%s*\n", "")
       :gsub("^%s*[Aa]ssistant:%s*", "")
       :gsub("^%s*Here is the commit message:?%s*\n+", "")
       :gsub("^%s*Commit message:?%s*\n+", "")
  local inner = s:match("^%s*```[%w%-_]*%s*\n(.-)\n```%s*$")
  if inner then s = inner end
  s = s:gsub("```+", "")
  return trim(s)
end

local function ensure_gitcommit_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local name = vim.api.nvim_buf_get_name(bufnr)
  local in_commit_msg = (ft == "gitcommit") or name:match("COMMIT_EDITMSG")
  if in_commit_msg then return bufnr end

  if not cfg.open_in_scratch then return bufnr end
  local newbuf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(newbuf)
  vim.bo[newbuf].buftype = ""
  vim.bo[newbuf].bufhidden = ""
  vim.bo[newbuf].swapfile = false
  vim.bo[newbuf].filetype = "gitcommit"
  vim.api.nvim_buf_set_name(newbuf, "commit-message (generated)")
  return newbuf
end

local function write_to_buffer(text)
  local bufnr = ensure_gitcommit_buffer()
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do table.insert(lines, line) end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, {1, 0})
end

-- ---------- Backend runners ----------
local function run_backend_ollama(prompt)
  local b = cfg.backends.ollama or {}
  local cmd
  if b.ssh_host and b.ssh_host ~= "" then
    cmd = { "ssh", b.ssh_host, "ollama", "run", b.model }
  else
    cmd = { "ollama", "run", b.model }
  end
  for _, a in ipairs(b.args or {}) do table.insert(cmd, a) end

  local code, out, err = run_cmd(cmd, { stdin = prompt })
  if code ~= 0 then
    return nil, ("Ollama failed (%d): %s"):format(code, trim(err ~= "" and err or out))
  end
  local msg = sanitize_output(out)
  if msg == "" then return nil, "Empty response from Ollama." end
  return msg, nil
end

local function run_backend_llm(prompt)
  local b = cfg.backends.llm or {}
  local cmd = { b.cmd or "llm" }
  if b.model and b.model ~= "" then
    table.insert(cmd, "-m"); table.insert(cmd, b.model)
  end
  for _, a in ipairs(b.args or {}) do table.insert(cmd, a) end
  -- The llm tool should read prompt from stdin and write the completion to stdout
  local code, out, err = run_cmd(cmd, { stdin = prompt })
  if code ~= 0 then
    return nil, ("llm failed (%d): %s"):format(code, trim(err ~= "" and err or out))
  end
  local msg = sanitize_output(out)
  if msg == "" then return nil, "Empty response from llm CLI." end
  return msg, nil
end

local function run_backend(backend, prompt)
  if backend == "ollama" then
    return run_backend_ollama(prompt)
  elseif backend == "llm" then
    return run_backend_llm(prompt)
  else
    return nil, "Unknown backend: " .. tostring(backend)
  end
end

local function commit_now(message)
  local code, out, err = run_cmd({ "git", "commit", "-F", "-" }, { stdin = message })
  if code ~= 0 then
    return false, trim(err ~= "" and err or out)
  end
  return true, trim(out)
end

-- ---------- Public: main entry ----------
function M.gen_commit(opts)
  opts = opts or {}
  local backend = opts.backend or cfg.default_backend or "ollama"

  if not git_ok() then
    notify(vim.log.levels.ERROR, "Not inside a Git repository.")
    return
  end
  if not staged_any() then
    notify(vim.log.levels.WARN, "No staged changes. Stage files first (git add).")
    return
  end

  local root, branch = get_repo_info()
  local diff, derr = get_staged_diff(cfg.max_diff_bytes)
  if not diff then
    notify(vim.log.levels.ERROR, derr or "Failed to get diff.")
    return
  end

  local prompt = (function()
    local p = build_prompt(root, branch, diff)
    return p
  end)()

  notify(vim.log.levels.INFO, ("Asking %s for commit message…"):format(backend))
  local message, lerr = run_backend(backend, prompt)
  if not message then
    notify(vim.log.levels.ERROR, lerr or "Backend error.")
    return
  end

  if opts.commit_now then
    local ok, res = commit_now(message)
    if ok then
      notify(vim.log.levels.INFO, "Committed:\n" .. res)
    else
      notify(vim.log.levels.ERROR, "git commit failed:\n" .. res)
      write_to_buffer(message) -- fall back to buffer
    end
  else
    write_to_buffer(message)
    notify(vim.log.levels.INFO, "Commit message inserted. Review & save/commit.")
  end
end

return M
