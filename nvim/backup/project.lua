return {
  "ahmedkhalf/project.nvim",
  main = "project_nvim",
  opts = {
    manual_mode = true,
    detection_methods = { "lsp", "pattern" },
    patterns = {
      ".git",
      "composer.json",
      "package.json",
      "Makefile",
    },
    exclude_dirs = {
      "~/.cargo/*",
      "~/.local/*",
    },
    show_hidden = true,
    silent_chdir = true,
    scope_chdir = "global",
  },
  keys = {
    {
      "<leader>pr",
      "<cmd>ProjectRoot<CR>",
      desc = "Set project root",
    },
    {
      "<leader>pp",
      function()
        require("telescope").extensions.projects.projects({})
      end,
      desc = "Projects",
    },
  },
}
