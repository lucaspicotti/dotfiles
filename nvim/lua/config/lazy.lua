local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins.util" },
    { import = "plugins.git" },
    { import = "plugins.lsp" },
    { import = "plugins.telescope" },
    { import = "plugins.theme" },
  },
  change_detection = { notify = false },
  checker = { enabled = true, notify = false },
  install = {
    colorscheme = { "tokyonight" },
  },
})
