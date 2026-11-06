-- Custom bindings complement Rex's defaults; helpers/actions live below.

-- Directional focus: Rex also provides Option+Cmd+arrows.
rex.bind("ctrl+s>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+s>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+s>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+s>l", "pane.focus", { direction = "right" })

-- Option provides the same directional focus without the prefix.
rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })
rex.bind("alt+l", "pane.focus", { direction = "right" })

-- Rearrange panes: Rex also provides Option+Shift+Cmd+arrows.
rex.bind("ctrl+s>shift+h", "pane.move", { direction = "left" })
rex.bind("ctrl+s>shift+j", "pane.move", { direction = "down" })
rex.bind("ctrl+s>shift+k", "pane.move", { direction = "up" })
rex.bind("ctrl+s>shift+l", "pane.move", { direction = "right" })

-- Ordinary splits: Rex has Cmd+D (right), Shift+Cmd+D (down), Cmd+Enter (best fit).
-- % and " on a US layout; Rex matches unshifted key names.
rex.bind("ctrl+s>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+s>shift+'", "pane.split", { direction = "down" })

-- Stack-inspired creation: Ctrl+P, S creates a pane and makes it fullscreen.
-- Rex's built-in alternative is split, then Shift+Cmd+Enter to toggle fullscreen.
rex.bind("ctrl+p>s", "new_fullscreen_pane")

-- Fullscreen: Rex has Shift+Cmd+Enter; Cmd+[ / Cmd+] cycles panes without keeping zoom.
rex.bind("ctrl+s>z", "pane.zoom")
rex.bind("alt+cmd+[", "cycle_fullscreen_pane", { step = -1 })
rex.bind("alt+cmd+]", "cycle_fullscreen_pane", { step = 1 })

-- Move panes between tabs: Rex also offers these actions in Cmd+Shift+P's palette.
rex.bind("ctrl+s>m", "pane.move_to_tab")
rex.bind("ctrl+s>shift+m", "pane.move_to_new_tab")

-- Close: Cmd+W is contextual; Option+Cmd+W closes a whole tab.
-- & (US layout) keeps the contextual close; X uses the fullscreen-aware trial.
rex.bind("ctrl+s>shift+7", "client.close")
rex.bind("ctrl+s>x", "close_preserving_fullscreen")

