-- lua/themes/alucard.lua

local colors = require("themes.palette")

local M = {}

function M.setup()
  vim.cmd("highlight clear")

  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "alucard"

  local hl = vim.api.nvim_set_hl

  -- =========================
  -- Editor
  -- =========================
  hl(0, "Normal", {
    fg = colors.fg,
    bg = colors.bg,
  })

  hl(0, "NormalFloat", {
    fg = colors.fg,
    bg = colors.menu,
  })

  hl(0, "FloatBorder", {
    fg = colors.purple,
    bg = colors.menu,
  })

  hl(0, "CursorLine", {
    bg = colors.selection,
  })

  hl(0, "CursorColumn", {
    bg = colors.visual,
  })

  hl(0, "ColorColumn", {
    bg = colors.menu,
  })

  hl(0, "Visual", {
    bg = colors.selection,
  })

  hl(0, "VertSplit", {
    fg = colors.nontext,
  })

  hl(0, "WinSeparator", {
    fg = colors.nontext,
  })

  -- =========================
  -- Line Numbers
  -- =========================
  hl(0, "LineNr", {
    fg = colors.gutter_fg,
  })

  hl(0, "CursorLineNr", {
    fg = colors.purple,
    bold = true,
  })

  hl(0, "SignColumn", {
    bg = colors.bg,
  })

  -- =========================
  -- Syntax
  -- =========================
  hl(0, "Comment", {
    fg = colors.comment,
    italic = true,
  })

  hl(0, "Constant", {
    fg = colors.orange,
  })

  hl(0, "String", {
    fg = colors.green,
  })

  hl(0, "Character", {
    fg = colors.green,
  })

  hl(0, "Number", {
    fg = colors.orange,
  })

  hl(0, "Boolean", {
    fg = colors.orange,
    bold = true,
  })

  hl(0, "Float", {
    fg = colors.orange,
  })

  hl(0, "Identifier", {
    fg = colors.fg,
  })

  hl(0, "Function", {
    fg = colors.purple,
    bold = true,
  })

  hl(0, "Statement", {
    fg = colors.pink,
  })

  hl(0, "Conditional", {
    fg = colors.pink,
    bold = true,
  })

  hl(0, "Repeat", {
    fg = colors.pink,
  })

  hl(0, "Keyword", {
    fg = colors.pink,
    bold = true,
  })

  hl(0, "Operator", {
    fg = colors.cyan,
  })

  hl(0, "Exception", {
    fg = colors.red,
  })

  hl(0, "PreProc", {
    fg = colors.yellow,
  })

  hl(0, "Include", {
    fg = colors.cyan,
  })

  hl(0, "Define", {
    fg = colors.pink,
  })

  hl(0, "Macro", {
    fg = colors.yellow,
  })

  hl(0, "Type", {
    fg = colors.yellow,
  })

  hl(0, "StorageClass", {
    fg = colors.yellow,
  })

  hl(0, "Structure", {
    fg = colors.yellow,
  })

  hl(0, "Typedef", {
    fg = colors.yellow,
  })

  hl(0, "Special", {
    fg = colors.cyan,
  })

  hl(0, "SpecialChar", {
    fg = colors.cyan,
  })

  hl(0, "Tag", {
    fg = colors.red,
  })

  hl(0, "Delimiter", {
    fg = colors.fg,
  })

  hl(0, "SpecialComment", {
    fg = colors.comment,
    italic = true,
  })

  hl(0, "Debug", {
    fg = colors.red,
  })

  -- =========================
  -- Diagnostics
  -- =========================
  hl(0, "DiagnosticError", {
    fg = colors.red,
  })

  hl(0, "DiagnosticWarn", {
    fg = colors.yellow,
  })

  hl(0, "DiagnosticInfo", {
    fg = colors.cyan,
  })

  hl(0, "DiagnosticHint", {
    fg = colors.purple,
  })

  -- =========================
  -- Search
  -- =========================
  hl(0, "Search", {
    fg = colors.black,
    bg = colors.bright_yellow,
  })

  hl(0, "IncSearch", {
    fg = colors.black,
    bg = colors.yellow,
    bold = true,
  })

  -- =========================
  -- Popup Menu
  -- =========================
  hl(0, "Pmenu", {
    fg = colors.fg,
    bg = colors.menu,
  })

  hl(0, "PmenuSel", {
    fg = colors.black,
    bg = colors.selection,
    bold = true,
  })

  hl(0, "PmenuThumb", {
    bg = colors.purple,
  })

  hl(0, "PmenuSbar", {
    bg = colors.visual,
  })

  -- =========================
  -- Statusline
  -- =========================
  hl(0, "StatusLine", {
    fg = colors.fg,
    bg = colors.visual,
  })

  hl(0, "StatusLineNC", {
    fg = colors.comment,
    bg = colors.menu,
  })

  -- =========================
  -- Telescope
  -- =========================
  hl(0, "TelescopeBorder", {
    fg = colors.purple,
    bg = colors.menu,
  })

  hl(0, "TelescopeSelection", {
    bg = colors.selection,
  })

  hl(0, "TelescopeMatching", {
    fg = colors.pink,
    bold = true,
  })
end

return M
