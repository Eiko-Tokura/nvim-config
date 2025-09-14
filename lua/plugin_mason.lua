require("mason").setup()
require("mason-lspconfig").setup()

require("mason-lspconfig").setup {
  ensure_installed = {
    "pyrefly"
  },
}
