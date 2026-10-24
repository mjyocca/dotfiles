# Migrate from asdf to mise for language runtimes

## Background

Currently using asdf for language runtime management (nodejs, ruby, golang, rust, zig, etc.). Mise can replace asdf with better performance, more features, and unified tooling.

## Benefits

- **Single tool**: Unified management for dev tools + language runtimes
- **Better performance**: No shims, uses PATH manipulation (5ms vs 120ms overhead)
- **More features**: Environment variables, task runner, bootstrap tool
- **Better security**: Built-in supply chain security (Cosign/SLSA verification)
- **Cross-platform**: Works on macOS and Linux with same config

## Migration Steps

1. Add language runtimes to packages/mise/.config/mise/config.toml
2. Test each language runtime (node, ruby, go, rust, zig, java, etc.)
3. Verify .tool-versions compatibility (mise can read asdf files)
4. Update CI/CD if applicable
5. Update documentation (AGENTS.md, platform instructions)
6. Remove asdf from system packages (Brewfile, pacman packages.txt)
7. Remove packages/tool-versions/.tool-versions

## Considerations

- asdf is currently working on macOS
- Migration effort is medium (test all language runtimes)
- Can be done incrementally, one language at a time
- mise reads .tool-versions files, so migration is low-risk

## Testing Checklist

- [ ] Node.js (23.10.0)
- [ ] Ruby (3.3.5)
- [ ] Go (1.26.2)
- [ ] Rust (1.95.0)
- [ ] Zig (0.16.0)
- [ ] Java (openjdk-17)
- [ ] Deno (2.7.13)
- [ ] Bun (1.3.13)

## References

- [mise vs asdf comparison](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [Spec document](/home/michaelyocca/.opencode/plan/spec_unified_package_management.md)

## Current State

- **Status**: Phase 3 (deferred)
- **Phase 1**: ✅ Complete - mise for dev tools
- **Phase 2**: ⏳ Migrate Stow to mise (see related issue)
- **Phase 3**: ⏳ Migrate asdf to mise (this issue)
