# System Identification Guide

The NixOS template includes a standardized system identification module that provides consistent hostname patterns, profile management, and system metadata across all configurations.

## Overview

Instead of manually setting `networking.hostName` and other system identifiers, use the `systemId` module for:

- **Consistent naming patterns** across different system types
- **Automatic profile detection** based on hostname
- **System metadata management** with flake integration
- **Environment classification** (production, staging, development, testing)
- **Custom tagging** for system organization

## Basic Configuration

```nix
systemId = {
  baseName = "workstation-01";
  profile = "workstation";           # workstation, server, laptop, gaming, development, minimal
  description = "Main development workstation";
  environment = "production";        # production, staging, development, testing
  location = "Home Office";          # Optional physical location
  tags = [ "gpu-enabled" "high-memory" "development" ];
};
```

## System Types and Naming

The system identification module automatically detects system types and applies appropriate hostname prefixes:

| System Type | Hostname Pattern      | Example                 |
| ----------- | --------------------- | ----------------------- |
| Physical    | `baseName`            | `workstation-01`        |
| VM          | `nixos-vm-baseName`   | `nixos-vm-development`  |
| WSL         | `nixos-wsl-baseName`  | `nixos-wsl-development` |
| Darwin      | `nix-darwin-baseName` | `nix-darwin-desktop`    |

### Disable System Type Prefixes

```nix
systemId = {
  baseName = "server-prod-01";
  useSystemTypePrefix = false;  # Use baseName directly
};
```

## Profile Types

| Profile       | Use Case                             | Auto-detected from hostname  |
| ------------- | ------------------------------------ | ---------------------------- |
| `workstation` | Desktop development/productivity     | `*desktop*`, `*workstation*` |
| `server`      | Headless server systems              | `*server*`                   |
| `laptop`      | Mobile systems with power management | `*laptop*`                   |
| `gaming`      | Gaming-optimized systems             | `*gaming*`                   |
| `development` | Development environments             | `*dev*`, `*development*`     |
| `minimal`     | Minimal installations                | -                            |

## Environment Classification

Use environments to organize systems by their deployment stage:

```nix
# Production server
systemId = {
  baseName = "web-server-01";
  environment = "production";
  tags = [ "public-facing" "load-balanced" ];
};

# Development workstation
systemId = {
  baseName = "dev-workstation";
  environment = "development";
  tags = [ "testing" "experimental" ];
};

# Staging environment
systemId = {
  baseName = "staging-api";
  environment = "staging";
  tags = [ "testing" "temporary" ];
};
```

## System Tags

Tags provide flexible system classification:

### Common Tag Categories

**Hardware Tags:**

- `gpu-enabled`, `gpu-nvidia`, `gpu-amd`, `gpu-intel`
- `high-memory`, `ssd-storage`, `nvme-storage`
- `wifi-enabled`, `ethernet-only`

**Purpose Tags:**

- `build-server`, `database`, `web-frontend`, `api-backend`
- `monitoring`, `logging`, `backup`
- `development`, `testing`, `ci-cd`

**Network Tags:**

- `dmz`, `internal`, `management`
- `public-facing`, `load-balanced`
- `vpn-access`, `ssh-access`

**Compliance Tags:**

- `pci-compliant`, `hipaa`, `gdpr`
- `encrypted-storage`, `audit-logging`

## System Information Commands

The system identification module provides useful commands:

### `system-id` - System Information

```bash
$ system-id
System Identification
========================

Basic Information:
  Hostname: nixos-vm-development
  Profile: development
  Type: vm
  Environment: development
  Location: Home Lab
  Description: Development VM for testing

Tags: gpu-enabled, development, testing

Platform:
  Architecture: x86_64
  Kernel: 6.1.55
  NixOS State Version: 25.05

🔧 Flake Metadata:
  Build Date: build-1699123456
  Flake Rev: a1b2c3d
  Nixpkgs Rev: 4e5f6a7

Configuration:
  Config Path: /etc/nixos
  System Type Prefix: enabled
  Flake Integration: enabled
```

