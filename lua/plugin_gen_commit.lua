require('gen_commit').setup({
  default_backend = "ollama", -- or "llm"
  backends = {
    ollama = {
      ssh_host = "AsukaLocal",
      model    = "qwen3:30b",
      args     = { "--hidethinking" },
    },
    llm = {
      cmd   = "llm",
      model = "gpt-5-nano",
      args  = {}, -- add flags if you like
    },
  },
})
