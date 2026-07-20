return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "olimorris/neotest-phpunit",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-phpunit")({
          phpunit_cmd = function()
            -- Usa o alias/abbr "phpunit" do sistema (que configuramos no Fish)
            return "phpunit"
          end,
        }),
      },
    })

    -- Atalhos de Teclado
    vim.keymap.set("n", "<leader>tr", function()
      require("neotest").run.run()
    end, { desc = "Rodar teste mais próximo (cursor)" })

    vim.keymap.set("n", "<leader>tf", function()
      require("neotest").run.run(vim.fn.expand("%"))
    end, { desc = "Rodar todos os testes do arquivo atual" })

    vim.keymap.set("n", "<leader>ts", function()
      require("neotest").summary.toggle()
    end, { desc = "Alternar painel de resultados de testes" })

    vim.keymap.set("n", "<leader>to", function()
      require("neotest").output.open({ enter = true })
    end, { desc = "Ver saída do teste sob o cursor" })
  end,
}
