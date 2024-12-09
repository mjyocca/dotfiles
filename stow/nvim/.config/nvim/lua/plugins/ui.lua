return {
  -- notify
  --
  -- {
  --   "rcarriga/nvim-notify",
  --   event = "VeryLazy",
  --   lazy = true,
  --   keys = {
  --     {
  --       "<leader>un",
  --       function()
  --         require("notify").dismiss({ silent = true, pending = true })
  --       end,
  --       desc = "Dismiss All Notifications",
  --     },
  --   },
  --   opts = {
  --     stages = "static",
  --     timeout = 3000,
  --     max_height = function()
  --       return math.floor(vim.o.lines * 0.75)
  --     end,
  --     max_width = function()
  --       return math.floor(vim.o.columns * 0.75)
  --     end,
  --     on_open = function(win)
  --       vim.api.nvim_win_set_config(win, { zindex = 100 })
  --     end,
  --   },
  -- },

  -- bufferline
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    lazy = true,
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
          -- separator_style = "thick",
          offsets = {
            {
              filetype = "neo-tree",
              text = "Neo-tree",
              padding = 2,
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
    lazy = true,
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

  -- filename
  -- https://github.com/b0o/incline.nvim
  {
    "b0o/incline.nvim",
    dependencies = {},
    event = "BufReadPre",
    priority = 1200,
    config = function()
      local helpers = require("incline.helpers")
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
          local modified = vim.bo[props.buf].modified
          local buffer = {
            { (ft_icon or "") .. " ", guifg = ft_color,                           guibg = "none" },
            -- ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) },
            -- " ",
            --TODO: remove hardcoded reference to hex color
            { filename .. " ",        gui = modified and "bold,italic" or "bold", guifg = "#c9d1d9" },
            " ",
            guibg = "none",
          }
          return buffer
        end,
      })
    end,
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "query",
        "vim",
        "vimdoc",
        "html",
        "css",
        "javascript",
        "typescript",
        "ruby",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "zig",
        "rust",
      },
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
      incremental_selection = {
        enable = true,
      },
      folding = {
        enable = true,
      },
    },
  },

  -- indent-blankline
  { -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    lazy = true,
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
        popupmenu = {
          border = {
            style = "rounded",
            padding = { 1, 3 },
          },
          win_options = {
            winhighlight = {
              Normal = "Normal",
              FloatBorder = "DiagnosticInfo",
            },
          },
        },
      },
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

  -- dashboard plugin
  -- {
  --   "goolord/alpha-nvim",
  --   lazy = false,
  --   priority = 1000,
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   config = function()
  --     local alpha = require("alpha")
  --     local dashboard = require("alpha.themes.startify")

  -- dashboard.section.header.val = {
  --   [[=================     ===============     ===============   ========  ========]],
  --   [[\\ . . . . . . .\\   //. . . . . . .\\   //. . . . . . .\\  \\. . .\\// . . //]],
  --   [[||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||]],
  --   [[|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||]],
  --   [[||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||]],
  --   [[|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\ . . . . ||]],
  --   [[||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||]],
  --   [[|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||]],
  --   [[||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||]],
  --   [[||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||]],
  --   [[||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||]],
  --   [[||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||]],
  --   [[||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||]],
  --   [[||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||]],
  --   [[||   .=='    _-'          '-__\._-'         '-_./__-'         `' |. /|  |   ||]],
  --   [[||.=='    _-'                                                     `' |  /==.||]],
  --   [[=='    _-'                        N E O V I M                         \/   `==]],
  --   [[\   _-'                                                                `-_   /]],
  --   [[ `''                                                                      ``' ]],
  -- }

  --     alpha.setup(dashboard.opts)
  --   end,
  -- },
}
