# Tooling Reference

Human-facing discovery links, not a package inventory or installation policy.
Consult upstream for features, compatibility, licensing, and commands; tracked
declarations determine what this repository actually installs.

## Local Preferences

- **Ghostty** is the preferred terminal; configuration lives in `packages/ghostty/`.
- **superfile** is in use, with configuration in `packages/superfile/`. Deployment
  uses the repository's mise entrypoint, not Stow; effective deployment wiring
  must be checked before assuming files are linked.
- **Colima + Lima** is the preferred Docker/VM stack on macOS. The template in
  `packages/colima/.config/colima/_templates/default.yaml` selects `vz` and
  `virtiofs`; existing profiles may differ. Do not assume helper commands exist:
  inspect `packages/scripts/.local/bin/dotf.d/` for the current `dotf` command set.

## Terminal and Development

- [Ghostty docs](https://ghostty.org/docs) · [source](https://github.com/ghostty-org/ghostty)
- [OpenCode V2 docs](https://opencode.ai/v2/docs/) — configuration and agent tooling
- [lazygit](https://github.com/jesseduffield/lazygit) — Git UI
- [lazydocker](https://github.com/jesseduffield/lazydocker) — container UI
- [gh-dash](https://github.com/dlvhdr/gh-dash) — GitHub dashboard
- [yazi docs](https://yazi-rs.github.io/docs/installation) · [source](https://github.com/sxyazi/yazi)
- [superfile docs](https://superfile.dev/) · [source](https://github.com/yorukot/superfile)
- [television docs](https://alexpasmantier.github.io/television/) · [source](https://github.com/alexpasmantier/television)
- [btop](https://github.com/aristocratos/btop) — resource monitor
- [glow](https://github.com/charmbracelet/glow) — terminal Markdown

## Containers and Virtual Machines

- [Colima](https://github.com/abiosoft/colima) · [Lima docs](https://lima-vm.io/docs/) · [Lima source](https://github.com/lima-vm/lima)
- [OrbStack Docker](https://docs.orbstack.dev/docker/) · [Linux machines](https://docs.orbstack.dev/machines/)
- [Docker Desktop](https://docs.docker.com/desktop/)
- [Podman](https://podman.io/docs/installation) · [Podman Desktop](https://podman-desktop.io/)
- [containerd](https://containerd.io/docs/)
- [QEMU docs](https://www.qemu.org/docs/master/) · [wiki](https://wiki.qemu.org/)
- [UTM docs](https://docs.getutm.app/) · [source](https://github.com/utmapp/UTM)

## Infrastructure

- Container sandboxing: [gVisor](https://gvisor.dev/docs/)
- MicroVMs: [Firecracker](https://firecracker-microvm.github.io/) · [source](https://github.com/firecracker-microvm/firecracker)
- VM initialization: [cloud-init](https://docs.cloud-init.io/en/latest/)
- Workload orchestration: [Kubernetes](https://kubernetes.io/docs/home/) · [Nomad](https://developer.hashicorp.com/nomad/docs)
- Durable workflows: [Temporal](https://docs.temporal.io/) · [Cadence](https://cadenceworkflow.io/docs/get-started)
- Network access: [Tailscale](https://tailscale.com/docs) · [Twingate](https://www.twingate.com/docs)
- Service discovery/mesh: [Consul](https://developer.hashicorp.com/consul/docs)
- Secrets management: [Vault](https://developer.hashicorp.com/vault/docs)
