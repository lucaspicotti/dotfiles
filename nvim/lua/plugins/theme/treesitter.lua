return {
  "neovim-treesitter/nvim-treesitter",
  dependencies = {
    "neovim-treesitter/treesitter-parser-registry",
    "JoosepAlviste/nvim-ts-context-commentstring",
    "numToStr/Comment.nvim",
  },
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    -- opcional; o README diz que setup só é necessário
    -- se você quiser mudar o install_dir
    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
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
      "json",
      "jsonc",
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
  end,
}
