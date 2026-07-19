local lazy_status = require("lazy.status")

local function indent()
  if vim.o.expandtab then
    return "SW:" .. vim.o.shiftwidth
  end
  return "TS:" .. vim.o.tabstop
end

local function lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local names = {}

  for _, client in ipairs(clients) do
    if client.name ~= "GitHub Copilot" then
      table.insert(names, client.name)
    end
  end

  if #names == 0 then
    return "No LSP"
  end

  return " " .. table.concat(names, ", ")
end

local function dap()
  local dap = package.loaded["dap"]
  if dap then
    return dap.status()
  end
  return ""
end

local function osv()
  local osv = package.loaded["osv"]
  if osv and osv.is_running() then
    return "Running as debuggee"
  end
  return ""
end

local function dap_or_lsp()
  local osv_status = osv()
  if osv_status ~= "" then
    return osv_status
  end

  local dap_status = dap()
  if dap_status ~= "" then
    return dap_status
  end

  return lsp()
end

return {
  "nvim-lualine/lualine.nvim",
  init = function()
    vim.o.laststatus = 0
  end,
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "ofseed/copilot-status.nvim",
  },
  opts = {
    options = {
      icons_enabled = true,
      theme = "everforest",
      disabled_filetypes = {
        statusline = { "alpha" },
      },
      always_divide_middle = true,
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },

    sections = {
      lualine_a = {
        {
          "mode",
          icon = "",
        },
      },

      lualine_b = {
        {
          "branch",
          icon = "",
        },
        {
          "diff",
          symbols = {
            added = " ",
            modified = " ",
            removed = " ",
          },
          source = function()
            return vim.b.gitsigns_status_dict
          end,
        },
      },

      lualine_c = {
        dap_or_lsp,
      },

      lualine_x = {
        {
          lazy_status.updates,
          cond = lazy_status.has_updates,
          color = { fg = "#ff9e64" },
        },
        {
          function()
            return ""
          end,
          name = "overseer-placeholder",
        },
        "copilot",
        indent,
        {
          "encoding",
          show_bomb = true,
        },
        "fileformat",
      },

      lualine_y = {
        "diagnostics",
        {
          "progress",
          icon = "",
        },
      },

      lualine_z = {
        {
          "location",
          icon = "",
        },
      },
    },

    extensions = {
      "man",
      "quickfix",
      "nvim-tree",
      "neo-tree",
      "toggleterm",
      "symbols-outline",
      "aerial",
      "fugitive",
      "nvim-dap-ui",
      "mundo",
      "lazy",
    },
  },
}
