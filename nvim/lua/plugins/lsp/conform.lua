return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>lf",
      function()
        require("conform").format { async = true, lsp_fallback = true }
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  -- Everything in opts will be passed to setup()
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      json = { "prettier", "prettierd", stop_after_first = true },
      javascript = { "prettier", "prettierd", stop_after_first = true },
      typescript = { "prettier", "prettierd", stop_after_first = true },
      javascriptreact = { "prettier", "prettierd", stop_after_first = true },
      typescriptreact = { "prettier", "prettierd", stop_after_first = true },
      go = { "goimports", "gofumpt" },
      terraform = { "terraform_fmt" },
      yaml = { "prettier", "prettierd", stop_after_first = true },
    },
    -- Set up format-on-save
    format_on_save = {
      -- These options will be passed to conform.format()
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
}
