return {
  -- notify
  --
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    lazy = true,
    keys = {
      {
        "<leader>un",
        function()
          require("notify").dismiss({ silent = true, pending = true })
        end,
        desc = "Dismiss All Notifications",
      },
    },
    opts = {
      stages = "static",
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    },
  },

  -- bufferline
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- Optional for file icons
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("bufferline").setup({
        options = {
          -- Add your options here
          show_buffer_close_icons = true,
          show_close_icon = true,
          separator_style = "thick",
          offsets = {
            {
              filetype = "neo-tree",
              text = "Neo-tree",
              -- highlight = "Dirctory",
              -- text_align = "left",
              padding = 2,
              -- padding = 1
            },
          },
        },
      })
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })

      vim.api.nvim_set_keymap("n", "<Tab>", ":bnext<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<S-Tab>", ":bprevious<CR>", { noremap = true, silent = true })
    end,
  },

  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    config = function()
      require("lualine").setup({
        options = {
          -- theme = 'dracula' -- 'dracula' -- 'horizon'
          theme = "github-dark", -- Your custom theme name
          icons_enabled = true,
          component_separators = " ",
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
        },
      })
    end,
  },

  -- indent-blankline
  { -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = "ibl",
    opts = {
      scope = { show_start = false, show_end = false },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "trouble",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
  },

  -- noice
  --
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    lazy = true,
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      views = {
        -- popupmenu = {
        --   border = {
        --     style = "rounded"
        --   }
        -- },
        -- popup = {
        --   border = {
        --     style = "rounded"
        --   }
        -- },
        -- mini = {
        --   border = {
        --     style = "rounded"
        --   }
        -- },
        -- cmdline_popup = {
        --   border = {
        --     style = "rounded"
        --   }
        -- },
        -- cmdline_popupmenu = {
        --   border = {
        --     style = "rounded"
        --   }
        -- },
        -- hover = {
        --   border = {
        --     style = "rounded"
        --   }
        -- }
      },
      -- views = {
      --   popupmenu = {
      --     border = {
      --       style = "rounded",
      --       padding = { 1, 3 },
      --     },
      --     win_options = {
      --       winhighlight = {
      --         Normal = "Normal",
      --         FloatBorder = "DiagnosticInfo"
      --       },
      --     },
      --   }
      -- }
    },
    -- stylua: ignore
    keys = {
      { "<leader>sn",  "",                                                                            desc = "+noice" },
      { "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",                              desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end,                                   desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end,                                desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end,                                    desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end,                                desc = "Dismiss All" },
      { "<leader>snt", function() require("noice").cmd("pick") end,                                   desc = "Noice Picker (Telescope/FzfLua)" },
      { "<c-f>",       function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true,                           expr = true,              desc = "Scroll Forward",  mode = { "i", "n", "s" } },
      { "<c-b>",       function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true,                           expr = true,              desc = "Scroll Backward", mode = { "i", "n", "s" } },
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
    end,
  },

  -- nui.nvim
  --
  { "MunifTanjim/nui.nvim", lazy = true },

  -- dashboard-nvim
  --
  {
    "nvimdev/dashboard-nvim",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
    lazy = false,
    priority = 3000,
    -- event = 'VimEnter',
    config = function()
      require("dashboard").setup({
        -- config
        hide = {
          statusline = false,
        },
      })
    end,
  },
}