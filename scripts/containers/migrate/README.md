# Switching Docker Contexts and Migrating Volumes

## Quick Reference

| Action | Command |
|--------|---------|
| Switch to Colima profile + relink socket | `scripts/containers/colima/profile.sh switch <profile>` |
| Start Colima profile + activate it | `scripts/containers/colima/profile.sh start <profile>` |
| Check active Docker context | `docker context show` |

---

## Colima Profile Helpers

Use the profile helper script to quickly switch context and relink `/var/run/docker.sock`.

### Start and activate a profile
```bash
scripts/containers/colima/profile.sh start exp-vz --cpu 2 --memory 4
```

### Switch to an existing profile
```bash
scripts/containers/colima/profile.sh switch exp-vz
```

### Switch context only (skip socket symlink)
```bash
scripts/containers/colima/profile.sh switch exp-vz --skip-socket-link
```

### List profiles
```bash
scripts/containers/colima/profile.sh ls
```

### Stop/delete profile
```bash
scripts/containers/colima/profile.sh stop exp-vz
scripts/containers/colima/profile.sh delete exp-vz
```

---

## Manual Context Switching

### → OrbStack
```bash
docker context use orbstack
```

### → Docker Desktop
```bash
docker context use desktop-linux
```

### Verify active context
```bash
docker context ls
```
The active context will have a `*` next to it.

---

## Migrating Volumes

Use the scripts below to move volumes between contexts (including Colima profiles).

### export_volume.sh
```bash
scripts/containers/migrate/export_volume.sh <volume_name> [context] [output_dir]
```

### import_volume.sh
```bash
scripts/containers/migrate/import_volume.sh <volume_name> [context] [archive_dir] [target_volume_name]
```

### transfer_volume.sh (export + import)
```bash
scripts/containers/migrate/transfer_volume.sh <volume_name> <source_context> <target_context> [archive_dir] [target_volume_name]
```

### Usage
```bash
chmod +x export_volume.sh import_volume.sh

# Copy from default Colima profile to experimental profile
scripts/containers/migrate/transfer_volume.sh my_volume colima colima-exp

# Export from current context into ./backups
scripts/containers/migrate/export_volume.sh my_volume "$(docker context show)" ./backups

# Import into a different target volume name
scripts/containers/migrate/import_volume.sh my_volume colima-exp ./backups my_volume_clone
```

---

## Using External Volumes in docker-compose

If a volume was created outside of Compose (e.g. migrated manually), declare it
as `external` so Compose won't try to create or delete it:

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

If the volume name on disk differs from the name used inside the Compose file:

```yaml
volumes:
  my_volume:
    external: true
    name: the_actual_volume_name_on_docker
```

---

## Troubleshooting

**`/var/run/docker.sock` errors after switching**

The socket may still be symlinked to the previous engine. Re-link manually:

```bash
sudo ln -sf ~/.colima/<profile>/docker.sock /var/run/docker.sock
```

or use:

```bash
scripts/containers/colima/profile.sh switch <profile>
```

Alternatively, bypass the socket entirely by passing `--context` explicitly:

```bash
docker --context desktop-linux volume ls
docker --context orbstack ps
```

**Check which socket is active**
```bash
ls -la /var/run/docker.sock
```
