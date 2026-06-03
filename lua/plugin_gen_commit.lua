require('gen_commit').setup({
  default_backend = "ollama", -- or "llm"
  backends = {
    ollama = {
      ssh_host = "AsukaLocal",
      model    = "glm-5.1:cloud",
      args     = { "--hidethinking" },
    },
    llm = {
      cmd   = "llm",
      model = "gpt-5-nano",
      args  = {}, -- add flags if you like
    },
  },
})
