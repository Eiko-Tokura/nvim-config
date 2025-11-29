local M = {}

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                            CONFIGURATION                              ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

M.profiles = {
  default = { adapter = "sqlite_ssh", host = "Asuka", db_path = "/opt/meowbot/meowbot.db" },
  prod    = { adapter = "pg_ssh",     host = "Asuka", user = "postgres", db_name = "production_db", format = "aligned" },
  dev     = { adapter = "pg_local",   user = "postgres", db_name = "dev_db" },
}

M.ui = {
  sep_start = "/*--- Result: %s -----",
  sep_end   = "----- End Result ---*/",
}

M.state = { last_scratch_buf = nil }

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                       1. PURE LOGIC (The Brains)                      ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

--[[ 
  choose_profile(explicit, pinned, fallback) -> string
  Decides which profile to use based on precedence.
  Pure function: knows nothing about Vim, buffers, or global state.
]]
local function choose_profile(explicit, pinned, fallback)
  if explicit and explicit ~= "" then 
    return explicit 
  end
  if pinned and pinned ~= "" then 
    return pinned 
  end
  return fallback or "default"
end

local adapters = {}

function adapters.sqlite_ssh(p)
  return { "ssh", p.host, "sqlite3", p.db_path }
end

function adapters.pg_local(p)
  local cmd = { "psql", "-U", p.user, "-d", p.db_name, "-q" }
  if p.format == "expanded" then table.insert(cmd, "-x") end
  return cmd
end

function adapters.pg_ssh(p)
  local psql_flags = "-U " .. p.user .. " -d " .. p.db_name .. " -q"
  if p.format == "expanded" then psql_flags = psql_flags .. " -x" end
  return { "ssh", p.host, "psql " .. psql_flags }
end

local function format_output(raw_text, profile_name)
  local clean = raw_text:gsub("\n+$", "")
  if clean == "" then clean = "(No output)" end
  local lines = vim.split(clean, "\n", { plain = true })
  
  local out = {}
  if M.ui.sep_start then table.insert(out, string.format(M.ui.sep_start, profile_name)) end
  for _, line in ipairs(lines) do table.insert(out, line) end
  if M.ui.sep_end then table.insert(out, M.ui.sep_end) end
  return out
end

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                       2. IMPURE SINKS (The Body)                      ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

local sinks = {}

local function get_scratch()
  if M.state.last_scratch_buf and vim.api.nvim_buf_is_valid(M.state.last_scratch_buf) then
    return M.state.last_scratch_buf
  end
  vim.cmd("new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "sql"
  M.state.last_scratch_buf = buf
  return buf
end

function sinks.scratch(lines)
  local buf = get_scratch()
  if #vim.fn.win_findbuf(buf) == 0 then vim.cmd("split | b" .. buf) end
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

function sinks.new_split(lines)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "sql"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function sinks.inline(lines)
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                       3. COORDINATOR (The Shell)                      ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

function M.run(opts)
  -- A. GATHER STATE (Impure)
  -- We extract all necessary state from the "world" here.
  local arg_profile = opts.args
  local buf_profile = vim.b.sql_profile
  local default_profile = "default"
  local input_range = opts.range or { 0, -1 }

  -- B. DECIDE (Pure)
  -- We pass the gathered state to the pure function.
  local profile_key = choose_profile(arg_profile, buf_profile, default_profile)

  -- C. VALIDATE & PREPARE
  local profile = M.profiles[profile_key]
  if not profile then
    return vim.notify("Unknown SQL profile: " .. tostring(profile_key), vim.log.levels.ERROR)
  end

  local cmd_builder = adapters[profile.adapter]
  if not cmd_builder then
    return vim.notify("Unknown adapter: " .. profile.adapter, vim.log.levels.ERROR)
  end
  local cmd = cmd_builder(profile)

  -- D. EXECUTE (Impure/Async)
  local s, e = unpack(input_range)
  local input_sql = table.concat(vim.api.nvim_buf_get_lines(0, s, e, false), "\n")

  vim.system(cmd, { stdin = input_sql, text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        vim.notify("SQL Error:\n" .. obj.stderr, vim.log.levels.ERROR)
        if obj.stdout == "" then return end
      end

      local formatted_lines = format_output(obj.stdout, profile_key)
      local sink_fn = sinks[opts.target] or sinks.scratch
      sink_fn(formatted_lines)
    end)
  end)
end

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║                           COMMAND SETUP                               ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

local function get_range(o)
  if o.range == 0 then return nil end
  return { o.line1 - 1, o.line2 }
end

-- Commands passing args down to M.run
vim.api.nvim_create_user_command("SQL", function(o)
  M.run { range = get_range(o), target = "scratch", args = o.args }
end, { range = true, nargs = "?" })

vim.api.nvim_create_user_command("SQLN", function(o)
  M.run { range = get_range(o), target = "new_split", args = o.args }
end, { range = true, nargs = "?" })

vim.api.nvim_create_user_command("SQLH", function(o)
  M.run { range = get_range(o), target = "inline", args = o.args }
end, { range = true, nargs = "?" })

-- SetSQL: Only updates the buffer state (vim.b.sql_profile)
vim.api.nvim_create_user_command("SetSQL", function(o)
  local name = o.args
  if not M.profiles[name] then
    return vim.notify("Profile '" .. name .. "' does not exist.", vim.log.levels.ERROR)
  end
  vim.b.sql_profile = name
  vim.notify("Buffer pinned to SQL profile: " .. name)
end, {
  nargs = 1,
  complete = function() return vim.tbl_keys(M.profiles) end,
})

return M
