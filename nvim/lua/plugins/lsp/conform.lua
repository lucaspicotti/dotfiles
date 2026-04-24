return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      css = { "prettierd" },
      scss = { "prettierd" },
      less = { "prettierd" },
      html = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      yaml = { "prettierd" },
      markdown = { "prettierd" },
      ["markdown.mdx"] = { "prettierd" },

      -- PHP (formatter)
      php = { "phpcbf" },
    },

    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
  },
}
