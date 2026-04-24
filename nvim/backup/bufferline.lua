local inactive_bg = {
  bg = { attribute = "bg", highlight = "BufferlineInactive" },
}

return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    options = {
      diagnostics = "nvim_lsp",

      indicator = {
        icon = " ",
      },

      show_close_icon = false,
      max_name_length = 25,
      separator_style = "slant",

      offsets = {
        {
          filetype = "neo-tree",
          text = function()
            return " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
          end,
          highlight = "StatusLine",
          text_align = "left",
        },
      },

      hover = {
        enabled = true,
        delay = 0,
        reveal = { "close" },
      },

      modified_icon = "",

      custom_areas = {
        left = function()
          return {
            { text = " " },
          }
        end,
        right = function()
          return {
            { text = "    ", fg = "#8fff6d" },
          }
        end,
      },

      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
    },

    highlights = {
      fill = {
        bg = { attribute = "bg", highlight = "StatusLine" },
      },

      background = inactive_bg,
      close_button = inactive_bg,
      diagnostic = inactive_bg,
      diagnostic_visible = inactive_bg,
      modified = inactive_bg,
      modified_visible = inactive_bg,
      hint = inactive_bg,
      hint_visible = inactive_bg,
      info = inactive_bg,
      info_visible = inactive_bg,
      warning = inactive_bg,
      warning_visible = inactive_bg,
      error = inactive_bg,
      error_visible = inactive_bg,
      hint_diagnostic = inactive_bg,
      hint_diagnostic_visible = inactive_bg,
      info_diagnostic = inactive_bg,
      info_diagnostic_visible = inactive_bg,
      warning_diagnostic = inactive_bg,
      warning_diagnostic_visible = inactive_bg,
      error_diagnostic = inactive_bg,
      error_diagnostic_visible = inactive_bg,
      duplicate = inactive_bg,
      duplicate_visible = inactive_bg,

      separator = {
        fg = { attribute = "bg", highlight = "StatusLine" },
        bg = { attribute = "bg", highlight = "BufferlineInactive" },
      },
      separator_selected = {
        fg = { attribute = "bg", highlight = "StatusLine" },
      },
      separator_visible = {
        fg = { attribute = "bg", highlight = "StatusLine" },
      },

      trunc_marker = {
        bg = { attribute = "bg", highlight = "StatusLine" },
      },

      tab = inactive_bg,
      tab_separator = {
        fg = { attribute = "bg", highlight = "StatusLine" },
        bg = { attribute = "bg", highlight = "BufferlineInactive" },
      },
      tab_separator_selected = {
        fg = { attribute = "bg", highlight = "StatusLine" },
      },
    },
  },
}
