return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
  opts = {
    columns = { "icon" },
    delete_to_trash = true,
    view_options = {
      show_hidden = true,
      sort = {
        { "type", "asc" },
        { "name", "asc" },
      },
    },
  },
}

