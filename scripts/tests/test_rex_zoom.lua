-- Run from the repository root: luajit scripts/tests/test_rex_zoom.lua
-- All Rex calls are mocked; this never changes live sessions or panes.
local actions, bindings, calls = {}, {}, {}
local view, view_error, zoom_error, perform_error, perform_change
local queued, performed
local splits, split_error, split_change, split_result, process_info, process_error
local mock = {
  bind = function(key, action, args)
    bindings[key] = { action = action, args = args }
  end,
  action = function(action) actions[action.name] = action end,
  layout = { block = function(options) return { block = options } end },
  block = {
    call = function(creator, method, args)
      assert(creator == "com.superlogical.terminal" and method == "process")
      assert(args.session_id == "session:test")
      return process_info, process_error
    end,
  },
  client = {
    queue = function(action, args)
      queued[#queued + 1] = { action = action, args = args }
    end,
  },
  call = function(method, args)
    assert(method == "client.perform", "Never bypass client close handling")
    assert(args.client_id == "client:test")
    assert(args.session_id == "session:test")
    performed[#performed + 1] = args
    if perform_error then return nil, perform_error end
    if perform_change then perform_change(args) end
    return { performed_by = args.client_id }
  end,
  session = {
    new_split = function(args)
      splits[#splits + 1] = args
      assert(args.session_id == "session:test" and args.focus == false)
      assert(args.direction == "horizontal" and args.side == "after")
      assert(args.layout.block.flavor == "com.superlogical.terminal.shell")
      if split_error then return nil, split_error end
      for _, window in ipairs(view.windows) do
        for _, current_layer in ipairs(window.layers) do
          for index, block in ipairs(current_layer.blocks) do
            if block.block_id == args.anchor_id then
              table.insert(current_layer.blocks, index + 1, { block_id = "new" })
              window.zoomed_block_id = nil
              break
            end
          end
        end
      end
      if split_change then split_change() end
      return split_result
    end,
    view = function(args)
      assert(args.session_id == "session:test")
      return view, view_error
    end,
    zoom_block = function(args)
      calls[#calls + 1] = args
      if zoom_error then return nil, zoom_error end
      return { block_id = args.block_id, zoomed = args.zoom }
    end,
  },
}
local config = assert(loadfile("packages/rex/.config/rex/init.lua"))
setfenv(config, setmetatable({ rex = mock }, { __index = _G }))
config()
assert(#calls == 0, "Loading config must not operate on panes")
local action = assert(actions.cycle_fullscreen_pane)

local function layer(ids, state)
  local blocks = {}
  for _, id in ipairs(ids) do
    blocks[#blocks + 1] = { block_id = id, creator_name = "com.superlogical.terminal" }
  end
  return { blocks = blocks, state = state }
end

local function reset()
  calls, view_error, zoom_error = {}, nil, nil
  queued, performed, perform_error, perform_change = {}, {}, nil, nil
  splits, split_error, split_change, process_error = {}, nil, nil, nil
  split_result = { block_ids = { "new" } }
  process_info = { foreground = { cwd = "/project" } }
  view = {
    active_window_id = "window:first",
    windows = {
      {
        window_id = "window:first",
        focused_block_id = "a",
        layers = {
          layer({ "a", "b" }),
          layer({ "hidden" }, "minimized"),
          layer({ "c" }),
        },
      },
      {
        window_id = "window:second",
        focused_block_id = "other",
        layers = { layer({ "other", "another" }) },
      },
    },
  }
end

local function cycle(block_id, step)
  return action.run({ session_id = "session:test", block_id = block_id }, { step = step })
end

local function expect_target(target)
  assert(#calls == 1, "Expected exactly one atomic focus-and-zoom call")
  assert(calls[1].session_id == "session:test")
  assert(calls[1].block_id == target, "Wrong target: " .. tostring(calls[1].block_id))
  assert(calls[1].zoom == true, "Must set fullscreen, not toggle it")
end

local function edit(name, block_id, args)
  return assert(actions[name], "Missing action: " .. name).run({
    session_id = "session:test", block_id = block_id, client_id = "client:test", origin = "key",
  }, args or {})
end

local function remove_block(window, block_id)
  for _, current_layer in ipairs(window.layers) do
    for index, block in ipairs(current_layer.blocks) do
      if block.block_id == block_id then table.remove(current_layer.blocks, index); break end
    end
  end
  window.zoomed_block_id = nil
end

local tests = {
  next_pane = function()
    cycle("a", 1)
    expect_target("b")
  end,
  previous_wraps = function()
    cycle("a", -1)
    expect_target("c")
  end,
  next_wraps = function()
    cycle("c", 1)
    expect_target("a")
  end,
  skips_minimized_layers = function()
    cycle("b", 1)
    expect_target("c")
  end,
  follows_invoking_pane_not_another_active_tab = function()
    cycle("other", 1)
    expect_target("another")
  end,
  missing_context_uses_active_tab_focus = function()
    cycle(nil, 1)
    expect_target("b")
  end,
  fullscreen_cycle_keeps_fullscreen = function()
    view.windows[1].zoomed_block_id = "a"
    cycle("a", 1)
    expect_target("b")
  end,
  single_pane_stays_fullscreen = function()
    view.windows[1].layers = { layer({ "a" }) }
    cycle("a", 1)
    expect_target("a")
  end,
  stale_pane_does_not_switch_tabs = function()
    cycle("closed", 1)
    assert(#calls == 0)
  end,
  empty_tab_is_a_noop = function()
    view.windows[1].layers = {}
    cycle(nil, 1)
    assert(#calls == 0)
  end,
  view_failure_is_reported = function()
    view, view_error = nil, "view unavailable"
    local ok, err = pcall(cycle, "a", 1)
    assert(not ok and err == view_error)
    assert(#calls == 0)
  end,
  zoom_failure_is_reported = function()
    zoom_error = "pane closed"
    local ok, err = pcall(cycle, "a", 1)
    assert(not ok and err == zoom_error)
  end,
  no_session_fails_safely = function()
    local ok = pcall(action.run, {}, { step = 1 })
    assert(not ok and #calls == 0)
  end,
  new_pane_is_fullscreen_even_from_normal_layout = function()
    edit("new_fullscreen_pane", "a")
    expect_target("new")
    assert(#performed == 0 and #queued == 0 and #splits == 1)
    assert(splits[1].anchor_id == "a")
    assert(splits[1].layout.block.options.cwd == "/project")
  end,
  fullscreen_split_zooms_new_pane = function()
    view.windows[1].zoomed_block_id = "a"
    edit("new_fullscreen_pane", "a")
    expect_target("new")
    assert(#performed == 0 and #splits == 1)
  end,
  unsuccessful_split_does_not_zoom_or_retry = function()
    split_error = "split failed"
    local ok, err = pcall(edit, "new_fullscreen_pane", "a")
    assert(not ok and err == split_error)
    assert(#splits == 1 and #calls == 0 and #performed == 0)
  end,
  split_does_not_steal_focus_from_another_tab = function()
    split_change = function() view.active_window_id = "window:second" end
    edit("new_fullscreen_pane", "a")
    assert(#calls == 0)
  end,
  split_does_not_steal_focus_from_another_pane = function()
    split_change = function() view.windows[1].focused_block_id = "b" end
    edit("new_fullscreen_pane", "a")
    assert(#calls == 0)
  end,
  new_pane_does_not_require_app_callback = function()
    actions.new_fullscreen_pane.run({ session_id = "session:test", block_id = "a" }, {})
    expect_target("new")
    assert(#performed == 0)
  end,
  new_pane_uses_child_cwd_when_foreground_cwd_is_missing = function()
    process_info = { foreground = {}, child = { cwd = "/shell" } }
    edit("new_fullscreen_pane", "a")
    assert(splits[1].layout.block.options.cwd == "/shell")
  end,
  process_error_does_not_create_a_pane_in_the_wrong_directory = function()
    process_info, process_error = nil, "process unavailable"
    local ok, err = pcall(edit, "new_fullscreen_pane", "a")
    assert(not ok and err == process_error)
    assert(#splits == 0 and #calls == 0)
  end,
  missing_new_pane_id_is_reported_without_retrying = function()
    split_result = {}
    local ok = pcall(edit, "new_fullscreen_pane", "a")
    assert(not ok and #splits == 1 and #calls == 0)
  end,
  stale_new_pane_context_does_not_create_a_pane = function()
    edit("new_fullscreen_pane", "closed")
    assert(#splits == 0 and #calls == 0)
  end,
  normal_close_delegates_to_native_action = function()
    edit("close_preserving_fullscreen", "a")
    assert(#performed == 0 and #calls == 0)
    assert(#queued == 1 and queued[1].action == "pane.close")
  end,
  fullscreen_close_zooms_next_pane = function()
    view.windows[1].zoomed_block_id = "a"
    perform_change = function(args)
      assert(args.action == "pane.close" and args.block_id == "a")
      remove_block(view.windows[1], "a")
    end
    edit("close_preserving_fullscreen", "a")
    expect_target("b")
  end,
  fullscreen_close_uses_previous_at_end = function()
    view.windows[1].zoomed_block_id = "c"
    perform_change = function() remove_block(view.windows[1], "c") end
    edit("close_preserving_fullscreen", "c")
    expect_target("b")
  end,
  cancelled_close_leaves_fullscreen_untouched = function()
    view.windows[1].zoomed_block_id = "a"
    edit("close_preserving_fullscreen", "a")
    assert(#performed == 1 and #calls == 0)
    assert(view.windows[1].zoomed_block_id == "a")
  end,
  last_pane_close_does_not_zoom_another_tab = function()
    view.windows[1].layers = { layer({ "a" }) }
    view.windows[1].zoomed_block_id = "a"
    perform_change = function()
      table.remove(view.windows, 1)
      view.active_window_id = "window:second"
    end
    edit("close_preserving_fullscreen", "a")
    assert(#performed == 1 and #calls == 0)
  end,
  close_skips_minimized_layers = function()
    view.windows[1].zoomed_block_id = "b"
    perform_change = function() remove_block(view.windows[1], "b") end
    edit("close_preserving_fullscreen", "b")
    expect_target("c")
  end,
  closing_with_only_minimized_survivors_does_not_unhide_them = function()
    view.windows[1].layers = { layer({ "a" }), layer({ "hidden" }, "minimized") }
    view.windows[1].zoomed_block_id = "a"
    perform_change = function() remove_block(view.windows[1], "a") end
    edit("close_preserving_fullscreen", "a")
    assert(#calls == 0)
  end,
  close_does_not_steal_focus_from_another_tab = function()
    view.windows[1].zoomed_block_id = "a"
    perform_change = function()
      remove_block(view.windows[1], "a")
      view.active_window_id = "window:second"
    end
    edit("close_preserving_fullscreen", "a")
    assert(#calls == 0)
  end,
  vanished_successor_falls_back_to_previous = function()
    view.windows[1].zoomed_block_id = "b"
    perform_change = function()
      remove_block(view.windows[1], "b")
      remove_block(view.windows[1], "c")
    end
    edit("close_preserving_fullscreen", "b")
    expect_target("a")
  end,
  refused_client_action_is_not_retried_or_closed_directly = function()
    view.windows[1].zoomed_block_id = "a"
    perform_error = "client refused"
    local ok, err = pcall(edit, "close_preserving_fullscreen", "a")
    assert(not ok and err == perform_error)
    assert(#performed == 1 and #calls == 0 and #queued == 0)
  end,
  timed_out_close_is_not_retried = function()
    view.windows[1].zoomed_block_id = "a"
    perform_error = "client timed out"
    local ok, err = pcall(edit, "close_preserving_fullscreen", "a")
    assert(not ok and err == perform_error)
    assert(#performed == 1 and #calls == 0 and #queued == 0)
  end,
  missing_client_does_not_close_directly = function()
    view.windows[1].zoomed_block_id = "a"
    local ok = pcall(actions.close_preserving_fullscreen.run, {
      session_id = "session:test", block_id = "a",
    }, {})
    assert(not ok and #performed == 0 and #calls == 0)
  end,
  post_close_view_failure_does_not_guess_a_target = function()
    view.windows[1].zoomed_block_id = "a"
    perform_change = function() view, view_error = nil, "view unavailable" end
    local ok, err = pcall(edit, "close_preserving_fullscreen", "a")
    assert(not ok and err == view_error)
    assert(#performed == 1 and #calls == 0)
  end,
  stale_edit_context_does_not_modify_panes = function()
    edit("close_preserving_fullscreen", "closed")
    assert(#performed == 0 and #calls == 0 and #queued == 0)
  end,
}

assert(bindings["alt+cmd+["].action == action.name)
assert(bindings["alt+cmd+["].args.step == -1)
assert(bindings["alt+cmd+]"].action == action.name)
assert(bindings["alt+cmd+]"].args.step == 1)
assert(not bindings["cmd+["] and not bindings["cmd+]"], "Keep Rex's defaults")
assert(not bindings["cmd+d"] and not bindings["shift+cmd+d"] and not bindings["cmd+w"])
assert(bindings["ctrl+s>shift+5"].action == "pane.split")
assert(bindings["ctrl+s>shift+5"].args.direction == "right")
assert(bindings["ctrl+s>shift+'"].action == "pane.split")
assert(bindings["ctrl+s>shift+'"].args.direction == "down")
assert(bindings["ctrl+s>x"].action == "close_preserving_fullscreen")
assert(bindings["ctrl+s>shift+7"].action == "client.close")
assert(bindings["ctrl+p>s"].action == "new_fullscreen_pane")
assert(bindings["ctrl+p>ctrl+p"].action == "pane.send_key")
assert(bindings["ctrl+p>ctrl+p"].args.key == "ctrl+p")
assert(bindings["ctrl+s>r"].action == "client.config.reload")
assert(bindings["cmd+shift+r"].action == "client.config.reload")

local count = 0
for name, test in pairs(tests) do
  reset()
  local ok, err = pcall(test)
  assert(ok, name .. ": " .. tostring(err))
  count = count + 1
end
print(count .. " fullscreen-pane tests passed")
