return {
  "rmagatti/goto-preview",
  keys = {
    { "gpd", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", desc = "Preview Definition" },
    { "gpt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", desc = "Preview Type Definition" },
    { "gpi", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", desc = "Preview Implementation" },
    { "gD", "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>", desc = "Preview Declaration" },
    { "gP", "<cmd>lua require('goto-preview').close_all_win()<CR>", desc = "Close All Previews" },
    { "gpr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>", desc = "Preview References" },
  },
  opts = {
    -- focus_on_open = false,
    -- dismiss_on_move = true,
    border = { "↖", "─", "╮", "│", "╯", "─", "╰", "│" },
    post_open_hook = function(buf, win)
      -- remap inside the preview window to close it
      vim.api.nvim_buf_set_keymap(buf, "n", "gd", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "gD", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "gr", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "gi", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "gt", ":close<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
    end,
  },
}
