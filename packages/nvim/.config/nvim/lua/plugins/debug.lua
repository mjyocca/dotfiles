-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  "mfussenegger/nvim-dap",
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    "rcarriga/nvim-dap-ui",

    -- virtual text for the debugger
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },

    -- Required dependency for nvim-dap-ui
    "nvim-neotest/nvim-nio",

    -- Installs the debug adapters for you
    "williamboman/mason.nvim",
    "jay-babu/mason-nvim-dap.nvim",

    -- Add your own debuggers here
    "leoluz/nvim-dap-go",
    "suketa/nvim-dap-ruby",
  },
  keys = function(_, keys)
    local dap = require("dap")
    local dapui = require("dapui")
    return {
      -- Basic debugging keymaps, feel free to change to your liking!
      { "<F5>",       dap.continue,          desc = "Debug: Start/Continue" },
      { "<F1>",       dap.step_into,         desc = "Debug: Step Into" },
      { "<F2>",       dap.step_over,         desc = "Debug: Step Over" },
      { "<F3>",       dap.step_out,          desc = "Debug: Step Out" },
      { "<leader>db", dap.toggle_breakpoint, desc = "[D]ebug: Toggle [B]reakpoint" },
      {
        "<leader>dB",
        function()
          dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Debug: Set Breakpoint",
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      { "<F7>", dapui.toggle, desc = "Debug: See last session result." },
      {
        "<leader>du",
        function()
          require("dapui").toggle({})
        end,
        desc = "[D]ebug: Dap [U]I",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        desc = "[D]ebug: Dap [E]val",
        mode = { "n", "v" },
      },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- vim.keymap.set("n", "<leader>dh", function()
    --   require("dap.ui.widgets").hover()
    --   require("dapui").refresh()
    -- end, { desc = "Show debugger hover info and refresh UI" })

    require("mason-nvim-dap").setup({
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        "delve",
        "rdbg",
      },
    })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup({
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      --
      element_mappings = {},
      expand_lines = true,
      floating = {
        border = "single",
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      force_buffers = true,
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        repl = "r",
        toggle = "t",
      },
      render = {
        indent = 1,
        max_value_lines = 100,
      },
      icons = {
        expanded = "▾",
        collapsed = "▸",
        current_frame = "*",
      },
      controls = {
        enabled = true,
        element = "repl",
        icons = {
          disconnect = "",
          pause = "",
          play = "",
          run_last = "",
          step_back = "",
          step_into = "",
          step_out = "",
          step_over = "",
          terminate = "",
        },
      },
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.25,
            },
            {
              id = "breakpoints",
              size = 0.25,
            },
            {
              id = "stacks",
              size = 0.25,
            },
            {
              id = "watches",
              size = 0.25,
            },
          },
          position = "left",
          size = 40,
        },
        {
          elements = {
            {
              id = "repl",
              size = 0.5,
            },
            {
              id = "console",
              size = 0.5,
            },
          },
          position = "bottom",
          size = 10,
        },
      },
    })

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, "DapUIPlayPauseNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIRestartNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIStepOutNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIStepBackNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIStepIntoNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIStepOverNC", { bg = "none" })
    vim.api.nvim_set_hl(0, "DapUIStopNC", { bg = "none" })

    local breakpoint_icons = vim.g.have_nerd_font
        and {
          Breakpoint = "",
          BreakpointCondition = "",
          BreakpointRejected = "",
          LogPoint = "",
          Stopped = "",
        }
        or {
          Breakpoint = "●",
          BreakpointCondition = "⊜",
          BreakpointRejected = "⊘",
          LogPoint = "◆",
          Stopped = "⭔",
        }
    for type, icon in pairs(breakpoint_icons) do
      local tp = "Dap" .. type
      local hl = (type == "Stopped") and "DapStop" or "DapBreak"
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open({})
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- Install golang specific config
    require("dap-go").setup({
      dap_configuration = {
        {
          -- Name as it will appear in the DAP UI
          name = "Debug Test custom",
          type = "go",
          request = "launch",
          mode = "test",  -- This tells Delve to run tests
          program = "${file}", -- Runs tests in the current file
          -- dlvToolPath = vim.fn.exepath("dlv"), -- Adjust if dlv isn't in your PATH
        },
      },
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has("win32") == 0,
        initialize_timeout_sec = 20,
        build_flags = {},
      },
      tests = {
        -- enables verbosity when running the test.
        verbose = true,
      },
    })

    vim.keymap.set("n", "<leader>dgt", function()
      -- local widgets = require("dap.ui.widgets")
      -- local sidebar = widgets.sidebar(widgets.scopes)
      require("dap-go").debug_test()
      -- require('dapui').open()

      -- sidebar.open()
    end, { desc = "[D]ebug [G]o [T]est" })

    vim.keymap.set("n", "<leader>dgl", function()
      require("dap-go").debug_last()
    end, { desc = "[D]ebug [G]o [L]ast test" })

    local relative_config_path = os.getenv("NVIM_PROJECT_DAP_CONFIG") or "/.nvim/dap.lua"
    local project_dap_config = vim.fn.getcwd() .. relative_config_path
    if vim.fn.filereadable(project_dap_config) == 1 then
      dofile(project_dap_config)
    end

    require("dap").set_log_level("TRACE")
  end,
}
