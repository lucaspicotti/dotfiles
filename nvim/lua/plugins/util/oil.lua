return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
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
    -- TODO: Talvez alterar o modo do keys
    keys = {
      { "-", ":Oil<CR>", desc = "Open parent directory" },
    },
  },
}
