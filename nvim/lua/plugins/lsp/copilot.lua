return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  keys = {
    {
      "<leader>ct",
      function()
        require("copilot.suggestion").toggle_auto_trigger()
        local is_auto = vim.b.copilot_suggestion_auto_trigger
        if is_auto == nil then
          is_auto = require("copilot.config").get("suggestion").auto_trigger
        end
        if is_auto then
          vim.notify("Copilot Auto-Trigger: LIGADO (Ativo)", vim.log.levels.INFO, { title = "Copilot" })
        else
          vim.notify("Copilot Auto-Trigger: DESLIGADO (Manual)", vim.log.levels.INFO, { title = "Copilot" })
        end
      end,
      desc = "Toggle Copilot Auto Trigger",
    },
  },
  config = function()
    require("copilot").setup({
      panel = {
        enabled = false,
      },

      suggestion = {
        enabled = true,
        auto_trigger = false,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = false,
        keymap = {
          accept = false,
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
          toggle_auto_trigger = false,
        },
      },

      filetypes = {
        php = true,
        lua = true,
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
        html = true,
        css = true,
        scss = true,
        less = true,
        json = true,
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        ["."] = false,
      },

      should_attach = function(_, bufname)
        local name = vim.fs.basename(bufname)
        if name:match("^%.env") then
          return false
        end
        return true
      end,
    })

    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.event:on("menu_opened", function()
        vim.b.copilot_suggestion_hidden = true
      end)

      cmp.event:on("menu_closed", function()
        vim.b.copilot_suggestion_hidden = false
      end)
    end
  end,
}
