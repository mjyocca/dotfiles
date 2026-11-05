# Container / Volume Migration

Scripts for switching between colima profiles and migrating docker volumes.

---

## Colima Profile Management (`dotf` commands)

These are accessed via the `dotf` dispatcher (`~/.local/bin/dotf`).

### List profiles

```bash
dotf colima-list
```

Shows every colima profile under `~/.colima/`, its run state, mapped docker
context, and socket path. Marks the currently active context with `*`.

### Switch active profile

```bash
dotf colima-use <profile>
```

1. Starts the colima VM if it is not already running
2. Switches the active docker context (`docker context use colima[-<profile>]`)
3. Relinks `/var/run/docker.sock` to the selected profile's socket

**Requires `sudo`** for the socket relink step.

The switching helper uses `$XDG_CONFIG_HOME/colima/<profile>/docker.sock` when
`XDG_CONFIG_HOME` is set, otherwise `~/.colima/<profile>/docker.sock`. Verify that
this matches the actual Docker context endpoint before switching; the listing
helper currently inspects only `~/.colima`.

```bash
dotf colima-use default   # context: colima
dotf colima-use arm       # context: colima-arm
dotf colima-use k8s       # context: colima-k8s
```

#### Profile → context name mapping

| Profile name | Docker context |
|---|---|
| `default` | `colima` |
| `<name>` | `colima-<name>` |

### Migrate volumes between profiles

```bash
dotf colima-migrate-volumes <src-profile> <dst-profile> [--all | --select]
```

Exports every selected volume from the source colima context and imports it
into the destination context. Archives are written to a temp directory and
deleted on exit.

| Flag | Behaviour |
|---|---|
| `--select` | Opens fzf picker (TAB to multi-select). Default when fzf is installed. |
| `--all` | Migrates all volumes without prompting. Default when fzf is absent. |

```bash
# Interactively choose which volumes to move
dotf colima-migrate-volumes default arm --select

# Non-interactive: move everything
dotf colima-migrate-volumes default arm --all
```

The destination profile is started automatically if it is not running.
Volumes that already exist in the destination are skipped.

---

## Low-level scripts

### `export_volume.sh`

Exports a single named volume to a `.tar.gz` in the current directory.

```bash
./export_volume.sh <volume_name> [--context <docker_context>]

./export_volume.sh my_volume                       # active context
./export_volume.sh my_volume --context colima      # explicit context
./export_volume.sh my_volume --context colima-arm
```

### `import_volume.sh`

Creates a volume and populates it from a `.tar.gz` in the current directory.

```bash
./import_volume.sh <volume_name> [--context <docker_context>]

./import_volume.sh my_volume
./import_volume.sh my_volume --context colima-arm
```

The archive `<volume_name>.tar.gz` must already exist in the current directory.

---

## Troubleshooting

If Docker cannot connect after switching, inspect the active context and socket
before changing links. Other Docker runtimes may manage `/var/run/docker.sock`.

```bash
docker context show
docker context inspect colima
ls -la /var/run/docker.sock
```

Pass `--context` explicitly to avoid depending on the shared socket link:

```bash
docker --context colima volume ls
docker --context colima-arm ps
```

## Upstream Guidance

- [Colima](https://github.com/abiosoft/colima) — profile configuration and lifecycle
- [Docker contexts](https://docs.docker.com/engine/manage-resources/contexts/) — endpoints and context selection
- [Compose external volumes](https://docs.docker.com/reference/compose-file/volumes/#external) — reusing migrated volumes
