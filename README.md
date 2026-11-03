```
    ____        __  _______ __         
   / __ \____  / /_/ ____(_) /__  _____
  / / / / __ \/ __/ /_  / / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / / /  __(__  ) 
/_____/\____/\__/_/   /_/_/\___/____/                     
```

## Installing

**macOS**
```bash
curl -sO https://raw.githubusercontent.com/mjyocca/dotfiles/main/scripts/macos/installer.sh
bash installer.sh
```

**Omarchy (Linux)**
```bash
# Prerequisites: git
sudo pacman -S git

git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make bootstrap  # Auto-detects Omarchy profile
```

The `make bootstrap` command sets up everything. For incremental updates:
- `make pack` - Install system packages
- `make link` - Deploy dotfiles via mise
- `make plug` - Install plugins
- `make sync` - All of the above