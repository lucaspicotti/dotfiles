return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "frappe",
    integrations = {
      telescope = {
        enabled = true,
      },
      cpm = {
        enabled = true,
      },
      indent_blankline = {
        enabled = true,
        scope_color = "lavender", -- ou "mauve", "blue", etc
      },
      neo_tree = {
        enabled = true,
      },
    },
  },
}
