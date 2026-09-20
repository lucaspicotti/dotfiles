return {
  {
    "EdenEast/nightfox.nvim",
    name = "nightfox",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("duskfox")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "duskfox" },
  },
}
