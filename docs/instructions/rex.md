# Rex Configuration and Automation

Use the tool-provided `rex` skill for CLI operations, if available. Otherwise,
consult installed CLI help and the version-matched sources in
[the reference](../reference/rex.md). Do not install a missing skill or create a
repository copy as a prerequisite for Rex work.
Paths below are relative to the repository root.

- Keep shared bindings in `packages/rex/.config/rex/init.lua`; retain Rex defaults
  and the contextual close action. Keep machine-specific hosts and credentials local.
- macOS app preferences belong in `.config/mise/config.macos.toml` under
  `[bootstrap.macos.defaults."com.superlogical.rex"]`, not a full plist symlink.
  Track selected UI keys only; exclude session state, hosts, permissions, and
  update metadata. Inspect installed keys and validate with
  `mise -E macos bootstrap macos defaults apply --dry-run`.
- Keep `init.lua` declarative: session operations belong in action callbacks;
  event listeners belong in separate `rex do` scripts. Running a draft action with
  `rex do` performs real operations, not validation.
- Confirm targets before automation. Inherited Rex IDs identify the calling
  terminal, not necessarily the app's focused pane; retain explicit IDs in scripts.
- Validate edits with `rex config check packages/rex/.config/rex/init.lua`.
  Discover client actions with `rex client ls` and `rex -C CLIENT actions --json`;
  config validation alone does not establish action availability.
- Follow [deployment guidance](mise-dotfiles.md) before an authorized apply.
  Reload explicitly with `rex config reload` on the server's machine only when
  authorized, then inspect `rex keymap` for loaded bindings and diagnostics.
  Do not close working panes or tabs merely to test a shortcut.
