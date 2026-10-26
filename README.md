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
# Prerequisites: git, stow
sudo pacman -S git stow

git clone https://github.com/mjyocca/dotfiles.git ~/dotfiles
cd ~/dotfiles
make dotfiles  # Auto-detects Omarchy profile
```

The `make dotfiles` command stows packages based on your OS profile (macOS or Omarchy).
Override with `PROFILE=<name>` if needed.