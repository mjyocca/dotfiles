local M = {}

local d = {}
local function augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

function M.general()
  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.highlight.on_yank()`
  vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = augroup("kickstart-highlight-yank"),
    callback = function()
      vim.highlight.on_yank()
    end,
  })
end

-- LSP-specific autocommands
function M.lsp(options)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
      -- Inject event into option callback
      if options.callback then
        options.callback(event)
      end

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd("LspDetach", {
          group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
          end,
        })
      end
    end,
  })
end

-- Snacks Plugin autocommands
function M.snacks(options)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      require("snacks").toggle.diagnostics():map("<leader>ud")
    end,
  })

  -- Diagnostic Window Util to scroll to correlated diagnostic line
  vim.api.nvim_create_user_command("ShowDiags", function()
    -- Current Window with diags
    local current_win = vim.api.nvim_get_current_win()
    -- Current Buffer
    local diagnostics = vim.diagnostic.get(0)

    if #diagnostics == 0 then
      vim.notify("No diagnostics found", vim.log.levels.INFO)
      return
    end

    local utils = require("config.utils")

    -- Prepare diagnostic entries
    local diag_res = utils.get_diagnostics(diagnostics)
    local lines = diag_res.lines
    local entries = diag_res.entries

    -- No file, temporary
    local diags_buf = vim.api.nvim_create_buf(false, true)
    -- Set buffer lines
    vim.api.nvim_buf_set_lines(diags_buf, 0, -1, false, lines)

    local width = vim.o.columns
    local height = vim.o.lines
    local row_offset = 5

    local win = Snacks.win({
      buf = diags_buf,
      relative = "editor",
      position = "float",
      height = 0.2,
      width = 0.4,
      row = 2, -- height - 0.2 - row_offset, -- Adjust if too close to bottom
      col = width - 40,
      fixbuf = true,
      minimal = false,
      border = "rounded",
      ---@diagnostic disable-next-line: missing-fields
      wo = {
        cursorline = true,
        cursorcolumn = false,
        signcolumn = "yes",
      },
      actions = {
        -- Callback function for selecting a line
        select = function()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local line_number = cursor[1]
          local line_text = vim.api.nvim_buf_get_lines(diags_buf, line_number - 1, line_number, false)[1]

          for _, diagnostic in ipairs(entries) do
            if diagnostic.text == line_text then
              utils.window_scroll_to(current_win, diagnostic.lnum)
              return
            end
          end

          print("Diagnostic not found for:", line_text)
        end,
      },
      keys = {
        -- register keymap for custom action
        ["<C-y>"] = "select",
        -- default close action
        ["<Esc>"] = "close",
      },
    })

    vim.api.nvim_win_set_config(win.win, {
      border = "rounded",
      title = "Diagnostics",
      footer = "Press <Esc> to close | <C-y> to select",
    })

    -- Create an autocommand to close on window leave
    vim.api.nvim_create_autocmd({ "WinLeave" }, {
      buffer = diags_buf,
      once = true, -- Trigger only once
      callback = function()
        win.close(win)
      end,
    })
  end, {})
end

return M
