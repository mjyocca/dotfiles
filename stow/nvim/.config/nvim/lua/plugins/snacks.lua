local dashboard = {
  enabled = true,
  pane_gap = 8,
  sections = {
    { section = "header" },
    { section = "keys",  gap = 1, padding = 1 },
    {
      pane = 2,
      icon = " ",
      title = "Recent Files",
      section = "recent_files",
      limit = 8,
      indent = 2,
      padding = 1,
    },
    {
      pane = 2,
      icon = " ",
      title = "Projects",
      section = "projects",
      limit = 8,
      indent = 2,
      padding = 1,
    },
    -- {
    -- 	pane = 2,
    -- 	icon = " ",
    -- 	title = "Git Status",
    -- 	section = "terminal",
    -- 	enabled = function()
    -- 		return require("snacks").git.get_root() ~= nil
    -- 	end,
    -- 	cmd = "git status --short --branch --renames",
    -- 	height = 5,
    -- 	padding = 1,
    -- 	ttl = 5 * 60,
    -- 	indent = 2,
    -- },
    { section = "startup" },
  },
}

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    toggles = {
      follow = "f",
      hidden = "h",
      ignored = "i",
      modified = "m",
      regex = { icon = "R", value = false },
    },
    matcher = { frecency = true },
    picker = {
      -- debug = { scores = true },
      matcher = { frecency = true },
      icons = {
        files = {
          -- dir = "",
          -- dir_open = "",
          dir = " ",
          dir_open = " ",
        },
        ui = {
          live = "󰐰 ",
          hidden = " ",
          ignored = " ",
          follow = "f",
          selected = "● ",
          unselected = "○ ",
        },
      },
      sources = {
        files = {
          hidden = true,
          ignored = true,
        },
        grep = {
          hidden = true,
          ignored = true,
        },
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            -- sidebar
            preview = false,
            layout = {
              backdrop = true,
              width = 40,
              min_width = 40,
              height = 0,
              position = "left",
              border = "none",
              box = "vertical",
              {
                win = "input",
                height = 1,
                border = "rounded",
                title = "{flags}",
                title_pos = "right",
              },
              { win = "list",    border = "none" },
              { win = "preview", title = "{preview}", height = 0.4, border = "top" },
            },
          },
        },
      },
    },
    explorer = {
      enabled = true,
      supports_live = true,
      live = true,
      replace_netrw = true,
      git_status_open = true,
      auto_close = true,
    },
    notifier = { enabled = true },
    dashboard = dashboard,
    scroll = { enabled = true },
    statuscolumn = {
      left = { "mark", "sign" }, -- priority of signs on the left (high to low)
      right = { "fold", "git" }, -- priority of signs on the right (high to low)
      folds = {
        open = false, -- show open fold icons
        git_hl = false, -- use Git Signs hl for fold icons
      },
      git = {
        -- patterns to match Git signs
        patterns = { "GitSign", "MiniDiffSign" },
      },
      refresh = 50, -- refresh at most every 50ms
    },
    indent = {
      enabled = true,
      only_scope = true,
      only_current = true,
    },
    scope = { enabled = true },
    toggle = {
      enabled = true,
      which_key = true,
    },
    scratch = { enabled = true },
    debug = { enabled = true },
    terminal = { enabled = true },
    git = { enabled = true },
    words = {},
    gitbrowse = { enabled = true },
    lazygit = {
      enabled = true,
      configure = true,
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        Snacks.explorer()
      end,
      desc = "File Explorer",
    },
    {
      "\\",
      function()
        Snacks.explorer()
      end,
      desc = "File Explorer",
    },
    {
      "<leader>sb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "[S]earch Open [B]uffers",
    },
    {
      "<leader><leader>",
      function()
        Snacks.picker.buffers()
      end,
      desc = "[S]earch Open [B]uffers",
    },
    {
      "<leader>sF",
      function()
        Snacks.picker.smart()
      end,
      desc = "[S]mart [F]ind Files",
    },
    {
      "<leader>sf",
      function()
        Snacks.picker.files()
      end,
      desc = "[S]earch Files",
    },
    {
      "<leader>sg",
      function()
        Snacks.picker.grep()
      end,
      desc = "[S]earch by [G]rep"
    },
    {
      "<leader>sC",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "[S]earch [C]olorschemes",
    },
    {
      "<leader>sI",
      function()
        Snacks.picker.icons()
      end,
      desc = "[S]earch [I]cons",
    },
    {
      "<leader>sH",
      function()
        Snacks.picker.highlights()
      end,
      desc = "[S]earch [H]ighlights",
    }
  },
  init = function()
    require("config.autocmds").snacks({})
  end,
}
