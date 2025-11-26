--  Language Server Protocol

return { 
  "neovim/nvim-lspconfig",
  event =  "Filetype",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",

    'williamboman/mason-lspconfig.nvim',
    "b0o/SchemaStore.nvim",
  },
  config = function()
    local lspconfig = require "lspconfig"
    
    -- Setup Mason to automatically install LSP servers
    require('mason').setup({
      ui = {
        height = 0.8,
      },
    })
    require('mason-lspconfig').setup({ automatic_installation = true })

    local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
    -- PHP
    lspconfig.phpactor.setup {
      on_attach = on_attach,
      filetypes = { "php" },
      init_options = {
        ["language_server_phpstan.enabled"] = false,
        ["language_server_psalm.enabled"] = false,
        ["language_server_php_cs_fixer.enabled"] = true,
      }
    }

    -- lspconfig.intelephense.setup {
    --   commands = {
    --     IntelephenseIndex = {
    --       function()
    --         vim.lsp.buf.execute_command({ command = 'intelephense.index.workspace' })
    --       end,
    --     },
    --   },
    --   capabilities = capabilities
    -- }
    
    -- Vue, Javascript, Typescript
    -- lspconfig.ts_ls.setup {
    --   on_attach = on_attach,
    --   capabilities = capabilities,
    --   init_options = {
    --     plugins = {
    --       {
    --         name = "@vue/typescript-plugin",
    --         location = "/usr/local/lib/node_modules/@vue/language-server",
    --         languages = { "vue" },
    --       },
    --     },
    --   },
    --   filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue"}
    -- }

      lspconfig.volar.setup {
      filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue"},
      init_options =  {
        vue = {
          hybridMode = false,
        },
      },
    } 
   

    -- Lua
    lspconfig.lua_ls.setup {
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
      end,
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
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
    }
    -- Keymaps
    vim.keymap.set('n', '<Leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>')
    vim.keymap.set('n', 'gd', ':Telescope lsp_definitions<CR>')
    vim.keymap.set('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')
    vim.keymap.set('n', 'gi', ':Telescope lsp_implementations<CR>')
    vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>')
    vim.keymap.set('n', '<Leader>lr', ':LspRestart<CR>', { silent = true })
    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
    vim.keymap.set('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')

      vim.diagnostic.config({
      virtual_text = false,
      float = {
        source = true,
      }
    })
   end,
}
