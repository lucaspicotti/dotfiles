return {
  {
    "Mofiqul/dracula.nvim",
    name = "dracula",
    priority = 1000,
    opts = {
      italic_comment = true,
    },
    config = function(_, opts)
      vim.o.background = "dark"
      require("dracula").setup(opts)
      vim.cmd.colorscheme("dracula")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "dracula" },
  },
}
