# Switching Between OrbStack and Docker Desktop

## Quick Reference

| Action | Command |
|--------|---------|
| Switch to OrbStack | `docker context use orbstack` |
| Switch to Docker Desktop | `docker context use desktop-linux` |
| Check current context | `docker context ls` |

---

## Switching Contexts

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

Use the scripts below to move volumes between engines. Both scripts assume the
`.tar.gz` archive lives in the current working directory.

### export_volume.sh — run while on OrbStack context
```bash
#!/bin/bash
set -e

VOLUME_NAME="${1:?Usage: $0 <volume_name>}"
DOCKER="docker --context orbstack"

echo "Exporting '$VOLUME_NAME'..."
$DOCKER run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(pwd):/backup" \
  alpine tar czf "/backup/${VOLUME_NAME}.tar.gz" -C /data .

echo "Done: $(pwd)/${VOLUME_NAME}.tar.gz"
```

### import_volume.sh — run while on Docker Desktop context
```bash
#!/bin/bash
set -e

VOLUME_NAME="${1:?Usage: $0 <volume_name>}"
DOCKER="docker --context desktop-linux"
ARCHIVE="$(pwd)/${VOLUME_NAME}.tar.gz"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Error: $ARCHIVE not found"
  exit 1
fi

echo "Creating volume '$VOLUME_NAME'..."
$DOCKER volume create "${VOLUME_NAME}"

echo "Importing from $ARCHIVE..."
$DOCKER run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(pwd):/backup" \
  alpine tar xzf "/backup/${VOLUME_NAME}.tar.gz" -C /data

echo "Done."
```

### Usage
```bash
chmod +x export_volume.sh import_volume.sh

./export_volume.sh my_volume   # exports my_volume.tar.gz to current dir
./import_volume.sh my_volume   # creates volume and imports data
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

The socket may still be symlinked to the previous engine. Fix it by restarting
Docker Desktop, or re-link manually:

```bash
sudo ln -sf /Users/$USER/Library/Containers/com.docker.docker/Data/docker.raw.sock /var/run/docker.sock
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
