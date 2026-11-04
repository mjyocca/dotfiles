```
    ____        __  _______ __         
   / __ \____  / /_/ ____(_) /__  _____
  / / / / __ \/ __/ /_  / / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / / /  __(__  ) 
/_____/\____/\__/_/   /_/_/\___/____/                     
```

Personal dotfiles managed with [mise](https://mise.jdx.dev/dotfiles/) and
platform-specific bootstrap scripts.

## Install

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/mjyocca/dotfiles/main/scripts/macos/installer.sh -o installer.sh
bash installer.sh
```

If prompted to install Xcode Command Line Tools, finish installation and rerun.

### Omarchy

```bash
sudo pacman -S --needed git make
git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap
```

`make bootstrap` detects the platform and runs setup. For incremental updates:

- `make pack` — Install system packages and deploy selected dotfiles
- `make link` — Deploy dotfiles via mise
- `make plug` — Install plugins
- `make sync` — Run packages, link, and plugins
