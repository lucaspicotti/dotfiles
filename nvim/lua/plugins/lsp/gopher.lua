-- Go Refactoring Tools (o equivalente ao phpactor para Go)
return {
  "olexsmir/gopher.nvim",
  ft = "go",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  -- Instala gomodifytags, impl, gotests e iferr com `go install`
  build = function()
    vim.cmd.GoInstallDeps()
  end,
  opts = {},
  keys = {
    { "<Leader>Gj", "<cmd>GoTagAdd json<CR>", ft = "go", desc = "Adicionar tags json na struct" },
    { "<Leader>GJ", "<cmd>GoTagRm json<CR>", ft = "go", desc = "Remover tags json da struct" },
    { "<Leader>Ge", "<cmd>GoIfErr<CR>", ft = "go", desc = "Gerar if err != nil" },
    { "<Leader>Gt", "<cmd>GoTestAdd<CR>", ft = "go", desc = "Gerar teste da função" },
  },
}
