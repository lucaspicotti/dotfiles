return {
  "neovim/nvim-lspconfig",
  event = "FileType",
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/nvim-cmp"
  },
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local on_attach = function(_, bufnr)
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
          buffer = bufnr,
          silent = true,
          desc = desc,
        })
      end

      map("n", "<leader>d", vim.diagnostic.open_float, "Line Diagnostics")
      map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Go to Definition")
      map("n", "ga", vim.lsp.buf.code_action, "Code Action")
      map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Go to Implementation")
      map("n", "gr", "<cmd>Telescope lsp_references<CR>", "References")
      map("n", "K", vim.lsp.buf.hover, "Hover")
      map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
      map("n", "<leader>lr", "<cmd>LspRestart<CR>", "Restart LSP")
    end

    -- Mason
    require("mason").setup({
      ui = {
        height = 0.8,
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = {
        "phpactor",
        "lua_ls",
      },
      automatic_enable = false,
    })

    -- PHP (phpactor)
    vim.lsp.config("phpactor", {
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "php" },
      init_options = {
        ["language_server_phpstan.enabled"] = false,
        ["language_server_psalm.enabled"] = false,
        ["language_server_php_cs_fixer.enabled"] = true,
      },
    })

    -- Lua
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        on_attach(client, bufnr)
      end,
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim" },
          },
          hint = {
            enable = true,
            setType = true,
          },
          codeLens = {
            enable = true,
          },
          completion = {
            postfix = ".",
            showWord = "Disable",
            workspaceWord = false,
          },
        },
      },
    })

    -- Enable LSPs
    vim.lsp.enable({
      "phpactor",
      "lua_ls",
    })

    -- Diagnostics
    vim.diagnostic.config({
      virtual_text = false,
      float = {
        source = true,
      },
    })
  end,
}
