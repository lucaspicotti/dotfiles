-- lua/themes/lualine_alucard.lua

local colors = require("themes.palette")

return {
  normal = {
    a = {
      fg = colors.bg,
      bg = colors.purple,
      gui = "bold",
    },

    b = {
      fg = colors.fg,
      bg = colors.visual,
    },

    c = {
      fg = colors.fg,
      bg = colors.bg,
    },
  },

  insert = {
    a = {
      fg = colors.bg,
      bg = colors.green,
      gui = "bold",
    },
  },

  visual = {
    a = {
      fg = colors.bg,
      bg = colors.pink,
      gui = "bold",
    },
  },

  replace = {
    a = {
      fg = colors.bg,
      bg = colors.red,
      gui = "bold",
    },
  },

  command = {
    a = {
      fg = colors.bg,
      bg = colors.yellow,
      gui = "bold",
    },
  },

  inactive = {
    a = {
      fg = colors.comment,
      bg = colors.menu,
    },

    b = {
      fg = colors.comment,
      bg = colors.menu,
    },

    c = {
      fg = colors.comment,
      bg = colors.menu,
    },
  },
}
