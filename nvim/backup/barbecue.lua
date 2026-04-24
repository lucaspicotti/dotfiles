return {
  "utilyre/barbecue.nvim",
  name = "barbecue",
  version = "*",
  event = "VeryLazy",

  dependencies = {
    {
      "SmiteshP/nvim-navic",
      opts = {
        lsp = {
          auto_attach = true,
          -- removido preference
        },
      },
    },
    "nvim-tree/nvim-web-devicons",
  },

  opts = {
    theme = "catppuccin",
    show_modified = true,
    show_dirname = true,
    show_basename = true,
    show_navic = true,
  },
}
