# Host Template Functions

The NixOS template provides convenient functions for creating new hosts without duplicating configuration.

## Quick Start

The template functions are available in `lib/flake-utils.nix` and can be used in your `flake.nix`:

```nix
# Import the utilities
flakeUtils = import ./lib/flake-utils.nix { inherit inputs outputs nixpkgs self home-manager sops-nix; };

# Use template functions in nixosConfigurations
nixosConfigurations = {
  # Quick workstation
  my-desktop = flakeUtils.mkWorkstation {
    hostname = "my-desktop";
  };

  # Development machine
  dev-laptop = flakeUtils.mkDevelopment {
    hostname = "dev-laptop";
    system = "x86_64-linux";
  };

  # Headless server
  web-server = flakeUtils.mkServer {
    hostname = "web-server";
    extraModules = [ ./modules/services/nginx.nix ];
  };
};
```

## Available Templates

### Basic Host Types

- **`mkWorkstation`** - Desktop workstation with GUI applications
- **`mkServer`** - Headless server optimized for system administration
- **`mkDevelopment`** - Development environment with programming tools
- **`mkGaming`** - Gaming-optimized system with Steam and drivers
- **`mkLaptop`** - Mobile laptop with power management
- **`mkMinimal`** - Minimal system with essential packages only

### Specialized Templates

- **`mkVM`** - Virtual machine with guest optimizations
- **`mkContainer`** - Container/LXC system configuration
- **`mkWSLSystem`** - Windows Subsystem for Linux 2

### Advanced Templates with Home Manager

- **`mkDesktopHost`** - Workstation with automatic Home Manager desktop profile
- **`mkServerHost`** - Server with automatic Home Manager server profile

## Template Parameters

All templates accept these common parameters:

```nix
{
  hostname,                    # Required: System hostname
  system ? "x86_64-linux",   # Optional: System architecture
  extraModules ? []           # Optional: Additional NixOS modules
}
```

Advanced templates also accept:

```nix
{
  homeProfile ? "desktop",    # Home Manager profile to use
  profile ? "workstation"     # System profile type
}
```

## Examples

### Basic Server

```nix
web-server = flakeUtils.mkServer {
  hostname = "web-server";
  extraModules = [
    # Custom nginx configuration
    ({ config, ... }: {
      services.nginx.enable = true;
      networking.firewall.allowedTCPPorts = [ 80 443 ];
    })
  ];
};
```

### Development Laptop

```nix
dev-laptop = flakeUtils.mkDevelopment {
  hostname = "dev-laptop";
  system = "x86_64-linux";
  extraModules = [
    # Laptop-specific power management
    ./modules/hardware/laptop.nix

    # Custom development tools
    ({ config, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        jetbrains.idea-ultimate
        docker
        kubernetes
      ];
    })
  ];
};
```

### VM with Custom Profile

```nix
test-vm = flakeUtils.mkVM {
  hostname = "test-vm";
  profile = "development";  # Use development profile instead of default workstation
  extraModules = [
    # VM-specific optimizations are automatically included
    ({ config, ... }: {
      # Additional VM configuration
      virtualisation.memorySize = 4096;
      virtualisation.cores = 4;
    })
  ];
};
```

### Complete Desktop with Home Manager

```nix
my-desktop = flakeUtils.mkDesktopHost {
  hostname = "my-desktop";
  homeProfile = "desktop";  # Uses home/profiles/desktop.nix
  extraModules = [
    ./hardware-configuration.nix
    ({ config, pkgs, ... }: {
      # System-level desktop configuration
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    })
  ];
};
```

## Custom Templates

You can create your own templates by following the same pattern:

```nix
# In your flake.nix
let
  flakeUtils = import ./lib/flake-utils.nix { inherit inputs outputs nixpkgs self home-manager sops-nix; };

  # Custom template
  mkMediaServer = { hostname, system ? "x86_64-linux", extraModules ? [] }:
    flakeUtils.mkServer {
      inherit hostname system;
      extraModules = [
        ./modules/services/plex.nix
        ./modules/services/sonarr.nix
        ./modules/services/radarr.nix
      ] ++ extraModules;
    };
in {
  nixosConfigurations = {
    media-server = mkMediaServer {
      hostname = "media-server";
      extraModules = [
        # Additional media server configuration
        ({ config, ... }: {
          services.plex.dataDir = "/mnt/media/plex";
          networking.firewall.allowedTCPPorts = [ 32400 ];
        })
      ];
    };
  };
}
```

## Profile System Integration

All template functions work seamlessly with the Home Manager profile system:

1. **Automatic Profile Application** - Templates automatically apply appropriate Home Manager profiles
1. **Host-Specific Overrides** - Individual hosts can override profile settings
1. **Consistent Configuration** - Shared profiles ensure consistent tool availability
1. **Easy Maintenance** - Update profiles to affect all systems using them

For more information about the profile system, see [CLAUDE.md](../CLAUDE.md).
