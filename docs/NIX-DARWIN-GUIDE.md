# nix-darwin Guide

This comprehensive guide covers using nix-darwin for native macOS system management with Nix and Home Manager integration.

## Table of Contents

1. [Overview](#overview)
1. [Installation](#installation)
1. [Configurations](#configurations)
1. [Usage](#usage)
1. [Customization](#customization)
1. [Management](#management)
1. [Troubleshooting](#troubleshooting)
1. [Advanced Usage](#advanced-usage)

## Overview

nix-darwin brings the power of NixOS to macOS, allowing you to:

- **Declaratively configure** your entire macOS system
- **Manage packages** with Nix instead of Homebrew alone
- **Integrate Home Manager** for user-specific configurations
- **Version control** your system configuration
- **Reproduce environments** across different Macs
- **Rollback changes** easily if something goes wrong

### Key Features

**System Management:**

- macOS system preferences and defaults
- Package management with Nix
- Homebrew integration for GUI apps
- Service management

**Development Environment:**

- Consistent development tools across machines
- Project-specific environments with direnv
- Shell configuration with Zsh/Fish
- Editor and terminal setup

**Security & Privacy:**

- Declarative security settings
- Touch ID integration
- Certificate management
- Privacy controls

## Installation

### Prerequisites

**System Requirements:**

- macOS 11.0 (Big Sur) or later
- Admin user account
- Command Line Tools for Xcode

**Install Nix:**

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Quick Installation

Use the interactive installation script:

```bash
# Clone the template
git clone https://github.com/yourusername/nixos-template
cd nixos-template

# Run the installer
./scripts/install-nix-darwin.sh
```

The installer will:

1. Detect your Mac's architecture (Apple Silicon/Intel)
1. Let you choose a configuration (Desktop/Laptop/Server)
1. Install nix-darwin with the selected configuration
1. Set up shell integration and management tools

### Manual Installation

For more control over the installation process:

1. **Clone the template:**

   ```bash
   git clone https://github.com/yourusername/nixos-template ~/.config/nix-darwin
   cd ~/.config/nix-darwin
   ```

1. **Install nix-darwin:**

   ```bash
   # For Apple Silicon Macs
   nix run nix-darwin -- switch --flake .#darwin-desktop

   # For Intel Macs
   nix run nix-darwin -- switch --flake .#darwin-desktop-intel
   ```

1. **Set up shell integration:**

   ```bash
   echo 'if [ -e /run/current-system/sw/bin ]; then' >> ~/.zprofile
   echo '  export PATH="/run/current-system/sw/bin:$PATH"' >> ~/.zprofile
   echo 'fi' >> ~/.zprofile
   ```

## Configurations

### Available Configurations

#### Desktop Configuration

**Purpose:** Full-featured desktop environment for development and daily use

**Features:**

- Complete development environment (Node.js, Python, Go, Rust)
- GUI applications via Homebrew
- Visual Studio Code and JetBrains tools
- Docker and container support
- Media and productivity tools

**Best for:** Primary development machines, workstations, iMacs

#### Laptop Configuration

**Purpose:** Mobile-optimized for MacBook users

**Features:**

- Battery-optimized settings
- Power management utilities
- Lightweight development tools
- Mobile-friendly applications
- Network management tools

**Best for:** MacBooks, mobile development, travel setups

#### Server Configuration

**Purpose:** Headless development server setup

**Features:**

- Server development tools
- Database servers (PostgreSQL, Redis, MongoDB)
- Container orchestration
- Monitoring and logging tools
- Minimal GUI applications

**Best for:** Development servers, CI/CD machines, headless setups

### Architecture Support

**Apple Silicon (M1/M2/M3):**

- `darwin-desktop` - Desktop configuration
- `darwin-laptop` - Laptop configuration
- `darwin-server` - Server configuration

**Intel Macs:**

- `darwin-desktop-intel` - Desktop configuration
- `darwin-laptop-intel` - Laptop configuration
- `darwin-server-intel` - Server configuration

## Usage

### Basic Commands

**System Management:**

```bash
# Apply configuration changes
darwin-rebuild switch --flake ~/.config/nix-darwin

# List system generations
darwin-rebuild --list-generations

# Rollback to previous generation
darwin-rebuild --rollback

# Update flake inputs
nix flake update ~/.config/nix-darwin
```

**System Information:**

```bash
# Show system information
darwin-info

# Show current configuration
darwin-rebuild --show-trace
```

**Maintenance:**

```bash
# Update system and flake
darwin-update

# Clean up old generations
nix-collect-garbage -d

# Optimize Nix store
nix store optimise
```

### Home Manager Integration

Home Manager is integrated automatically and manages:

- User-specific packages
- Dotfiles and configuration files
- Shell configuration
- Development environments

**Home Manager Commands:**

```bash
# Switch Home Manager configuration
home-manager switch --flake ~/.config/nix-darwin

# List Home Manager generations
home-manager generations

# Edit Home Manager configuration
code ~/.config/nix-darwin/hosts/darwin-desktop/home.nix
```

### Homebrew Integration

Homebrew is managed declaratively through nix-darwin:

```nix
# In configuration.nix
homebrew = {
  enable = true;

  # Command-line tools
  brews = [
    "ffmpeg"
    "youtube-dl"
  ];

  # GUI applications
  casks = [
    "visual-studio-code"
    "docker"
    "firefox"
  ];

  # Mac App Store apps
  masApps = {
    "Xcode" = 497799835;
    "TestFlight" = 899247664;
  };
};
```

## Customization

### System Preferences

Configure macOS system preferences declaratively:

```nix
system.defaults = {
  # Dock settings
  dock = {
    autohide = true;
    tilesize = 48;
    show-recents = false;
  };

  # Finder settings
  finder = {
    AppleShowAllExtensions = true;
    ShowPathbar = true;
  };

  # Global settings
  NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    KeyRepeat = 2;
    InitialKeyRepeat = 15;
  };
};
```

### Adding Packages

**System-wide packages** (in `configuration.nix`):

```nix
environment.systemPackages = with pkgs; [
  git
  vim
  curl
  nodejs_20
];
```

**User packages** (in `home.nix`):

```nix
home.packages = with pkgs; [
  vscode
  firefox
  htop
];
```

### Shell Configuration

Configure your shell in Home Manager:

```nix
programs.zsh = {
  enable = true;
  enableCompletion = true;

  shellAliases = {
    ll = "ls -la";
    grep = "grep --color=auto";
  };

  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "docker" "node" ];
  };
};
```

### Development Environment

Set up development tools:

```nix
# Languages and runtimes
home.packages = with pkgs; [
  nodejs_20
  python311
  go
  rustc
];

# Git configuration
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "your.email@example.com";

  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
  };
};
```

## Management

### Configuration Structure

```
~/.config/nix-darwin/
├── flake.nix                    # Main flake configuration
├── darwin/
│   ├── default.nix             # Base nix-darwin config
│   ├── system.nix              # macOS system settings
│   ├── homebrew.nix            # Homebrew integration
│   ├── networking.nix          # Network configuration
│   └── security.nix            # Security settings
└── hosts/
    ├── darwin-desktop/
    │   ├── configuration.nix   # Desktop system config
    │   └── home.nix            # Desktop user config
    ├── darwin-laptop/
    │   ├── configuration.nix   # Laptop system config
    │   └── home.nix            # Laptop user config
    └── darwin-server/
        ├── configuration.nix   # Server system config
        └── home.nix            # Server user config
```

### Updating Your System

**Regular updates:**

```bash
# Update everything
darwin-update

# Or manually:
cd ~/.config/nix-darwin
git pull origin main
nix flake update
darwin-rebuild switch --flake .
```

**Selective updates:**

```bash
# Update specific input
nix flake lock --update-input nixpkgs

# Update without pulling git changes
nix flake update && darwin-rebuild switch --flake .
```

### Managing Generations

**List generations:**

```bash
darwin-rebuild --list-generations
```

**Switch to specific generation:**

```bash
darwin-rebuild switch --switch-generation 42
```

**Delete old generations:**

```bash
# Delete generations older than 7 days
sudo nix-collect-garbage --delete-older-than 7d

# Delete all but current
sudo nix-collect-garbage -d
```

### Version Control

Track your configuration with Git:

```bash
cd ~/.config/nix-darwin

# Make changes
vim hosts/darwin-desktop/configuration.nix

# Commit changes
git add .
git commit -m "Add new development tools"

# Test the changes
darwin-rebuild switch --flake .
```

## Troubleshooting

### Common Issues

**Build Failures:**

```bash
# Check flake validity
nix flake check

# Build with more verbose output
darwin-rebuild switch --flake . --show-trace

# Check system log
log show --last 10m --predicate 'process == "nix"'
```

**Permission Issues:**

```bash
# Fix Nix store permissions
sudo chown -R root:nixbld /nix
sudo chmod 1775 /nix/store

# Restart nix-daemon
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon
```

**Path Issues:**

```bash
# Check PATH
echo $PATH

# Reload shell configuration
source ~/.zprofile

# Check nix-darwin activation
cat /run/current-system/activate
```

**Homebrew Integration Issues:**

```bash
# Reset Homebrew state
brew cleanup
brew doctor

# Force reinstall Homebrew packages
darwin-rebuild switch --flake . --option pure-eval false
```

### Performance Issues

**Slow Builds:**

```bash
# Use binary cache
echo "substituters = https://cache.nixos.org/ https://nix-community.cachix.org" >> ~/.config/nix/nix.conf
echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" >> ~/.config/nix/nix.conf

# Enable parallel builds
echo "max-jobs = auto" >> ~/.config/nix/nix.conf
```

**Large Nix Store:**

```bash
# Check store size
du -sh /nix/store

# Optimize store
nix store optimise

# Clean up
nix-collect-garbage -d
```

### Recovery

**System Won't Boot:**

```bash
# Boot from recovery partition
# In Terminal:
/nix/var/nix/profiles/system/activate

# Or rollback
darwin-rebuild --rollback
```

**Complete Reset:**

```bash
# Remove nix-darwin (destructive!)
sudo rm -rf /nix
sudo rm /etc/synthetic.conf
sudo rm /etc/nix/nix.conf

# Reinstall Nix and nix-darwin
curl -L https://nixos.org/nix/install | sh
# Then reinstall nix-darwin
```

## Advanced Usage

### Custom Modules

Create custom nix-darwin modules:

```nix
# darwin/custom-module.nix
{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.feature.enable = mkEnableOption "custom feature";
  };

  config = mkIf config.custom.feature.enable {
    environment.systemPackages = [ pkgs.custom-package ];
  };
}
```

### Multiple Users

Configure multiple users:

```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;

  users = {
    alice = import ./home/alice.nix;
    bob = import ./home/bob.nix;
  };
};
```

### Cross-Platform Configuration

Share configuration between NixOS and nix-darwin:

```nix
# shared/development.nix
{ pkgs, ... }:

{
  # Cross-platform development tools
  environment.systemPackages = with pkgs; [
    git
    vim
    nodejs
    python3
  ];
}
```

### Integration with CI/CD

```yaml
# .github/workflows/nix-darwin.yml
name: nix-darwin CI
on: [push, pull_request]

jobs:
  check:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      - name: Check flake
        run: nix flake check
      - name: Build configuration
        run: nix build .#darwinConfigurations.darwin-desktop.system
```

### Secrets Management

Integrate with agenix for secrets:

```nix
# secrets.nix
let
  user1 = "ssh-ed25519 AAAAC3...";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3...";
  systems = [ system1 ];
in
{
  "secret1.age".publicKeys = users ++ systems;
}
```

## Resources

### Documentation

- **nix-darwin Manual:** <https://daiderd.com/nix-darwin/manual/>
- **Home Manager Manual:** <https://nix-community.github.io/home-manager/>
- **NixOS Manual:** <https://nixos.org/manual/nixos/stable/>
- **Nix Reference:** <https://nixos.org/manual/nix/stable/>

### Community

- **nix-darwin Issues:** <https://github.com/LnL7/nix-darwin/issues>
- **NixOS Discourse:** <https://discourse.nixos.org/>
- **Matrix Chat:** #nix-darwin:nixos.org
- **Reddit:** r/NixOS

### Examples and Templates

- **nix-darwin Examples:** <https://github.com/LnL7/nix-darwin/tree/master/examples>
- **Community Dotfiles:** Search GitHub for "nix-darwin configuration"
- **NixOS Wiki:** <https://nixos.wiki/wiki/Darwin>

### Learning Resources

- **Nix Pills:** <https://nixos.org/guides/nix-pills/>
- **NixOS & Flakes Book:** <https://nixos-and-flakes.thiscute.world/>
- **Zero to Nix:** <https://zero-to-nix.com/>

This guide provides comprehensive coverage of nix-darwin usage. For additional help with the template, run `darwin-info` or refer to the configuration files in `~/.config/nix-darwin/`.
