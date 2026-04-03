local M = {}

function M.general()
  -- General utility function to simplify keymap creation
  local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
      options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  end

  map("n", "<Esc>", "<cmd>nohlsearch<CR>")

  -- Navigate vim panes better
  map("n", "<c-k>", ":wincmd k<CR>")
  map("n", "<c-j>", ":wincmd j<CR>")
  map("n", "<c-h>", ":wincmd h<CR>")
  map("n", "<c-l>", ":wincmd l<CR>")

  -- Move splits with <c-w>h/j/k/l
  map("n", "<c-w>h", "<c-w>H")
  map("n", "<c-w>j", "<c-w>J")
  map("n", "<c-w>k", "<c-w>K")
  map("n", "<c-w>l", "<c-w>L")

  -- -- Remap visual mode indenting to keep the selection active
  map("v", ">", ">gv", { noremap = true, silent = true })
  map("v", "<", "<gv", { noremap = true, silent = true })

  -- Navigate between open buffers
  map("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
  map("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
end

-- LSP KeyMaps
function M.lsp(event)
  local function map(keys, func, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
  end
  -- Jump to the definition of the word under your cursor.
  --  This is where a variable was first declared, or where a function is defined, etc.
  --  To jump back, press <C-t>.
  -- map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
  map("gd", require("snacks").picker.lsp_definitions, "[G]oto [D]efinition")

  -- Jump to declarations
  map("gD", require("snacks").picker.lsp_declarations, "[G]oto [D]eclaration")


  -- Find references for the word under your cursor.
  map("gR", require("snacks").picker.lsp_references, "[G]oto [R]eferences")
  -- leaving for now to compare
  map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

  -- Jump to the implementation of the word under your cursor.
  --  Useful when your language has ways of declaring types without an actual implementation.
  -- map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
  map("gI", require("snacks").picker.lsp_implementations, "[G]oto [I]mplementation")

  -- NOTE: map("K", vim.lsp.buf.hover, "Default Keymap for LSP hover reveal")

  -- Jump to the type of the word under your cursor.
  --  Useful when you're not sure what type a variable is and you want to see
  --  the definition of its *type*, not where it was *defined*.
  -- map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
  map("gy", require("snacks.picker").lsp_type_definitions, "[G]o T[y]pe Definition")

  -- Fuzzy find all the symbols in your current document.
  --  Symbols are things like variables, functions, types, etc.
  -- map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
  map("<leader>ds", require("snacks.picker").lsp_symbols, "LSP [D]ocument [S]ymbols")

  -- Fuzzy find all the symbols in your current workspace.
  --  Similar to document symbols, except searches over your entire project.
  -- map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
  map("<leader>ws", require("snacks.picker").lsp_workspace_symbols, "LSP [W]orkspace [S]ymbols")

  -- Rename the variable under your cursor.
  --  Most Language Servers support renaming across files, etc.
  map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

  -- WARN: This is not Goto Definition, this is Goto Declaration.
  --  For example, in C this would take you to the header.
  -- map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration vim.lsp.buf.declaration")

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  -- The following code creates a keymap to toggle inlay hints in your
  -- code, if the language server you are using supports them
  --
  -- This may be unwanted, since they displace some of your code
  if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    map("<leader>th", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
    end, "[T]oggle Inlay [H]ints")
  end

  map("<leader>tl", require("lsp_lines").toggle, "[T]oggle [L]spLines")
end

function M.plugins()
  local map = function(keys, func, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, keys, func, { desc = desc })
  end

  -- LazyGit (A Git Client)
  map(";c", function()
    require("snacks").lazygit.open({})
  end, "[;] LazyGit")

  -- GitBrowse Open Remote Url
  map(";o", function()
    require("snacks").gitbrowse({})
  end, "[;] GitBrowse")

  -- GitBrowse [V]isual Open Remote Url
  map(";o", function()
    require("snacks").gitbrowse({})
  end, "[;] GitBrowse", "v")

  map(";d", function()
    require("snacks").picker.diagnostics()
  end, "[;] Diagnostics")

  map(";e", function()
    -- UserCommand created in config/autocmds.lua
    vim.cmd("FindEmberRelated")
  end, "[;] Ember")
end

return M
