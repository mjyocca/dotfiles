# Rex

The macOS mise selection deploys `packages/rex/.config/rex/init.lua` to
`~/.config/rex/init.lua`. Rex installation is managed separately.

See [init.lua](../../packages/rex/.config/rex/init.lua) for shared bindings.
Rex defaults remain available; app-local shortcuts take precedence.

Selected macOS UI preferences are tracked in
[macOS mise configuration](../../.config/mise/config.macos.toml), applied by `make config`,
not `make link` or `rex config reload`. Session and host state remain local.

Repository workflow and verification: [Rex guidance](../instructions/rex.md).
For version differences, prefer installed `rex --help`, `rex api describe METHOD`,
and the connected client's action list over website examples. Check `REX_CONFIG`
and `XDG_CONFIG_HOME` when troubleshooting config discovery; reloads are explicit.

## Customize

- [Configuration file](https://www.superlogical.com/rex/docs/customize/config.md) — discovery, modules, reloads
- [Mac settings](https://www.superlogical.com/rex/docs/reference/mac-settings.md) — sidebar, appearance, terminal preferences
- [Keyboard shortcuts](https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts.md) — binding syntax and precedence
- [Key sequences](https://www.superlogical.com/rex/docs/customize/key-sequences.md) — tmux-style prefixes
- [Key modes](https://www.superlogical.com/rex/docs/customize/key-modes.md) — persistent/one-shot tables and exclusive modes
- [Custom actions](https://www.superlogical.com/rex/docs/customize/actions.md) — reusable callbacks, arguments, error handling

## Automate

- [CLI](https://www.superlogical.com/rex/docs/automate/cli.md) — resource types, targets, JSON output
- [Agents](https://www.superlogical.com/rex/docs/automate/agent-skill.md) — installed skill setup and supported hooks
- [Lua scripts](https://www.superlogical.com/rex/docs/automate/lua-scripts.md) — `rex do`, snippets, layouts, commands, waits, timers
- [Lua events](https://www.superlogical.com/rex/docs/automate/lua-events.md) — listeners, scope, lifetime, failure handling
- [Shell scripting](https://www.superlogical.com/rex/docs/automate/shell-scripting.md) — CLI composition, capture, process waits
- [Server API](https://www.superlogical.com/rex/docs/automate/server-api.md) — version-matched methods and schemas

References: [Lua API](https://www.superlogical.com/rex/docs/reference/lua.md),
[events](https://www.superlogical.com/rex/docs/reference/events.md),
[Mac actions](https://www.superlogical.com/rex/docs/reference/mac-actions.md),
and the [documentation index](https://www.superlogical.com/rex/docs/llms.txt).
