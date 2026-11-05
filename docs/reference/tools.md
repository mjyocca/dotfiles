# Tooling Reference

Human-facing discovery links, not a package inventory or installation policy.
Consult upstream for features, compatibility, licensing, and commands; tracked
declarations determine what this repository actually installs.

When freshness matters, check upstream content's **Last updated** date or source
history and compare it with the installed version. HTTP `Last-Modified` may reflect
a site deployment, not a content change; an absent date is not evidence of staleness.

## Agent Guidance

- [Agent guidance](agent-guidance.md) — official OpenCode V2, OpenAI, and Anthropic sources with review dates
- [agent-desktop](https://github.com/vercel-labs/agent-desktop) — platform-specific automation guidance

## Terminal and Development

- [Ghostty docs](https://ghostty.org/docs) · [source](https://github.com/ghostty-org/ghostty)
- [Rex docs](https://www.superlogical.com/rex/docs) · [repository configuration](rex.md)
- [OpenCode V2 docs](https://opencode.ai/v2/docs/) — configuration and agent tooling
- [lazygit](https://github.com/jesseduffield/lazygit) — Git UI
- [lazydocker](https://github.com/jesseduffield/lazydocker) — container UI
- [gh-dash](https://github.com/dlvhdr/gh-dash) — GitHub dashboard
- [yazi docs](https://yazi-rs.github.io/docs/installation/) · [source](https://github.com/sxyazi/yazi)
- [superfile docs](https://superfile.dev/) · [source](https://github.com/yorukot/superfile)
- [television docs](https://alexpasmantier.github.io/television/) · [source](https://github.com/alexpasmantier/television)
- [btop](https://github.com/aristocratos/btop) — resource monitor
- [glow](https://github.com/charmbracelet/glow) — terminal Markdown
- [Zellij docs](https://zellij.dev/documentation/) · [Tmux wiki](https://github.com/tmux/tmux/wiki)

## Configuration Managers

- [mise configuration](https://mise.jdx.dev/configuration.html) · [dotfiles](https://mise.jdx.dev/dotfiles.html)
- [asdf configuration](https://asdf-vm.com/manage/configuration.html)
- [Omarchy manual](https://omarchy.org/manual/)

For this repository's file layout and scope, see [mise architecture](../architecture/mise.md).

## Containers and Virtual Machines

- [Colima](https://github.com/abiosoft/colima) · [Lima docs](https://lima-vm.io/docs/) · [Lima source](https://github.com/lima-vm/lima)
- [OrbStack Docker](https://docs.orbstack.dev/docker/) · [Linux machines](https://docs.orbstack.dev/machines/)
- [Docker Desktop](https://docs.docker.com/desktop/)
- [Podman](https://podman.io/docs/installation) · [Podman Desktop](https://podman-desktop.io/)
- [containerd](https://containerd.io/docs/)
- [QEMU docs](https://www.qemu.org/docs/master/) · [wiki](https://wiki.qemu.org/)
- [UTM docs](https://docs.getutm.app/) · [source](https://github.com/utmapp/UTM)

See [dotf](dotf.md) for repository helper commands.

## Infrastructure

- Container sandboxing: [gVisor](https://gvisor.dev/docs/)
- MicroVMs: [Firecracker](https://firecracker-microvm.github.io/) · [source](https://github.com/firecracker-microvm/firecracker)
- VM initialization: [cloud-init](https://docs.cloud-init.io/en/latest/)
- Workload orchestration: [Kubernetes](https://kubernetes.io/docs/home/) · [Nomad](https://developer.hashicorp.com/nomad/docs)
- Durable workflows: [Temporal](https://docs.temporal.io/) · [Cadence](https://cadenceworkflow.io/docs/get-started)
- Network access: [Tailscale](https://tailscale.com/docs) · [Twingate](https://www.twingate.com/docs)
- Service discovery/mesh: [Consul](https://developer.hashicorp.com/consul/docs)
- Secrets management: [Vault](https://developer.hashicorp.com/vault/docs)
