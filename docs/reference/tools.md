# Tooling Reference

A quick reference for tools by category — alternatives, trade-offs, and links to docs.

---

## Table of Contents

### Local Development
- [Terminal Emulators](#terminal-emulators)
- [TUI Tools](#tui-tools)
- [Container Runtimes](#container-runtimes)
- [Virtual Machines](#virtual-machines)

### DevOps & Infrastructure
- [Container Security / MicroVMs](#container-security--microvms)
- [VM Provisioning](#vm-provisioning)
- [Orchestration](#orchestration)
- [Workflow Orchestration](#workflow-orchestration)
- [Networking / Zero Trust](#networking--zero-trust)
- [Service Mesh & Discovery](#service-mesh--discovery)
- [Secrets Management](#secrets-management)

---

# Local Development

## Terminal Emulators

### Ghostty *(preferred)*
Fast, native terminal emulator written in Zig by Mitchell Hashimoto. Prioritizes performance and platform-native feel — uses Metal on macOS. Supports GPU acceleration, true color, ligatures, and a rich configuration format. First-class macOS citizen with a split pane UI and good defaults out of the box.

- [Docs](https://ghostty.org/docs)
- [GitHub](https://github.com/ghostty-org/ghostty)

---

## TUI Tools

Terminal User Interface applications — keyboard-driven, terminal-native tools that replace or augment GUI workflows.

### OpenCode
AI coding agent for the terminal. Integrates with LLMs to assist with code generation, refactoring, and codebase exploration directly from the CLI. Configurable via `~/.config/opencode/`.

- [Docs](https://opencode.ai/docs)
- [GitHub](https://github.com/sst/opencode)

### lazygit
Full-featured terminal UI for Git. Navigate branches, stage hunks, resolve conflicts, interactive rebase, and cherry-pick — all without memorizing flags. Highly configurable and broadly considered the best Git TUI available.

- [Docs](https://lazygit.dev/docs/)
- [GitHub](https://github.com/jesseduffield/lazygit)

### lazydocker
Terminal UI for Docker and Docker Compose. Visualizes containers, images, volumes, and logs in one view. Supports starting, stopping, and removing resources without leaving the terminal.

- [GitHub](https://github.com/jesseduffield/lazydocker)

### gh-dash
TUI dashboard for GitHub built on the `gh` CLI. Displays pull requests and issues across repos in a customizable, keyboard-driven interface. Configured via a YAML file to define sections and filters.

- [GitHub](https://github.com/dlvhdr/gh-dash)

### yazi
Blazing-fast terminal file manager written in Rust. Full async I/O, image previews (via Kitty/iTerm protocol), syntax-highlighted file previews, bulk rename, and a plugin system. Highly configurable via TOML and Lua.

- [Docs](https://yazi-rs.github.io/docs/)
- [GitHub](https://github.com/sxyazi/yazi)

### superfile *(in use)*
Modern, visually polished terminal file manager written in Go. Multi-panel layout with icons, themes, and plugin support. Dotfile config lives at `packages/superfile/` and is stowed to `~/.config/superfile/` via `XDG_CONFIG_HOME`. Press `E` to open the current directory in `$EDITOR` (nvim), `.` to toggle dotfile visibility.

- [Docs](https://superfile.dev/)
- [GitHub](https://github.com/yorukot/superfile)

### television
Fast, portable fuzzy finder for the terminal written in Rust. Searches through any kind of data in real-time via a channel-based architecture — built-in channels for files, git repos, environment variables, shell history, and more. Channels are composable and fully customizable via TOML. Designed as a general-purpose `fzf` alternative with richer defaults and a built-in preview system.

- [Docs](https://alexpasmantier.github.io/television/)
- [GitHub](https://github.com/alexpasmantier/television)

### btop
Beautifully designed resource monitor for CPU, memory, disk, network, and processes. Successor to bashtop and bpytop, rewritten in C++ for performance. Mouse support, customizable themes, and sorting. Drop-in replacement for `htop`/`top` with far better visuals.

- [GitHub](https://github.com/aristocratos/btop)

### glow
Markdown renderer for the terminal from Charmbracelet. Renders `.md` files with styling in the terminal, and includes a TUI mode for browsing a local collection of markdown files. Useful for reading docs, READMEs, and notes without leaving the shell.

- [GitHub](https://github.com/charmbracelet/glow)

---

## Container Runtimes

### Colima + Lima *(preferred)*
Colima is the primary container runtime. It uses [Lima](https://lima-vm.io) as the underlying VM layer to run a Linux guest on macOS. Lima supports multiple backends — Apple's Virtualization.framework (`vz`), QEMU, and others — with `vz` used here for near-native performance on Apple Silicon. Docker runs inside that VM — `colima start` provisions the VM, registers a Docker context, and exposes a socket at `~/.colima/<profile>/docker.sock`.

Multiple named profiles are supported, each with its own VM config, resources, and Docker context. Profile switching is automated via `dotf colima-use <profile>`.

- [Colima docs](https://github.com/abiosoft/colima)
- [Lima docs](https://lima-vm.io/docs/)

### OrbStack
Fast, lightweight Docker runtime for macOS. Drop-in replacement for Docker Desktop with significantly lower resource usage. Includes a built-in GUI, Docker Compose support, and seamless macOS integration. Also doubles as a Linux VM manager.

- [Docs](https://docs.orbstack.dev/docker/)

### Docker Desktop
The official Docker GUI and runtime for macOS. Feature-rich with built-in Kubernetes, Dev Environments, and Docker Scout. Requires a paid subscription for commercial use in larger orgs (>250 employees or >$10M revenue).

- [Docs](https://docs.docker.com/desktop/)

### Podman
Daemonless, rootless container engine compatible with the Docker CLI. No licensing restrictions. Pairs with Podman Desktop for a GUI experience. Good alternative when Docker licensing is a concern.

- [Docs](https://podman.io/docs/installation)
- [Podman Desktop](https://podman-desktop.io/)

### containerd
Industry-standard container runtime used as the underlying engine by Docker, Kubernetes, and others. Manages the full container lifecycle — image transfer, storage, execution, networking. Rarely used directly; more commonly a component within a larger stack.

- [Docs](https://containerd.io/docs/)

---

## Virtual Machines

### Lima *(preferred — via Colima)*
Linux VM manager for macOS with automatic file sharing and port forwarding. Supports multiple VM backends including Apple's Virtualization.framework (`vz`), QEMU, and others — `vz` is used here for near-native performance on Apple Silicon. Colima is built on top of Lima and is the primary interface used here — Lima provides the VM layer, Colima handles profile management and Docker context wiring.

- [Docs](https://lima-vm.io/docs/)
- [GitHub](https://github.com/lima-vm/lima)

### Colima (VM mode)
Beyond containers, Colima can provision VMs for running Kubernetes clusters or isolated Linux environments. Each named profile is its own Lima-backed VM. Managed via `dotf colima-use`, `dotf colima-list`, and `dotf colima-migrate-volumes`.

- [Docs](https://github.com/abiosoft/colima)

### OrbStack Linux Machines
Lightweight Linux VMs integrated into OrbStack. WSL2-like experience on macOS with automatic file sharing and port forwarding. Fast to spin up, low overhead, managed via CLI or GUI.

- [Docs](https://docs.orbstack.dev/machines/)

- [Docs](https://colima.run/docs/)

### QEMU
Open-source machine emulator and virtualizer. Full hardware emulation — can run virtually any OS and architecture. Low-level and highly configurable but requires more manual setup. Used as a backend by Lima and others.

- [Docs](https://www.qemu.org/docs/master/)
- [Wiki](https://wiki.qemu.org/)

### UTM
GUI-first VM app for macOS and iOS built on QEMU. Operates in two distinct modes: **virtualization** (uses Apple's Hypervisor framework for near-native speed when the guest architecture matches the host) and **emulation** (full QEMU emulation for foreign architectures, e.g. running x86 on Apple Silicon). The only tool in this list that runs on iPhone and iPad. Best choice when you want a polished, point-and-click VM experience rather than a CLI-driven workflow.

- [Docs](https://docs.getutm.app/)
- [GitHub](https://github.com/utmapp/UTM)

---

# DevOps & Infrastructure

## Container Security / MicroVMs

Tools in this category add isolation beyond standard containers — either by sandboxing syscalls in userspace (gVisor) or by running each workload inside a dedicated lightweight VM (Firecracker). Both approaches harden multi-tenant environments where container escape is a concern.

### gVisor
Application-level kernel sandbox from Google that intercepts and handles container syscalls in userspace, isolating containers from the host kernel. Acts as an OCI-compatible runtime (`runsc`). Adds a strong security boundary at the cost of some performance overhead. Integrates with Docker and containerd.

- [Docs](https://gvisor.dev/docs/)

### Firecracker
MicroVM technology from AWS, purpose-built for serverless and container workloads. Boots a minimal KVM-based VM in milliseconds with a tiny memory footprint (~5MB overhead per VM). Each workload gets full VM-level isolation without the startup cost of traditional VMs. Powers AWS Lambda and Fargate under the hood. Linux host only — not directly usable on macOS without a VM layer.

- [Docs](https://firecracker-microvm.github.io/)
- [GitHub](https://github.com/firecracker-microvm/firecracker)

---

## VM Provisioning

### cloud-init
The industry-standard tool for initializing cloud instances on first boot. Reads user-data (YAML) to configure users, SSH keys, packages, files, and run commands. Supported by all major cloud providers and most VM tools (Lima, QEMU, etc.).

- [Docs](https://docs.cloud-init.io/en/latest/)

---

## Orchestration

### Kubernetes
Open-source container orchestration platform from CNCF. Automates deployment, scaling, and management of containerized workloads across clusters. The de-facto standard for production container orchestration. High operational complexity; most appropriate at scale.

- [Docs](https://kubernetes.io/docs/home/)

### Nomad
Lightweight, flexible workload orchestrator from HashiCorp. Schedules containers, binaries, JVM apps, and batch jobs — not containers-only like Kubernetes. Simpler operational model; integrates natively with Consul and Vault. Good choice when Kubernetes feels like overkill.

- [Docs](https://developer.hashicorp.com/nomad/docs)

---

## Workflow Orchestration

Distinct from infrastructure orchestration — these tools manage long-running, stateful application workflows with durability guarantees. Code executes as if failures never happened; state is persisted automatically.

### Temporal
Open-source durable execution platform. Workflows are written as regular code (Go, Java, TypeScript, Python, etc.) and survive process crashes, network failures, and server restarts — execution resumes exactly where it left off. Spun out of Uber's Cadence project. The more actively developed and widely adopted of the two.

- [Docs](https://docs.temporal.io/)

### Cadence
Uber's original fault-oblivious workflow engine, open-sourced in 2017. Same core model as Temporal — stateful workflows as code with automatic state persistence. Temporal is a fork of Cadence; the two share concepts but have diverged. Still maintained at Uber scale; consider Temporal for greenfield work.

- [Docs](https://cadenceworkflow.io/docs/get-started)

---

## Networking / Zero Trust

### Tailscale
Zero Trust mesh VPN built on WireGuard. Each device gets a stable IP within a private tailnet; connections are peer-to-peer where possible, relayed via DERP servers otherwise. Identity-based access control via your existing SSO provider. Supports subnet routers (expose entire networks), exit nodes (route all traffic), and MagicDNS. Free tier is generous; good fit for homelabs and small teams.

- [Docs](https://tailscale.com/docs)

### Twingate
Zero Trust Network Access (ZTNA) alternative to VPNs. Resource-level access control rather than network-level — users only reach the specific services they're authorized for, never the broader network. Connector-based architecture; no open inbound firewall ports required. More access-policy-focused than Tailscale; better fit for teams needing fine-grained resource gating.

- [Docs](https://www.twingate.com/docs)

---

## Service Mesh & Discovery

### Consul
HashiCorp's service discovery and service mesh tool. Provides a distributed key/value store, health checking, and mTLS-based service mesh via Envoy proxies. Integrates tightly with Nomad and Vault. Can run independently of the rest of the HashiCorp stack.

- [Docs](https://developer.hashicorp.com/consul/docs)

---

## Secrets Management

### Vault
HashiCorp's secrets management platform. Centralizes storage and access control for secrets, API keys, certificates, and dynamic credentials. Supports a wide range of secrets engines (AWS, databases, PKI, KV) and auth methods. Essential for production secrets hygiene.

- [Docs](https://developer.hashicorp.com/vault/docs)
