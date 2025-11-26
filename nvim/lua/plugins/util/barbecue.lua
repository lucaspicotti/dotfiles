return {
  'utilyre/barbecue.nvim',
  event = 'BufRead',
  dependencies = {
    {
      "SmiteshP/nvim-navic",
      opts = {
        lsp = {
          auto_attach = true,
          preference = { "intelephense" },
        }
      },
    },
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    theme = 'catppuccin',
  },
}
