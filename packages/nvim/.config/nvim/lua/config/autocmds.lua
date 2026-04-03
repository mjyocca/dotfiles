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
      require("snacks").toggle.diagnostics():map("<leader>td")
    end,
  })
end

M.plugins = function()
  -- Ember Cmd util for finding related files
  vim.api.nvim_create_user_command("FindEmberRelated", function()
    local telescope = require("telescope.builtin")
    -- local search_patterns = { "component", "controller", "route", "template", "model", "service", "helper" }
    local current_file_path = vim.fn.expand("%:p")
    local current_file = vim.fn.expand("%:t:r")
    local relative_path = vim.fn.expand("%:p:~:.")
    local base_name = current_file:gsub("%.module$", ""):gsub("%-test$", "")

    local search_patterns = {}
    local related_file

    -- Determine related file path to insert into search_patterns table
    -- Controllers
    if relative_path:match("^.*/app/controllers/") then
      related_file = relative_path:gsub("^.*/app/controllers/", "/app/routes/")
      table.insert(search_patterns, "**/*" .. related_file .. "")

      local template_file = relative_path:gsub("^.*/app/controllers/", "/app/templates/")
      template_file = template_file:gsub("(.+)(%.js)$", "%1.hbs")
      table.insert(search_patterns, "**/*" .. template_file .. "*")
      -- test file glob
      local test_file = relative_path:gsub("^.*/app/controllers/", "/tests/acceptance/")
      test_file = test_file:gsub("(.+)(%.js)$", "%1-test%2")
      table.insert(search_patterns, "**/*" .. test_file .. "")
      -- Routes
    elseif relative_path:match("^.*/app/routes/") then
      related_file = relative_path:gsub("^.*/app/routes/", "/app/controllers/")
      table.insert(search_patterns, "**/*" .. related_file .. "")

      local template_file = relative_path:gsub("^.*/app/routes/", "/app/templates/")
      template_file = template_file:gsub("(.+)(%.js)$", "%1.hbs")
      table.insert(search_patterns, "**/*" .. template_file .. "*")

      -- test file glob
      local test_file = relative_path:gsub("^.*/app/routes/", "/tests/acceptance/")
      test_file = test_file:gsub("(.+)(%.js)$", "%1-test%2")
      table.insert(search_patterns, "**/*" .. test_file .. "")
      -- Components
    elseif relative_path:match("^.*/app/components/") then
      table.insert(search_patterns, "**/*" .. current_file .. "*")
      table.insert(search_patterns, "**/*" .. base_name .. "*")

      local test_file = relative_path:gsub("^.*/app/components/", "tests/**/*/")
      test_file = test_file:gsub("(.+)(%.js)$", "%1-test%2")
      table.insert(search_patterns, test_file)
    end

    -- Test Files tests/**/**/file-test.js
    local result = relative_path:gsub("^(.-)/app/(.+)/([^/]+)%.js$", "%1/tests/**/**/%2/%3-test.js")
    table.insert(search_patterns, result)

    -- Test files tests/**/**/file.js
    local result = relative_path:gsub("^(.-)/app/(.+)/([^/]+)%.js$", "%1/tests/**/**/%2/%3.js")
    table.insert(search_patterns, result)

    -- Build the search command
    local find_command = { "rg", "--files" }
    for _, pattern in ipairs(search_patterns) do
      table.insert(find_command, "--glob")
      table.insert(find_command, pattern)
    end

    -- Use find_files with a previewer like the built-in behavior
    telescope.find_files({
      prompt_title = "Find Related Ember Files",
      search_dirs = { vim.fn.getcwd() },
      find_command = find_command,
      previewer = true, -- This enables the default Telescope previewer
    })
  end, {})

  -- Send OSC 7 escape sequence to update Ghostty's working directory awareness
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      local cwd = vim.fn.getcwd()
      local uri = "file://" .. vim.fn.hostname() .. cwd
      local esc_seq = "\x1b]7;" .. uri .. "\x07"
      vim.api.nvim_chan_send(vim.v.stderr, esc_seq)
    end,
  })
end

return M
