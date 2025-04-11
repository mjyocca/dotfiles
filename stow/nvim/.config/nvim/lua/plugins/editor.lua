return {
  -- NOTE: Fuzzy finder.
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      {
        "nvim-tree/nvim-web-devicons",
        enabled = vim.g.have_nerd_font,
      },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { ".git/.*" },
        },
        pickers = {
          find_files = {
            hidden = true,
            theme = "ivy",
          },
          live_grep = {
            additional_args = function(opts)
              return { "--hidden" }
            end,
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          fzf = {},
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")

      -- See `:help telescope.builtin`
      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
      vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

      -- Custom telescope picker to show current modified files
      vim.keymap.set("n", "<leader>sm", function()
        local previewers = require("telescope.previewers")
        local pickers = require("telescope.pickers")
        local sorters = require("telescope.sorters")
        local finders = require("telescope.finders")
        pickers
            .new({}, {
              results_title = "Modified in current branch",
              finder = finders.new_oneshot_job({
                "git",
                "diff",
                "--name-only",
              }, {}),
              sorter = sorters.get_fuzzy_file(),
              previewer = previewers.new_termopen_previewer({
                get_command = function(entry)
                  return {
                    "git",
                    "diff",
                    "--",
                    entry.value,
                  }
                end,
              }),
            })
            :find()
      end, { desc = "[S]earch [M]odified files" })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set("n", "<leader>/", function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = "[/] Fuzzily search in current buffer" })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set("n", "<leader>s/", function()
        builtin.live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end, { desc = "[S]earch [/] in Open Files" })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set("n", "<leader>sc", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end, { desc = "[S]earch Neovim [C]onfig files" })
    end,
  },

  -- NOTE: sourced from nvim-lua/kickstart.nvim
  -- which-key helps you remember key bindings by showing a popup
  -- with the active keybindings of the command you started typing.
  { -- Useful plugin to show you pending keybinds.
    "folke/which-key.nvim",
    event = "VimEnter",
    opts = {
      preset = "modern",
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and { Space = "<Space>" } or {
          Up = "<Up> ",
          Down = "<Down> ",
          Left = "<Left> ",
          Right = "<Right> ",
          C = "<C-…> ",
          M = "<M-…> ",
          D = "<D-…> ",
          S = "<S-…> ",
          CR = "<CR> ",
          Esc = "<Esc> ",
          ScrollWheelDown = "<ScrollWheelDown> ",
          ScrollWheelUp = "<ScrollWheelUp> ",
          NL = "<NL> ",
          BS = "<BS> ",
          Space = "<Space> ",
          Tab = "<Tab> ",
          F1 = "<F1>",
          F2 = "<F2>",
          F3 = "<F3>",
          F4 = "<F4>",
          F5 = "<F5>",
          F6 = "<F6>",
          F7 = "<F7>",
          F8 = "<F8>",
          F9 = "<F9>",
          F10 = "<F10>",
          F11 = "<F11>",
          F12 = "<F12>",
        },
      },

      win = {
        padding = { 2, 4 },
        border = "rounded",
      },

      -- Document existing key chains
      spec = {
        { "<leader>c",  group = "[C]ode",            mode = { "n", "x" } },
        { "<leader>d",  group = "[D]ocument/[D]ebug" },
        { "<leader>r",  group = "[R]ename" },
        { "<leader>s",  group = "[S]earch" },
        { "<leader>w",  group = "[W]orkspace" },
        { "<leader>t",  group = "[T]oggle" },
        { "<leader>h",  group = "Git [H]unk",        mode = { "n", "v" } },
        -- subgroups
        { "<leader>dg", group = "[D]ebug [G]o" },
      },
    },
  },

  -- File Explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "\\", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
    },
    config = function()
      require("neo-tree").setup({
        sources = { "filesystem", "buffers", "git_status" },
        open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
        enable_git_status = true,
        popup_border_style = "rounded",
        filesystem = {
          bind_to_cwd = true,
          follow_current_file = {
            enabled = true,
            leave_dirs_open = true,
            use_libuv_file_watcher = true,
          },
          use_libuv_file_watcher = true,
          group_empty_dirs = false,
          hijack_netrw_behavior = "open_default",
          window = {
            position = "left",
            mappings = {
              ["Z"] = "expand_all_nodes",
              ["z"] = "close_all_nodes",
              ["\\"] = "close_window",
            },
          },
          close_if_last_window = true,
          enable_git_status = true,
          enable_diagnostics = true,
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_by_pattern = { ".git" },
          },
        },
        default_component_configs = {
          icon = {
            folder_closed = "", -- "",
            folder_open = "", --"",
            folder_empty = "",
            default = "",
            highlight = "NeoTreeFileIcon",
            folder_empty_open = "",
          },
          git_status = {
            symbols = {
              added = "✚",
              modified = "",
              deleted = "✖",
              renamed = "➜",
              untracked = "★",
              ignored = "◌",
              -- unstaged = "✗",
              staged = "✓",
              conflict = "",
            },
          },
          indent = {
            with_markers = true,
            with_expanders = true,
            indent_marker = "│",
            last_indent_marker = "└",
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
        },
        auto_expand = true,
      })

      vim.keymap.set("n", "<leader>nb", ":Neotree buffers reveal float<CR>", {
        desc = "[N]eoTree [B]uffer Reveal",
        silent = true,
      })
    end,
  },

  -- OIL
  {
    "stevearc/oil.nvim",
    config = function()
      local oil = require("oil")
      oil.setup()
      vim.keymap.set("n", "-", oil.toggle_float, {})
    end,
  },

  -- git signs highlights text that has changed since the list
  -- git commit, and also lets you interactively stage & unstage
  -- hunks in a commit.
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    -- NOTE: gitsigns is already included in init.lua but contains only the base
    -- config. This will add also the recommended keymaps.
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Jump to next git [c]hange" })

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Jump to previous git [c]hange" })

        -- Actions
        -- visual mode
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "stage git hunk" })
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "reset git hunk" })
        -- normal mode
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
        map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
        map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "git [u]ndo stage hunk" })
        map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
        map("n", "<leader>hb", gitsigns.blame_line, { desc = "git [b]lame line" })
        map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
        map("n", "<leader>hD", function()
          gitsigns.diffthis("@")
        end, { desc = "git [D]iff against last commit" })
        -- Toggles
        map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
        map("n", "<leader>tD", gitsigns.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
      end,
    },
  },

  -- Git plugin to interact with git ex: `:Git diff`
  {
    "tpope/vim-fugitive",
  },

  -- {
  -- 	"tpope/vim-commentary",
  -- },
  --
  -- add this to your lua/plugins.lua, lua/plugins/init.lua,  or the file you keep your other plugins:
  {
    "numToStr/Comment.nvim",
    opts = {
      -- add any options here
      -- setup = function()
      -- 	local pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
      -- end,
    },
    lazy = false,
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },

  -- NOTE: this is an example note
  -- Highlight todo, notes, etc in comments
  {
    "folke/todo-comments.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },

  {
    "norcalli/nvim-colorizer.lua",
    lazy = true,
    event = "VeryLazy",
    config = function()
      require("colorizer").setup()
    end,
  },

  -- Game to get good at vim
  {
    "ThePrimeagen/vim-be-good",
    lazy = true,
  },
}
