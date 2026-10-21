return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
    "numToStr/Comment.nvim",
  },
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    -- Pasta própria: o kulala.nvim instala o parser dele em site/parser, e o
    -- :TSUpdate tentaria atualizar o kulala_http se dividissem o mesmo diretório
    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/treesitter",
    })

    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })

    ts.install({
      "lua",
      "vim",
      "vimdoc",
      "markdown",
      "markdown_inline",
      "bash",
      "php",
      "php_only",
      "phpdoc",
      "go",
      "gomod",
      "gosum",
      "gowork",
      "json",
      "yaml",
      "toml",
      "html",
      "css",
      "dockerfile",
      "gitcommit",
      "gitignore",
      "git_rebase",
      "git_config",
      "diff",
      "regex",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "lua",
        "vim",
        "markdown",
        "bash",
        "php",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "json",
        "jsonc",
        "yaml",
        "toml",
        "html",
        "css",
        "dockerfile",
        "gitcommit",
        "diff",
      },
      callback = function(args)
        vim.treesitter.start(args.buf)

        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

        -- indent via treesitter; se notar comportamento ruim no PHP legado,
        -- remova esta linha ou limite por filetype
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    vim.treesitter.language.register("bash", { "zsh" })
    -- O upstream não tem parser jsonc; o de json já entende comentários
    vim.treesitter.language.register("json", { "jsonc" })
  end,
}