### `system-tags` - Tag Management

```bash
$ system-tags
System Tags Management
=========================

Current tags: gpu-enabled, development, testing

Common tag patterns:
  Hardware: gpu-enabled, high-memory, ssd-storage
  Purpose: build-server, database, web-frontend
  Network: dmz, internal, management
  Compliance: pci-compliant, hipaa, gdpr

Note: Tags are configured in configuration.nix
Add tags with: systemId.tags = [ "tag1" "tag2" ];
```

## Darwin Integration

For nix-darwin systems, the module automatically handles macOS-specific naming:

```nix
# Darwin desktop configuration
systemId = {
  baseName = "desktop";
  profile = "workstation";
};

# Results in:
# networking.hostName = "nix-darwin-desktop"
# networking.localHostName = "nix-darwin-desktop"
# networking.computerName = "nix-darwin Desktop"
```

## Flake Metadata Integration

When used with the template's flake system, system identification integrates with build metadata:

```nix
systemId = {
  useFlakeMetadata = true;  # Default
  # Enables integration with build dates, revisions, and system info
};
```

## Migration from Manual Configuration

### Old Pattern

```nix
networking.hostName = "my-server";
system.stateVersion = "25.05";
```

### New Pattern

```nix
systemId = {
  baseName = "my-server";
  profile = "server";
  environment = "production";
  tags = [ "web-server" ];
};
# hostname, stateVersion, and metadata handled automatically
```

## Advanced Examples

### Production Web Server

```nix
systemId = {
  baseName = "web-01";
  profile = "server";
  description = "Primary web server with load balancing";
  environment = "production";
  location = "Datacenter-A";
  tags = [
    "web-server"
    "load-balanced"
    "public-facing"
    "ssl-termination"
    "high-availability"
  ];
};
```

### Gaming Desktop

```nix
systemId = {
  baseName = "gaming-rig";
  profile = "gaming";
  description = "High-performance gaming desktop";
  environment = "production";
  location = "Home Office";
  tags = [
    "gaming"
    "gpu-nvidia-rtx4080"
    "high-memory-32gb"
    "nvme-storage"
    "rgb-lighting"
  ];
};
```

### Development Laptop

```nix
systemId = {
  baseName = "dev-laptop";
  profile = "laptop";
  description = "Mobile development workstation";
  environment = "development";
  tags = [
    "mobile"
    "battery-optimized"
    "development"
    "docker-enabled"
    "vpn-access"
  ];
};
```

### CI/CD Build Server

```nix
systemId = {
  baseName = "build-server-01";
  profile = "server";
  description = "Automated build and testing server";
  environment = "staging";
  location = "Cloud-US-East";
  tags = [
    "ci-cd"
    "build-server"
    "docker-enabled"
    "high-cpu"
    "temporary"
  ];
};
```

## Validation and Warnings

The system identification module includes validation:

### Assertions

- `baseName` cannot be empty
- `baseName` cannot contain spaces
- `baseName` must be ≤63 characters (hostname limit)

### Warnings

- Using default `baseName` values
- Profile mismatches (e.g., workstation profile on VM)
- Disabled flake integration when metadata is available

## Integration with Other Modules

The system identification module integrates with other template modules:

- **Power Management**: Profiles automatically configure power settings
- **GPU Detection**: GPU tags influence driver selection
- **Firewall**: Environment affects default firewall rules
- **Services**: Profile determines default service configurations
- **Package Collections**: Profile influences package selection

## Best Practices

1. **Use descriptive base names**: `web-server-01` instead of `server1`
1. **Tag consistently**: Use standardized tag categories
1. **Set appropriate environments**: Match your deployment pipeline
1. **Include location for physical systems**: Helps with remote management
1. **Use profiles that match hardware**: `laptop` for mobile, `server` for headless
1. **Keep descriptions concise but informative**: One sentence explaining purpose

This standardized approach ensures consistent system identification across your entire NixOS infrastructure.
