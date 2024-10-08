local M = {
  "nvim-treesitter/nvim-treesitter",
  -- commit = "226c1475a46a2ef6d840af9caa0117a439465500",
  event = "BufReadPost",
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      event = "VeryLazy",
      -- commit = "729d83ecb990dc2b30272833c213cc6d49ed5214",
    },
    {
      "nvim-tree/nvim-web-devicons",
      event = "VeryLazy",
      -- commit = "0568104bf8d0c3ab16395433fcc5c1638efc25d4",
    },
    {
      "windwp/nvim-ts-autotag",
      -- event = "LazyFile",
      opts = {
        enable_after_quote = false,
      },
    },
  },
}
function M.config()
  -- local treesitter = require "nvim-treesitter"
  local configs = require "nvim-treesitter.configs"

  configs.setup {
    ensure_installed = {
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
      "bash",
      "python",
      "go",
      "gomod",
      "gowork",
      "gosum",
      "javascript",
      "typescript",
      "tsx",
      "terraform",
      "hcl",
      "json",
      "yaml",
    },                       -- put the language you want in this array
    -- ensure_installed = "all", -- one of "all" or a list of languages
    ignore_install = { "" }, -- List of parsers to ignore installing
    sync_install = false,    -- install languages synchronously (only applied to `ensure_installed`)

    highlight = {
      enable = true,       -- false will disable the whole extension
      disable = { "css" }, -- list of language that will be disabled
    },
    autopairs = {
      enable = true,
    },
    indent = { enable = true, disable = { "python", "css" } },
  }
end

return M
