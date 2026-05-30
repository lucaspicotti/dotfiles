return {
  {
    "jaljoue/dracula-alucard.nvim",
    name = "dracula-alucard",
    lazy = false,
    priority = 1000,
  },

  -- Configure LazyVim to load dracula-alucard
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula-alucard",
    },
  },
}
