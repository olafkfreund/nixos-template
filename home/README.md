# Home Manager Configuration Structure

This directory contains a modular Home Manager configuration system that eliminates duplication and provides clear separation between common and host-specific settings.

## Directory Structure

```
home/
├── common/                    # Shared configurations used by all roles
│   ├── base.nix              # Universal settings (shell, XDG, basic programs)
│   ├── git.nix               # Common git configuration with user overrides
│   └── packages/             # Package groups by purpose
│       ├── essential.nix     # Core CLI tools (git, vim, curl, etc)
│       ├── development.nix   # Development tools (nodejs, docker, etc)
│       └── desktop.nix       # GUI applications (firefox, libreoffice, etc)
├── roles/                    # Role-based configurations
│   ├── developer.nix         # Full development environment (zsh, starship, direnv)
│   ├── gamer.nix            # Gaming setup (steam, mangohud, performance tools)
│   ├── server-admin.nix     # Server administration (monitoring, containers, tmux)
│   └── minimal.nix          # Bare minimum for resource-constrained systems
├── profiles/                 # Desktop environment profiles
│   ├── gnome.nix            # GNOME-specific configuration
│   ├── kde.nix              # KDE-specific configuration
│   └── headless.nix         # No GUI configuration for servers
├── examples/                 # Example configurations showing best practices
│   ├── developer-desktop.nix # Developer with GNOME desktop
│   ├── server-admin.nix     # Server administrator setup
│   └── gamer-kde.nix        # Gaming setup with KDE
└── users/                   # Legacy user configurations (deprecated)
```

## How to Use

### Host Configuration Structure

Each `hosts/*/home.nix` file should be minimal and only contain:

1. **Role and Profile Imports**: Choose the appropriate role and profile
2. **User-specific Information**: Username, email, home directory
3. **Host-specific Customizations**: Only settings unique to that host

### Example Host Configuration

```nix
# hosts/my-workstation/home.nix
{ ... }:
{
  imports = [
    ../../home/roles/developer.nix    # Development environment
    ../../home/profiles/gnome.nix     # GNOME desktop
  ];

  # User-specific information (required)
  home = {
    username = "johndoe";
    homeDirectory = "/home/johndoe";
  };

  # User-specific git configuration (required)
  programs.git = {
    userName = "John Doe";
    userEmail = "john.doe@company.com";
  };

  # Host-specific overrides (optional)
  programs.zsh = {
    shellAliases = {
      work = "cd ~/Work";
      company-vpn = "sudo openvpn ~/Work/company.ovpn";
    };
  };
}
```

## Available Roles

### Developer Role (`roles/developer.nix`)

- **Includes**: Essential packages, development tools, desktop applications
- **Programs**: Zsh with autosuggestions, Starship prompt, Direnv, Git with Delta, Bat, Fzf
- **Use Case**: Full development workstation

### Gamer Role (`roles/gamer.nix`)

- **Includes**: Essential packages, desktop applications, gaming-specific tools
- **Programs**: Steam, Lutris, MangoHud, Discord, OBS Studio, performance monitoring
- **Use Case**: Gaming desktop with streaming capabilities

### Server Admin Role (`roles/server-admin.nix`)

- **Includes**: Essential packages, server administration tools
- **Programs**: System monitoring, network tools, containers, backup utilities, Tmux
- **Use Case**: Server administration and maintenance

### Minimal Role (`roles/minimal.nix`)

- **Includes**: Only essential packages with minimal footprint
- **Programs**: Basic bash, minimal git configuration
- **Use Case**: Resource-constrained environments, embedded systems

## Available Profiles

### Desktop Profiles

- **GNOME** (`profiles/gnome.nix`): GNOME desktop environment configuration
- **KDE** (`profiles/kde.nix`): KDE Plasma desktop environment configuration
- **Headless** (`profiles/headless.nix`): No GUI, terminal-only configuration

## Package Organization

### Essential Packages (`common/packages/essential.nix`)

Core command-line tools needed by everyone:

- File management: `file`, `tree`, `less`, `unzip`, `tar`
- Network: `curl`, `wget`
- System: `htop`, `iotop`
- Editors: `nano`, `vim`
- Development: `git`
- Utilities: `jq`, `yq-go`

### Development Packages (`common/packages/development.nix`)

Tools for software development:

- Version control: `git-lfs`, `gh`
- Build tools: `make`, `cmake`
- Languages: `nodejs`, `python3`
- Containers: `docker-compose`
- Analysis: `shellcheck`, `hyperfine`

### Desktop Packages (`common/packages/desktop.nix`)

GUI applications for desktop environments:

- Browsers: `firefox`
- Office: `libreoffice`, `evince`
- Media: `vlc`
- Graphics: `gimp`, `inkscape`

## Migration from Old Structure

### Old Structure Issues

- Massive duplication across `hosts/*/home.nix` files
- Unclear relationship between `home/users/*.nix` and host configurations
- Mixed concerns (packages, user info, host-specific settings all together)

### Migration Steps

1. **Identify the role**: What is the primary function of this host?
2. **Choose a profile**: What desktop environment (if any)?
3. **Update host config**: Use the new minimal structure
4. **Move customizations**: Extract any host-specific settings to the minimal host config

### Example Migration

**Old** `hosts/my-desktop/home.nix` (50+ lines with packages, programs, etc):

```nix
{ pkgs, ... }: {
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.05";
    packages = with pkgs; [ firefox libreoffice git nodejs ... ];
  };
  programs = {
    git = { ... };
    bash = { ... };
    # ... many more programs
  };
}
```

**New** `hosts/my-desktop/home.nix` (15 lines, clear intent):

```nix
{ ... }: {
  imports = [
    ../../home/roles/developer.nix
    ../../home/profiles/gnome.nix
  ];
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };
  programs.git = {
    userName = "User Name";
    userEmail = "user@example.com";
  };
}
```

## Benefits

1. **No Duplication**: Common configurations are shared across all hosts
2. **Clear Intent**: Role and profile imports make the purpose obvious
3. **Easy Maintenance**: Update once, apply everywhere
4. **Flexible Override**: Host-specific customizations are still possible
5. **Type Safety**: All configurations are still fully typed with NixOS module system
6. **Consistent Experience**: Same tools and aliases across all hosts with the same role

## Legacy Support

The old `home/users/*.nix` files are still present for backward compatibility but are deprecated. New configurations should use the role/profile system.
