-- Tmux-style prefix sequences; keep Rex's default shortcuts available.
rex.bind("ctrl+s>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+s>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+s>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+s>l", "pane.focus", { direction = "right" })

-- Shift moves the pane instead of changing focus.
rex.bind("ctrl+s>shift+h", "pane.move", { direction = "left" })
rex.bind("ctrl+s>shift+j", "pane.move", { direction = "down" })
rex.bind("ctrl+s>shift+k", "pane.move", { direction = "up" })
rex.bind("ctrl+s>shift+l", "pane.move", { direction = "right" })

-- % and " on a US keyboard layout; Rex matches unshifted key names.
rex.bind("ctrl+s>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+s>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+s>z", "pane.zoom")

-- & (US layout) uses Rex's contextual close (Cmd+W), not whole-tab close.
rex.bind("ctrl+s>shift+7", "client.close")
rex.bind("ctrl+s>x", "pane.close")

rex.bind("ctrl+s>c", "client.tab.new")
rex.bind("ctrl+s>n", "client.tab.next")
rex.bind("ctrl+s>p", "client.tab.previous")
rex.bind("ctrl+s>s", "session.switch")
rex.bind("ctrl+s>r", "client.config.reload")

-- Forward the prefix to terminal applications (including nested tmux).
rex.bind("ctrl+s>ctrl+s", "pane.send_key", { key = "ctrl+s" })
