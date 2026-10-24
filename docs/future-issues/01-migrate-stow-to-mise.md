# Migrate from Stow to mise for dotfiles management

## Background

Currently using GNU Stow for dotfiles management (Phase 1 of unified package architecture). Mise can also manage dotfiles with additional features like templates, platform variants, and self-managing config.

## Benefits

- **Unified tooling**: Single tool for dev tools + dotfiles (mise)
- **Advanced features**: Templates, copy mode, platform variants
- **Self-managing**: mise can manage its own config file
- **Better conflict handling**: More sophisticated than Stow

## Migration Steps

1. Add [dotfiles] section to packages/mise/.config/mise/config.toml
2. Convert each stow package to mise dotfiles entries
3. Test on both macOS and Omarchy
4. Update documentation (AGENTS.md, platform instructions)
5. Remove stow from system packages (Brewfile, pacman packages.txt)

## Considerations

- Stow is currently working well
- Omarchy endorses Stow for dotfiles backup
- Migration effort is medium (all dotfiles need testing)
- Can be done incrementally, one package at a time

## References

- [mise dotfiles documentation](https://mise.jdx.dev/dotfiles/managed.html)
- [Spec document](/home/michaelyocca/.opencode/plan/spec_unified_package_management.md)

## Current State

- **Status**: Phase 2 (deferred)
- **Phase 1**: ✅ Complete - mise for dev tools
- **Phase 2**: ⏳ Migrate Stow to mise (this issue)
- **Phase 3**: ⏳ Migrate asdf to mise (see related issue)
