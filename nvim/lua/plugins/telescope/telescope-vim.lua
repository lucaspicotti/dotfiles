return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope-live-grep-args.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
    },
  },

  keys = {
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Grep Project",
    },
    {
      "<leader>fw",
      function()
        require("telescope.builtin").grep_string()
      end,
      desc = "Word Under Cursor",
    },
    {
      "<leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Find Buffers",
    },
    {
      "<leader>fo",
      function()
        require("telescope.builtin").oldfiles()
      end,
      desc = "Recent Files",
    },
    {
      "<leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Help Tags",
    },
    {
      "<leader>fk",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>fs",
      function()
        require("telescope.builtin").lsp_document_symbols()
      end,
      desc = "Document Symbols",
    },
    {
      "<leader>fc",
      function()
        require("telescope.builtin").find_files({
          prompt_title = "Neovim Config",
          cwd = vim.fn.stdpath("config"),
          hidden = true,
        })
      end,
      desc = "Find Neovim Config",
    },
    {
      "<leader>fC",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args({
          prompt_title = "Grep Neovim Config",
          cwd = vim.fn.stdpath("config"),
        })
      end,
      desc = "Grep Neovim Config",
    },
    {
      "<leader>/",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
          layout_config = {
            width = 0.8,
          },
        }))
      end,
      desc = "Search Current Buffer",
    },
    {
      "<leader>gc",
      function()
        require("telescope.builtin").git_commits()
      end,
      desc = "Git Commits",
    },
    {
      "<leader>gb",
      function()
        require("telescope.builtin").git_bcommits()
      end,
      desc = "Buffer Commits",
    },
  },

  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")
    local lga_actions = require("telescope-live-grep-args.actions")

    telescope.setup({
      defaults = {
        prompt_prefix = "   ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",

        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          preview_width = 0.55,
          width = 0.90,
          height = 0.85,
        },

        winblend = 0,

        preview = {
          filesize_limit = 1,
          timeout = 200,
          msg_bg_fillchar = " ",
        },

        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-down>"] = actions.cycle_history_next,
            ["<C-up>"] = actions.cycle_history_prev,
          },
        },

        file_ignore_patterns = {
          "%.git/",
          "node_modules/",
          "dist/",
          "build/",
          "target/",
          "vendor/",
        },
      },

      pickers = {
        find_files = {
          hidden = true,
          prompt_title = "Find Files",
        },
        buffers = {
          prompt_title = "Find Buffers",
          previewer = false,
          sort_mru = true,
          ignore_current_buffer = true,
          layout_config = {
            width = 0.80,
            height = 0.50,
          },
        },
        oldfiles = {
          prompt_title = "Recent Files",
        },
        help_tags = {
          prompt_title = "Help Tags",
        },
        keymaps = {
          prompt_title = "Keymaps",
        },
        grep_string = {
          prompt_title = "Word Under Cursor",
        },
        git_commits = {
          prompt_title = "Git Commits",
        },
        git_bcommits = {
          prompt_title = "Buffer Commits",
        },
        lsp_references = {
          previewer = false,
        },
        lsp_definitions = {
          previewer = false,
        },
        lsp_document_symbols = {
          prompt_title = "Document Symbols",
          symbol_width = 50,
        },
      },

      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },

        live_grep_args = {
          auto_quoting = true,
          mappings = {
            i = {
              ["<C-k>"] = lga_actions.quote_prompt(),
              ["<C-space>"] = actions.to_fuzzy_refine,
            },
          },
        },

        ["ui-select"] = require("telescope.themes").get_dropdown(),
      },
    })

    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
    telescope.load_extension("ui-select")

    pcall(telescope.load_extension, "projects")
  end,
}
