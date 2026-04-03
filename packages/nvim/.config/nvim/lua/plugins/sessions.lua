return {
  "rmagatti/auto-session",
  lazy = false,
  keys = {
    -- Will use Telescope if installed or a vim.ui.select picker otherwise
    { "<leader>wr", "<cmd>SessionSearch<CR>",         desc = "Session search" },
    { "<leader>ws", "<cmd>SessionSave<CR>",           desc = "Save session" },
    { "<leader>wa", "<cmd>SessionToggleAutoSave<CR>", desc = "Toggle autosave" },
    { "<leader>wd", "<cmd>SessionDelete<CR>",         desc = "Session Delete" },
  },
  opts = {
    log_level = "error",
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    bypass_save_filetypes = { "alpha", "dashboard" }, -- or whatever dashboard you use
    session_lens = {
      buftypes_to_ignore = {},
      load_on_setup = true,
      theme_conf = { border = true },
      previewer = false,
      mappings = {
        -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
        delete_session = { "i", "<C-D>" },
        alternate_session = { "i", "<C-S>" },
        copy_session = { "i", "<C-Y>" },
      },
    },

    cwd_change_handling = true,
    pre_cwd_changed_cmds = {
      -- NOTE: Hook to swap auto-sessions new directory based on open buffers to the root of the project.
      -- This will remove the annoying confirm dialog floating window from neotree to switch directory.
      function()
        -- Get initial working directory from the session
        local initial_dir = vim.fn.getcwd()

        -- Find the git repository root by searching upwards
        -- This works even if current directory is a subdirectory of a git repo
        local git_cmd =
            io.popen("git -C " .. vim.fn.shellescape(initial_dir) .. " rev-parse --show-toplevel 2>/dev/null")
        local git_root = nil

        if git_cmd then
          git_root = git_cmd:read("*l") -- Read the first line
          git_cmd:close()
        end

        -- If git root found, use it, otherwise stay in current directory
        local target_dir = git_root or initial_dir

        -- Change Neovim's working directory to the git root
        if target_dir and target_dir ~= "" then
          vim.cmd("cd " .. vim.fn.fnameescape(target_dir))

          -- Log the directory change (optional)
          print("Changed directory to git root: " .. target_dir)
        end

        -- TODO: update Ghostty so new splits inherit the updated current directory
      end,
    },
    post_cwd_changed_cmds = {
      function()
        -- Refresh NeoTree to reflect the new directory
        vim.cmd("Neotree dir=" .. vim.fn.getcwd())
        -- Refresh Lualine
        require("lualine").refresh()
      end,
    },
  },
}
