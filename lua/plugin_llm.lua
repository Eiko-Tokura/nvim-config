local llm = require('llm')

llm.setup({
  model = "deepseek-r1:14b", -- Model you want to use
  url = "http://10.52.1.55:11434",
  api_type = "openai",
  -- cf https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
  request_body = {
    -- Modelfile options for the model you use
    options = {
      temperature = 0.2,
      top_p = 0.95,
    }
  }
})
