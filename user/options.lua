-- Edit
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.wrap = false
vim.opt.relativenumber = true
vim.opt.wildmode = 'longest:full,full'
vim.opt.spell = true
vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '·' }
vim.opt.clipboard = 'unnamedplus'
vim.opt.undofile = true
vim.opt.backup = true
vim.opt.backupdir:remove('.')
-- Interface
vim.opt.confirm = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.title = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.fillchars:append({ eob = ' ' })
