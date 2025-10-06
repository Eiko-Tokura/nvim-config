Run

```
:PlugInstall
```

The `lua/essential.lua` file is the most important configuration (basic keybinds) that are plugin independent. I think you will want it in all of your neovim machines. Check it out!

## Major Functionality

This repository provides a Neovim configuration focused on improving editing workflows for code, writing, and project collaboration. Key features include:

- Core editing experience: basic keybinds and autoreload when files change outside Neovim (already in config).
- Language support: enhanced syntax highlighting and LSP via nvim-treesitter and Mason; quick actions via LSP mapping.
- AI-assisted coding and commit generation: GenCommit commands to generate git commit messages from diffs using Ollama or llm; commands available: `:GenCommit`, `:GenCommitNow`, `:GenCommitOllama`, `:GenCommitNowOllama`, `:GenCommitLLM`, `:GenCommitNowLLM`.
- Opencode integration: quick access to an AI assistant for code understanding; keymaps in `lua/plugin_opencode.lua`.
- Git tooling: `gitsigns` for inline git info, and an optional `ghcid` integration for Haskell live feedback (`plugin_ghcid.lua`).
- TeX/LaTeX: shortcuts and templates to accelerate TeX editing (`latex-shortcuts.lua`, `texcommands.lua`).
- Markdown support: syntax and editing improvements for Markdown (`after/syntax/markdown.vim`).

## Major Functionality

This repository provides a Neovim configuration focused on improving editing workflows for code, writing, and project collaboration. Key features include:

- Core editing experience: basic keybinds and autoreload when files change outside Neovim (already in config).
- Language support: enhanced syntax highlighting and LSP via nvim-treesitter and Mason; quick actions via LSP mapping.
- AI-assisted coding and commit generation: GenCommit commands to generate git commit messages from diffs using Ollama or llm; commands available: `:GenCommit`, `:GenCommitNow`, `:GenCommitOllama`, `:GenCommitNowOllama`, `:GenCommitLLM`, `:GenCommitNowLLM`.
- Opencode integration: quick access to an AI assistant for code understanding; keymaps in `lua/plugin_opencode.lua`.
- Git tooling: `gitsigns` for inline git info, and an optional `ghcid` integration for Haskell live feedback (`plugin_ghcid.lua`).
- TeX/LaTeX: shortcuts and templates to accelerate TeX editing (`latex-shortcuts.lua`, `texcommands.lua`).
- Markdown support: syntax and editing improvements for Markdown (`after/syntax/markdown.vim`).

## Quick Start

- Run `:PlugInstall` to install plugins.
- Open Neovim and start editing; see core keybinds in `lua/essential.lua`.
- For commit messages: stage changes, then use `:GenCommit` (or `:GenCommitNow`) to generate a message, then commit.
- For LaTeX: in TeX files use LaTeX shortcuts (e.g., `;al`, `;;en`) and commands `:Tex` / `:NewTex` to bootstrap documents.
- For AI-assisted coding: configure Ollama or llm as per `lua/gen_commit/init.lua` and `lua/plugin_llm.lua`; then use `:GenCommit*` commands, `opencode` prompts, etc.


This repository provides a Neovim configuration focused on improving editing workflows for code, writing, and project collaboration. Key features include:

- Core editing experience: basic keybinds and autoreload when files change outside Neovim (already in config).
- Language support: enhanced syntax highlighting and LSP via nvim-treesitter and Mason; quick actions via LSP mapping.
- AI-assisted coding and commit generation: GenCommit commands to generate git commit messages from diffs using Ollama or llm; commands available: `:GenCommit`, `:GenCommitNow`, `:GenCommitOllama`, `:GenCommitNowOllama`, `:GenCommitLLM`, `:GenCommitNowLLM`.
- Opencode integration: quick access to an AI assistant for code understanding; keymaps in `lua/plugin_opencode.lua`.
- Git tooling: `gitsigns` for inline git info, and an optional `ghcid` integration for Haskell live feedback (`plugin_ghcid.lua`).
- TeX/LaTeX: shortcuts and templates to accelerate TeX editing (`latex-shortcuts.lua`, `texcommands.lua`).
- Markdown support: syntax and editing improvements for Markdown (`after/syntax/markdown.vim`).


## Haskell & Ghcid

This configuration includes dedicated Haskell tooling. Ghcid and Haskell Language Server support are wired via plugin/plugins.vim. See details in that file for exact mappings and commands.

- Ghcid live error/warning feedback: GhcidQF loads errors into QuickFix; quick access via a convenient key mapping is provided.
- Haskell LSP via Coc: coc with haskell-language-server-wrapper (--lsp) for real-time diagnostics, go-to-definition, renaming, etc. Root patterns and formatter (ormolu) are configured in Coc settings.
- Haskell editing helpers: integration with haskell-tools and related plugins as configured in the repo.

## Quick Start

- Run `:PlugInstall` to install plugins.
- Open Neovim and start editing; see core keybinds in `lua/essential.lua`.
- For commit messages: stage changes, then use `:GenCommit` (or `:GenCommitNow`) to generate a message, then commit.
- For LaTeX: in TeX files use LaTeX shortcuts (e.g., `;al`, `;;en`) and commands `:Tex` / `:NewTex` to bootstrap documents.
- For AI-assisted coding: configure Ollama or llm as per `lua/gen_commit/init.lua` and `lua/plugin_llm.lua`; then use `:GenCommit*` commands, `opencode` prompts, etc.

