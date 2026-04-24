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
3. Relinks `/var/run/docker.sock` → `~/.colima/<profile>/docker.sock`

**Requires `sudo`** for the socket relink step.

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
# Migrate all volumes from default → arm profile (auto-mode)
dotf colima-migrate-volumes default arm

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

## Manual context switching (no scripts)

```bash
docker context ls                  # list contexts, active one has *
docker context use colima          # switch to default colima profile
docker context use colima-arm      # switch to arm colima profile
docker context show                # print active context name
```

Re-link the socket manually after switching:

```bash
sudo ln -sf ~/.colima/<profile>/docker.sock /var/run/docker.sock

# e.g.
sudo ln -sf ~/.colima/default/docker.sock /var/run/docker.sock
sudo ln -sf ~/.colima/arm/docker.sock     /var/run/docker.sock
```

Verify which socket is active:

```bash
ls -la /var/run/docker.sock
```

---

## Using external volumes in docker-compose

When a volume was created outside of Compose (e.g. migrated manually), declare
it as `external` so Compose won't attempt to create or delete it:

```yaml
services:
  myapp:
    image: myapp
    volumes:
      - my_volume:/app/data

volumes:
  my_volume:
    external: true
```

If the on-disk name differs from the Compose name:

```yaml
volumes:
  my_volume:
    external: true
    name: the_actual_volume_name_on_docker
```

---

## Troubleshooting

**`Cannot connect to the Docker daemon` after switching**

The socket is likely still pointing to the previous engine. Run:

```bash
dotf colima-use <profile>
```

or relink manually:

```bash
sudo ln -sf ~/.colima/<profile>/docker.sock /var/run/docker.sock
```

**Check socket target**

```bash
ls -la /var/run/docker.sock
```

**Pass `--context` directly (bypass socket entirely)**

```bash
docker --context colima volume ls
docker --context colima-arm ps
```
