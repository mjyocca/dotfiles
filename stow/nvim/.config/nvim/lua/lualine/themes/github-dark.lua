-- lua/lualine/themes/github-dark.lua

-- TODO: Remove hardcoded value here
local palette = require("github-theme.palette").load("github_dark_default")

local colors = {
  bg = palette.black.base,
  fg = palette.white.base,
  yellow = palette.yellow.bright,
  cyan = palette.cyan.base,
  darkblue = palette.canvas.overlay,
  green = palette.green.base,
  orange = palette.orange.base,
  violet = palette.done.emphasis,
  magenta = palette.magenta.base,
  blue = palette.accent.emphasis,
  red = palette.danger.fg,
  transparent = "NONE",
}

return {
  normal = {
    a = { fg = colors.bg, bg = colors.blue, gui = "bold" },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  insert = {
    a = { fg = colors.bg, bg = colors.green, gui = "bold" },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  visual = {
    a = { fg = colors.bg, bg = colors.violet, gui = "bold" },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  replace = {
    a = { fg = colors.bg, bg = colors.red, gui = "bold" },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  command = {
    a = { fg = colors.bg, bg = colors.orange, gui = "bold" },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  inactive = {
    a = { fg = colors.fg, bg = colors.transparent },
    b = { fg = colors.fg, bg = colors.transparent },
    c = { fg = colors.fg, bg = colors.transparent },
  },
}

-- NOTE: github-theme github-dark output colors
-- {
--   accent = {
--     emphasis = "#1f6feb",
--     fg = "#2f81f7",
--     muted = "#1e4273",
--     subtle = "#132339"
--   },
--   attention = {
--     emphasis = "#9e6a03",
--     fg = "#d29922",
--     muted = "#533d11",
--     subtle = "#272215"
--   },
--   black = {
--     base = "#0d1117",
--     bright = "#161b22"
--   },
--   blue = {
--     base = "#58a6ff",
--     bright = "#79c0ff"
--   },
--   border = {
--     default = "#161b22",
--     muted = "#21262d",
--     subtle = "#24282e"
--   },
--   canvas = {
--     default = "#0d1117",
--     inset = "#010409",
--     overlay = "#161b22",
--     subtle = "#161b22"
--   },
--   closed = {
--     emphasis = "#da3633",
--     fg = "#f85149",
--     muted = "#6b2b2b",
--     subtle = "#301b1e"
--   },
--   cyan = {
--     base = "#76e3ea",
--     bright = "#b3f0ff"
--   },
--   danger = {
--     emphasis = "#da3633",
--     fg = "#f85149",
--     muted = "#6b2b2b",
--     subtle = "#25171c"
--   },
--   done = {
--     emphasis = "#8957e5",
--     fg = "#a371f7",
--     muted = "#493771",
--     subtle = "#1c1b2d"
--   },
--   fg = {
--     default = "#e6edf3",
--     muted = "#7d8590",
--     on_emphasis = "#ffffff",
--     subtle = "#6e7681"
--   },
--   generate_spec = <function 1>,
--   gray = {
--     base = "#6e7681",
--     bright = "#6e7681"
--   },
--   green = {
--     base = "#3fb950",
--     bright = "#56d364"
--   },
--   magenta = {
--     base = "#bc8cff",
--     bright = "#d2a8ff"
--   },
--   meta = {
--     light = false,
--     name = "github_dark_default"
--   },
--   neutral = {
--     emphasis = "#6e7681",
--     emphasis_plus = "#6e7681",
--     muted = "#343941",
--     subtle = "#171b22"
--   },
--   open = {
--     emphasis = "#238636",
--     fg = "#3fb950",
--     muted = "#1a4a29",
--     subtle = "#12261e"
--   },
--   orange = "#f0883e",
--   pink = {
--     base = "#f778ba",
--     bright = "#ff9bce"
--   },
--   red = {
--     base = "#ff7b72",
--     bright = "#ffa198"
--   },
--   scale = {
--     black = "#010409",
--     blue = { "#cae8ff", "#a5d6ff", "#79c0ff", "#58a6ff", "#388bfd", "#1f6feb", "#1158c7", "#0d419d", "#0c2d6b", "#051d4d" },
--     coral = { "#ffddd2", "#ffc2b2", "#ffa28b", "#f78166", "#ea6045", "#cf462d", "#ac3220", "#872012", "#640d04", "#460701" },
--     gray = { "#f0f6fc", "#c9d1d9", "#b1bac4", "#8b949e", "#6e7681", "#484f58", "#30363d", "#21262d", "#161b22", "#0d1117" },
--     green = { "#aff5b4", "#7ee787", "#56d364", "#3fb950", "#2ea043", "#238636", "#196c2e", "#0f5323", "#033a16", "#04260f" },
--     orange = { "#ffdfb6", "#ffc680", "#ffa657", "#f0883e", "#db6d28", "#bd561d", "#9b4215", "#762d0a", "#5a1e02", "#3d1300" },
--     pink = { "#ffdaec", "#ffbedd", "#ff9bce", "#f778ba", "#db61a2", "#bf4b8a", "#9e3670", "#7d2457", "#5e103e", "#42062a" },
--     purple = { "#eddeff", "#e2c5ff", "#d2a8ff", "#bc8cff", "#a371f7", "#8957e5", "#6e40c9", "#553098", "#3c1e70", "#271052" },
--     red = { "#ffdcd7", "#ffc1ba", "#ffa198", "#ff7b72", "#f85149", "#da3633", "#b62324", "#8e1519", "#67060c", "#490202" },
--     white = "#ffffff",
--     yellow = { "#f8e3a1", "#f2cc60", "#e3b341", "#d29922", "#bb8009", "#9e6a03", "#845306", "#693e00", "#4b2900", "#341a00" }
--   },
--   severe = {
--     emphasis = "#bd561d",
--     fg = "#db6d28",
--     muted = "#5f361e",
--     subtle = "#221a19"
--   },
--   sponsors = {
--     emphasis = "#bf4b8a",
--     fg = "#db61a2",
--     muted = "#5f314f",
--     subtle = "#221925"
--   },
--   success = {
--     emphasis = "#238636",
--     fg = "#3fb950",
--     muted = "#1a4a29",
--     subtle = "#12261e"
--   },
--   white = {
--     base = "#b1bac4",
--     bright = "#b1bac4"
--   },
--   yellow = {
--     base = "#d29922",
--     bright = "#e3b341"
--   }
-- }
