return {
  "nvim-treesitter/nvim-treesitter",
  -- tag = "v0.9.2",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "JoosepAlviste/nvim-ts-context-commentstring",
    "numToStr/Comment.nvim",
    "RRethy/nvim-treesitter-endwise",
  },
  config = function()
    ---@class TSConfigs
    ---@field setup fun(config: table)
    local configs = require("nvim-treesitter.configs")
    require("Comment").setup()
    configs.setup({
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "vue",
        "typescript",
        "javascript",
        "html",
        "css",
        "http",
        "json",
        "jsonc",
        "bash",
        "php",
        "php_only",
        "phpdoc",
        -- "blade",
        "gitcommit",
        "gitignore",
        "git_rebase",
        "git_config",
        "regex",
        "diff",
        "dockerfile",
        -- "markdown",
        "markdown_inline",
        "toml",
        "yaml",
        "properties",
      },
      auto_install = true,
      sync_install = false,
      ignore_install = {},
      highlight = { enable = true },
      indent = { enable = true },
      modules = {},
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<leader>ss",
          node_incremental = "<leader>nn",
          node_decremental = "<leader>np",
          scope_incremental = "<leader>sn",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["ap"] = "@parameter.outer",
            ["ip"] = "@parameter.inner",
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["as"] = { query = "@scope", query_group = "locals" },
          },
        },
          lsp_interop = {
          enable = true,
          border = "none",
          floating_preview_opts = {},
          peek_definition_code = {
            ["<leader>df"] = "@function.outer",
            ["<leader>dF"] = "@class.outer",
          },
        },
      },
    }) -- Remove the trailing comma here
    vim.treesitter.language.register("bash", "zsh")
  end,
}
