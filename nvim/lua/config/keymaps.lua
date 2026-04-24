-- Limpar highlight de busca --
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Fechar todos os buffers --
vim.keymap.set("n", "<leader>Q", ":bufdo bdelete<CR>")

-- Diagnóstico LSP --
vim.keymap.set("n", "[d", vim.diagnostic.get_prev)
vim.keymap.set("n", "]d", vim.diagnostic.get_next)

-- gf cria arquivo se não existir --
vim.keymap.set("", "gf", ":edit <cfile><CR>")

-- Re-selecionar após identação --
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- YANK sem mover cursor --
vim.keymap.set("v", "y", "myy`y")
vim.keymap.set("v", "Y", "myY`y")

-- Movimento em linhas quebradas (wrap) --
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Paste sem sobrescrever clipboard --
vim.keymap.set("v", "p", '"_dP')

-- Inserir ; e , rapidamente --
vim.keymap.set("i", ";;", "<Esc>A;<Esc>")
vim.keymap.set("i", ",,", "<Esc>A,<Esc>")

-- Desabilitar q: --
vim.keymap.set("n", "q:", ":q<CR>")

-- Resize com setas --
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>")
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>")
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>")

-- Mover Linhas --
vim.keymap.set("i", "<A-j>", "<Esc>:move .+1<CR>==gi")
vim.keymap.set("i", "<A-k>", "<Esc>:move .-2<CR>==gi")

vim.keymap.set("n", "<A-j>", ":move .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":move .-2<CR>==")

vim.keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv")

-- Abrir terminal --
vim.keymap.set("n", "<leader>tt", function()
	require("snacks").terminal()
end, { desc = "Toggle Terminal" })
