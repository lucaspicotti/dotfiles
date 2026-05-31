return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "onsails/lspkind-nvim",
  },
  lazy = false,
  enabled = true,
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    require("luasnip/loaders/from_snipmate").lazy_load()

    local source_map = {
      buffer = "Buffer",
      nvim_lsp = "LSP",
      nvim_lsp_signature_help = "Signature",
      luasnip = "LuaSnip",
      nvim_lua = "Lua",
      path = "Path",
      copilot = "Copilot",
    }

    local function ltrim(s)
      return s:match("^%s*(.*)")
    end

    cmp.setup({
      preselect = cmp.PreselectMode.None,

      completion = {
        autocomplete = false,
      },

      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      view = {
        entries = { name = "custom", selection_order = "near_cursor" },
      },

      window = {
        completion = {
          col_offset = -2,
        },
      },

      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = lspkind.cmp_format({
          mode = "symbol",
          before = function(entry, vim_item)
            vim_item.menu = "  " .. vim_item.kind .. " (" .. (source_map[entry.source.name] or entry.source.name) .. ")"
            vim_item.menu_hl_group = "SpecialComment"
            vim_item.abbr = ltrim(vim_item.abbr)

            if vim_item.kind == "Color" and entry.completion_item.documentation then
              local _, _, r, g, b = string.find(entry.completion_item.documentation, "^rgb%((%d+), (%d+), (%d+)")
              if r then
                local color = string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
                local group = "Tw_" .. color

                if vim.fn.hlID(group) < 1 then
                  vim.api.nvim_set_hl(0, group, { fg = "#" .. color })
                end

                vim_item.kind_hl_group = group
              end
            end

            return vim_item
          end,
        }),
      },

      mapping = {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = true })
          else
            local ok, copilot_suggestion = pcall(require, "copilot.suggestion")
            if ok and copilot_suggestion.is_visible() then
              copilot_suggestion.accept()
            else
              fallback()
            end
          end
        end, { "i", "s" }),

        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-e>"] = cmp.mapping.abort(),
      },

      sources = {
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      },

      experimental = {
        ghost_text = true,
      },
    })
  end,
}
