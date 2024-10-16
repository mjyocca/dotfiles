-- lua/lualine/themes/github-dark.lua
local colors = {
  bg = '#0d1117',      -- Background color (main window)
  fg = '#c9d1d9',      -- Foreground color (text)
  yellow = '#d29922',  -- Yellow (warnings, etc.)
  cyan = '#56d4dd',    -- Cyan (secondary elements)
  darkblue = '#161b22', -- Dark blue (inactive areas)
  green = '#28a745',   -- Green (success)
  orange = '#d18616',  -- Orange (warnings)
  violet = '#8a63d2',  -- Violet (special elements)
  magenta = '#b392f0', -- Magenta (secondary)
  blue = '#539bf5',    -- Blue (primary elements)
  red = '#f85149',     -- Red (errors)
  transparent = nil, 
}

-- \ "base0"        : ["#0d1117", 233],
-- \ "base1"        : ["#161b22", 235],
-- \ "base2"        : ["#21262d", 237],
-- \ "base3"        : ["#89929b", 243],
-- \ "base4"        : ["#c6cdd5", 249],
-- \ "base5"        : ["#ecf2f8", 252],
-- \ "red"          : ["#fa7970", 210],
-- \ "orange"       : ["#faa356", 178],
-- \ "green"        : ["#7ce38b", 114],
-- \ "lightblue"    : ["#a2d2fb", 153],
-- \ "blue"         : ["#77bdfb", 75],
-- \ "purp"         : ["#cea5fb", 183],
-- \ "none"         : ["NONE", "NONE"]

return {
  normal = {
    a = { fg = colors.bg, bg = colors.blue, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  insert = {
    a = { fg = colors.bg, bg = colors.green, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  visual = {
    a = { fg = colors.bg, bg = colors.violet, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  replace = {
    a = { fg = colors.bg, bg = colors.red, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  command = {
    a = { fg = colors.bg, bg = colors.orange, gui = 'bold' },
    b = { fg = colors.fg, bg = colors.darkblue },
    c = { fg = colors.fg, bg = colors.transparent },
  },
  inactive = {
    a = { fg = colors.fg, bg = colors.transparent },
    b = { fg = colors.fg, bg = colors.transparent },
    c = { fg = colors.fg, bg = colors.transparent },
  },
}