-- Tabs: Rex has Cmd+T, Ctrl+Tab / Ctrl+Shift+Tab, and Shift+Cmd+] / Shift+Cmd+[.
rex.bind("ctrl+s>c", "client.tab.new")
rex.bind("ctrl+s>n", "client.tab.next")
rex.bind("ctrl+s>p", "client.tab.previous")

-- Sessions: Rex has Cmd+K. Reload Config is also available in Cmd+Shift+P's palette.
rex.bind("ctrl+s>s", "session.switch")
rex.bind("ctrl+s>r", "client.config.reload")
-- Ghostty-style reload shortcut, alongside the prefix sequence above.
rex.bind("cmd+shift+r", "client.config.reload")

-- Forward intercepted prefixes to terminal applications (history, nested tmux).
rex.bind("ctrl+s>ctrl+s", "pane.send_key", { key = "ctrl+s" })
rex.bind("ctrl+p>ctrl+p", "pane.send_key", { key = "ctrl+p" })

-- Custom helpers and actions. Session operations run only inside action callbacks.

local function session_view(ctx)
  if not ctx.session_id then error("No session selected", 0) end
  local view, err = rex.session.view{ session_id = ctx.session_id }
  if not view then error(err, 0) end
  return view
end

local function window_by_id(view, window_id)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == window_id then return window end
  end
end

local function window_for_block(view, block_id)
  if not block_id then return window_by_id(view, view.active_window_id) end
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == block_id then return window end
      end
    end
  end
end

local function pane_ids(window)
  local blocks = {}
  for _, layer in ipairs(window.layers or {}) do
    if layer.state ~= "minimized" then
      for _, block in ipairs(layer.blocks or {}) do
        blocks[#blocks + 1] = block.block_id
      end
    end
  end
  return blocks
end

local function index_of(blocks, block_id)
  for index, id in ipairs(blocks) do
    if id == block_id then return index end
  end
end

local function fullscreen_pane(ctx, block_id)
  -- Explicitly set zoom: toggling would unzoom a tab with only one pane.
  local result, err = rex.session.zoom_block{
    session_id = ctx.session_id, block_id = block_id, zoom = true,
  }
  if not result then error(err, 0) end
  return result
end

-- Cycle fullscreen panes without changing Rex's normal Cmd+[ / Cmd+] bindings.
rex.action{
  name = "cycle_fullscreen_pane",
  title = "Cycle Fullscreen Pane",
  category = "Pane",
  args = {
    type = "object",
    properties = { step = { type = "integer", enum = { -1, 1 } } },
    required = { "step" },
    additionalProperties = false,
  },
  run = function(ctx, args)
    local current_window = window_for_block(session_view(ctx), ctx.block_id)
    if not current_window then return end

    -- Match Rex's layout order, leaving minimized floating layers untouched.
    local blocks = pane_ids(current_window)
    local focused = ctx.block_id or current_window.focused_block_id
    if #blocks == 0 then return end

    local index = index_of(blocks, focused) or (args.step == 1 and 0 or 1)
    local target = blocks[(index - 1 + args.step) % #blocks + 1]
    return fullscreen_pane(ctx, target)
  end,
}

rex.action{
  name = "new_fullscreen_pane",
  title = "New Fullscreen Pane",
  category = "Pane",
  run = function(ctx)
    local window = window_for_block(session_view(ctx), ctx.block_id)
    if not window then return end
    local focused = ctx.block_id or window.focused_block_id
    if not focused then return end

    local options = {}
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == focused and block.creator_name == "com.superlogical.terminal" then
          local process, err = rex.block.call("com.superlogical.terminal", "process", {
            session_id = ctx.session_id, block_id = focused,
          })
          if not process then error(err, 0) end
          options.cwd = (process.foreground or {}).cwd or (process.child or {}).cwd
        end
      end
    end

    -- Create directly on the server: synchronously calling back into the app
    -- from its own Lua action can time out. The result identifies the exact pane.
    local created, err = rex.session.new_split{
      session_id = ctx.session_id,
      anchor_id = focused,
      direction = "horizontal",
      side = "after",
      layout = rex.layout.block{ flavor = "com.superlogical.terminal.shell", options = options },
      focus = false,
    }
    if not created then error(err, 0) end
    local block_id = (created.block_ids or {})[1]
    if not block_id then error("Split created no pane; inspect the tab before retrying", 0) end

    local after_view = session_view(ctx)
    local after_window = window_by_id(after_view, window.window_id)
    if after_window and after_view.active_window_id == window.window_id
      and after_window.focused_block_id == focused then
      return fullscreen_pane(ctx, block_id)
    end
    return created
  end,
}

local function close_preserving_fullscreen(ctx)
  local window = window_for_block(session_view(ctx), ctx.block_id)
  if not window then return end
  local focused = ctx.block_id or window.focused_block_id
  if not focused then return end
  if not window.zoomed_block_id then
    rex.client.queue("pane.close")
    return
  end
  if window.zoomed_block_id ~= focused then return end
  if not ctx.client_id then error("A Rex app client is required", 0) end

  local before = pane_ids(window)
  -- Let the app perform the native action, including its close handling. Never
  -- bypass a refusal/timeout with block.close or retry a possibly completed edit.
  local performed, err = rex.call("client.perform", {
    client_id = ctx.client_id,
    session_id = ctx.session_id,
    block_id = focused,
    action = "pane.close",
    origin = ctx.origin,
    timeout_ms = 25000,
  })
  if not performed then error(err, 0) end

  local after_view = session_view(ctx)
  local after_window = window_by_id(after_view, window.window_id)
  -- The user may have switched tabs during a confirmation. Do not pull them back.
  if not after_window or after_view.active_window_id ~= window.window_id then return end
  local remaining = pane_ids(after_window)
  -- A cancelled/deferred close leaves the old pane present: do nothing to zoom.
  if window_for_block(after_view, focused) then return end
  local index = index_of(before, focused)
  if not index then return end
  for next_index = index + 1, #before do
    if index_of(remaining, before[next_index]) then
      return fullscreen_pane(ctx, before[next_index])
    end
  end
  for previous_index = index - 1, 1, -1 do
    if index_of(remaining, before[previous_index]) then
      return fullscreen_pane(ctx, before[previous_index])
    end
  end
end

rex.action{
  name = "close_preserving_fullscreen",
  title = "Close Pane (Preserve Fullscreen)",
  category = "Pane",
  run = close_preserving_fullscreen,
}
