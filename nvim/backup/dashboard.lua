return {
  "nvimdev/dashboard-nvim",
  event = "BufEnter",
  priority = 1000,
  config = function()
    require("dashboard").setup({
      theme = "hyper",
      disable_move = false,
      shortcut_type = "number",
      change_to_vcs_root = false,
      config = {
        header = {
          [[███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
          [[████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
          [[██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
          [[██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
          [[██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
          [[╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        packages = { enable = true },
        project = { enable = true },
        week_header = { enable = false },
        shortcut = {
          {
            icon = "󰊳 ",
            desc = "Update Lazy",
            group = "@property",
            action = "Lazy update",
            key = "l",
          },
          {
            icon = "󰊳 ",
            desc = "Update Mason",
            group = "Number",
            action = "MasonToolsUpdate",
            key = "m",
          },
          {
            icon = " ",
            desc = "Files",
            group = "Label",
            action = "Telescope find_files",
            key = "f",
          },
          {
            icon = "󰝰 ",
            desc = "Neo-tree",
            group = "@type",
            action = "Neotree toggle",
            key = "n",
          },
        },
      },
      hide = {
        statusline = false,
        tabline = true,
        winbar = true,
      },
      preview = {},
    })
  end,
}
