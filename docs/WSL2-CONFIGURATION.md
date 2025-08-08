# NixOS on WSL2 Configuration Guide

This guide covers installing and configuring NixOS on Windows Subsystem for Linux 2 (WSL2) using this template, providing a full development environment that seamlessly integrates with Windows.

## Table of Contents

1. [Overview](#overview)
1. [Prerequisites](#prerequisites)
1. [Installation](#installation)
1. [Configuration](#configuration)
1. [Windows Integration](#windows-integration)
1. [Development Environment](#development-environment)
1. [Performance Optimization](#performance-optimization)
1. [Troubleshooting](#troubleshooting)
1. [Advanced Usage](#advanced-usage)

## Overview

NixOS on WSL2 provides a complete declarative Linux development environment that seamlessly integrates with Windows. This template includes comprehensive WSL2 support with specialized modules and optimizations.

### Key Features

- **Windows Integration** - Seamless file system access, clipboard sharing, application launching
- **Performance Optimizations** - Memory management, network stack, filesystem tuning for WSL2
- **Development Environment** - Pre-configured with Zsh, development tools, and WSL2-specific utilities
- **Modular Architecture** - Specialized WSL2 modules for different aspects of integration
- **Container Support** - Docker/Podman with Windows integration
- **GUI Application Support** - X11 forwarding and WSLg compatibility
- **Systemd Integration** - Full systemd support with WSL2 optimizations

### WSL2 Module System

The template includes dedicated WSL2 modules:

- **`modules/wsl/interop.nix`** - Windows application integration, clipboard, file associations
- **`modules/wsl/networking.nix`** - Network optimizations, firewall configuration, diagnostics
- **`modules/wsl/optimization.nix`** - Performance tuning for memory, filesystem, services
- **`modules/wsl/systemd.nix`** - Systemd service optimizations for WSL2 environment

### Benefits

- **Declarative Configuration** - Reproducible development environments with version control
- **Windows Compatibility** - Native Windows tool integration with Linux development power
- **Performance** - Optimized for WSL2 with memory, network, and filesystem tuning
- **Consistency** - Same environment across different machines and team members
- **Professional Development** - Complete development stack with Windows interoperability

## Prerequisites

### Windows Requirements

- **Windows 10** version 2004 and higher (Build 19041 and higher)
- **Windows 11** (recommended)
- **WSL 2** enabled with Virtual Machine Platform
- **Administrator access** for installation

### Hardware Requirements

- **CPU**: x64 with virtualization support
- **Memory**: Minimum 4GB RAM (8GB+ recommended)
- **Storage**: 10GB+ available space
- **GPU**: Optional, for GUI applications and development

### Software Prerequisites

1. **Enable WSL 2**:

   ```powershell
   # Run as Administrator
   wsl --install
   # or
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

1. **Set WSL 2 as default**:

   ```powershell
   wsl --set-default-version 2
   ```

1. **Install Windows Terminal** (recommended):
   - From Microsoft Store or GitHub releases

## Installation

### Automated Installation (Recommended)

1. **Download the template**:

   ```powershell
   git clone https://github.com/yourusername/nixos-template
   cd nixos-template
   ```

1. **Run the installation script**:

   ```powershell
   # Run PowerShell as Administrator
   .\scripts\install-wsl2.sh
   ```

1. **Follow the prompts**:
   - Choose username and password
   - Wait for installation to complete (10-30 minutes)

### Manual Installation

1. **Download NixOS-WSL**:

   ```powershell
   wget https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos-wsl-installer.tar.gz
   ```

1. **Import the distribution**:

   ```powershell
   wsl --import NixOS-Template C:\WSL\NixOS-Template nixos-wsl-installer.tar.gz --version 2
   ```

1. **Copy template configuration**:

   ```bash
   wsl -d NixOS-Template
   # Inside WSL:
   git clone https://github.com/yourusername/nixos-template /tmp/template
   sudo cp -r /tmp/template/hosts/wsl2-template/* /etc/nixos/
   sudo nixos-rebuild switch
   ```

## Configuration

### System Configuration

The main system configuration is in `/etc/nixos/configuration.nix`:

```nix
# Core WSL2 settings from nixos-wsl
wsl = {
  enable = true;
  defaultUser = "nixos";
  startMenuLaunchers = true;  # Add apps to Windows Start Menu
  interop = {
    includePath = true;       # Include Windows PATH in WSL PATH
    register = true;          # Register WSL interop
  };
  useWindowsDriver = true;    # Use Windows OpenGL driver for better GPU performance
  docker-desktop.enable = false; # Enable if using Docker Desktop
  usbip.enable = false;      # Enable for USB device access
};

# Template-specific WSL2 modules
modules.wsl = {
  interop = {
    enable = true;           # Windows application integration
    windowsApps = true;      # Enable Windows app aliases (explorer.exe, code.exe)
    clipboard = true;        # Bidirectional clipboard sharing
    fileAssociations = true; # Open files with Windows applications
  };

  networking = {
    enable = true;
    dnsConfig = "auto";      # "auto" | "wsl" | "custom"
    firewallConfig = "disabled"; # "disabled" | "minimal" | "standard"
    networkOptimizations = true; # TCP and network performance tuning
    portForwarding = {       # Custom port forwarding for development
      ssh = 22;
      web = 3000;
      api = 8080;
    };
  };

  optimization = {
    enable = true;
    memory = {
      swappiness = 10;       # Lower swap usage (0-100)
      cacheOptimization = true;
      hugepages = false;     # Enable for memory-intensive workloads
    };
    filesystem = {
      mountOptimizations = true; # Optimize Windows drive mounts
      tmpfsSize = "2G";      # Size for /tmp tmpfs
      noCOW = true;          # Disable copy-on-write for large files
    };
    services = {
      disableUnneeded = true; # Disable services not needed in WSL
      optimizeSystemd = true; # Faster boot and service management
    };
    development = {
      fastBuild = true;      # Optimize for development builds
      cacheNix = true;       # Nix store optimizations
    };
  };

  systemd = {
    enable = true;           # Systemd optimizations for WSL2
    networkOptimizations = true; # Network service optimizations
    serviceOptimizations = true; # General service optimizations
  };
};
```

### Module Configuration Details

#### Windows Interop Module (`modules.wsl.interop`)

Controls Windows integration features:

- **windowsApps**: Creates shell aliases for Windows applications
- **clipboard**: Enables clipboard sharing between Windows and WSL2
- **fileAssociations**: Allows opening files with appropriate Windows applications
- **windowsPath**: Includes Windows PATH in WSL environment

#### Networking Module (`modules.wsl.networking`)

Optimizes network performance and configuration:

- **dnsConfig**: DNS resolution strategy (auto-detect, use WSL default, or custom)
- **firewallConfig**: Firewall configuration level (disabled for dev, minimal, or standard)
- **networkOptimizations**: TCP window scaling, BBR congestion control
- **portForwarding**: Automatic port forwarding setup for development servers

#### Optimization Module (`modules.wsl.optimization`)

Performance tuning for WSL2 environment:

- **Memory Management**: Swappiness, cache pressure, transparent hugepages
- **Filesystem**: tmpfs configuration, mount optimizations, COW settings
- **Services**: Disable unnecessary services, optimize systemd timeouts
- **Development**: Parallel builds, Nix store optimizations, compiler flags

#### Systemd Module (`modules.wsl.systemd`)

Systemd service optimizations:

- **Service Timeouts**: Faster start/stop timeouts for WSL2
- **Network Services**: Optimized DNS and network service configuration
- **Performance Services**: Background services for performance monitoring

### User Configuration

Home Manager configuration is in `~/.config/home-manager/home.nix`:

```nix
# Import role-based configurations
imports = [
  ../../home/roles/developer.nix
  ../../home/profiles/headless.nix
];

# WSL2-specific shell aliases
programs.zsh.shellAliases = {
  explorer = "explorer.exe";
  code = "code.exe";
  wsl-open = "explorer.exe .";
};
```

### Customization

1. **Edit system configuration**:

   ```bash
   sudo nano /etc/nixos/configuration.nix
   ```

1. **Edit user configuration**:

   ```bash
   nano ~/.config/home-manager/home.nix
   ```

1. **Apply changes**:

   ```bash
   sudo nixos-rebuild switch
   home-manager switch
   ```

## Windows Integration

### File System Access

- **Windows drives**: Mounted at `/mnt/c`, `/mnt/d`, etc.
- **WSL home**: Accessible from Windows at `\\wsl$\NixOS-Template\home\username`
- **Performance tip**: Keep development files on WSL filesystem (`/home`)

### Application Integration

```bash
# Open current directory in Windows Explorer
wsl-open .

# Edit file in VS Code
wsl-edit myfile.txt

# Run Windows applications
explorer.exe
notepad.exe file.txt
code.exe project/
```

### Clipboard Integration

The template includes clipboard sharing between WSL and Windows:

```bash
# Copy to Windows clipboard
echo "text" | clip.exe

# In tmux/vim, clipboard operations work automatically
```

### PATH Integration

Windows executables are available in WSL PATH:

```bash
# These work automatically
code .
explorer .
powershell.exe
cmd.exe
```

## Development Environment

### Included Development Tools

- **Shell**: Zsh with Oh-My-Zsh and Starship prompt, WSL2-specific functions
- **Editor**: Vim with optimized configuration and clipboard integration
- **Version Control**: Git with Windows credential integration and performance optimizations
- **Languages**: Node.js, Python, Rust, Go with WSL2 performance tuning
- **Package Managers**: npm, pip, cargo with parallel build optimizations
- **Container Tools**: Docker/Podman with Windows integration and GPU support
- **Development Utilities**: tmux with clipboard sync, fzf, jq, curl, wget, WSL-specific tools

### WSL2-Specific Utilities

The template includes custom utilities for WSL2 integration:

**System Information and Monitoring**

- `wsl-info` - Comprehensive WSL2 system information
- `wsl-network-info` - Network configuration and diagnostics
- `wsl-performance-tune` - Performance analysis and optimization
- `system-info` - Detailed hardware and software information
- `performance-monitor` - Real-time system performance monitoring

**Windows Integration Utilities**

- `wsl-open <path>` - Open files/directories in Windows Explorer
- `wsl-edit <file>` - Edit files in Windows applications (VS Code, Notepad)
- `wsl-ports` - Show listening ports and services
- `wsl-network-diagnostics` - Network troubleshooting and connectivity tests

**Development Environment Helpers**

- `dev-start` - Start development environment services
- `dev-stop` - Stop development servers and processes
- `dev-env-setup` - Initialize development directory structure
- `wsl-restart` - Restart WSL2 instance from within WSL
- `wsl-shutdown` - Shutdown WSL2 instance safely

### Development Workflow

1. **Clone projects to WSL filesystem**:

   ```bash
   cd ~
   git clone https://github.com/user/project.git
   cd project
   ```

1. **Use integrated development tools**:

   ```bash
   # Open project in VS Code
   code .

   # Start development server
   npm run dev

   # Access from Windows browser: http://localhost:3000
   ```

1. **Container development**:

   ```bash
   # Docker works with Windows Docker Desktop
   docker run -p 8080:80 nginx

   # Or use Podman
   podman run -p 8080:80 nginx
   ```

### Project Structure

Recommended project organization:

```
~/Development/
├── projects/           # Main development projects
│   ├── web/           # Web development
│   ├── mobile/        # Mobile development
│   └── desktop/       # Desktop applications
├── tools/             # Development tools and utilities
└── scripts/           # Custom scripts and automation
```

## Performance Optimization

### WSL2 Configuration

Create or edit `C:\Users\Username\.wslconfig`:

```ini
[wsl2]
# Memory allocation (adjust based on your system)
memory=8GB
# Processor count
processors=4
# Swap file size
swap=2GB
# Networking mode
networkingMode=mirrored
# GUI applications
guiApplications=true
```

### System Optimizations

The template includes several performance optimizations:

- **Memory Management**: Optimized swappiness and caching
- **Network Performance**: TCP optimizations for WSL2
- **File System**: tmpfs for `/tmp`, optimized mount options
- **Service Management**: Disabled unnecessary services
- **Build Optimization**: Parallel builds, Nix store optimization

### Performance Monitoring

```bash
# System information and performance
wsl-info
wsl-performance-tune

# Resource monitoring
htop
iotop
performance-monitor
```

### Best Practices

1. **File Location**: Keep development files on WSL filesystem (`/home`)
1. **Memory Management**: Use `wsl --shutdown` periodically to free memory
1. **Network**: Use `wsl-network-diagnostics` to troubleshoot connectivity
1. **Storage**: Regular cleanup with `nix-collect-garbage`

## Troubleshooting

### Common Issues

#### WSL2 Won't Start

1. **Check WSL status**:

   ```powershell
   wsl --status
   wsl --list --verbose
   ```

1. **Restart WSL service**:

   ```powershell
   # As Administrator
   Restart-Service LxssManager
   ```

1. **Reset WSL2**:

   ```powershell
   wsl --shutdown
   wsl --unregister NixOS-Template
   # Reinstall from backup
   ```

#### Network Issues

1. **Check network configuration**:

   ```bash
   wsl-network-diagnostics
   ```

1. **Reset network settings**:

   ```bash
   sudo systemctl restart systemd-networkd
   sudo systemctl restart systemd-resolved
   ```

1. **Windows network reset**:

   ```powershell
   # As Administrator
   netsh winsock reset
   netsh int ip reset
   ```

#### Performance Issues

1. **Check resource usage**:

   ```bash
   performance-monitor
   htop
   ```

1. **Optimize WSL2 settings**:

   ```bash
   wsl-performance-tune
   ```

1. **Free up memory**:

   ```powershell
   wsl --shutdown
   # Wait 8 seconds, then restart
   wsl -d NixOS-Template
   ```

#### GUI Applications

1. **Install VcXsrv or similar X server on Windows**

1. **Set DISPLAY variable**:

   ```bash
   export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
   ```

1. **Test GUI application**:

   ```bash
   # Install a simple GUI app
   nix-shell -p xeyes --run xeyes
   ```

### Configuration Issues

#### NixOS Rebuild Fails

1. **Check configuration syntax**:

   ```bash
   sudo nixos-rebuild dry-run
   ```

1. **Rollback to previous generation**:

   ```bash
   sudo nixos-rebuild switch --rollback
   ```

1. **Clean Nix store**:

   ```bash
   sudo nix-collect-garbage -d
   ```

#### Home Manager Issues

1. **Check configuration**:

   ```bash
   home-manager build
   ```

1. **Reset Home Manager**:

   ```bash
   rm -rf ~/.local/state/home-manager/gcroots
   home-manager switch
   ```

### Getting Help

1. **Check system logs**:

   ```bash
   sudo journalctl -u multi-user.target
   sudo journalctl -f  # Follow logs in real-time
   ```

1. **WSL logs**:

   ```powershell
   # In PowerShell
   Get-EventLog -LogName Application -Source "Microsoft-Windows-Subsystem-Linux"
   ```

1. **Template-specific diagnostics**:

   ```bash
   wsl-systemd-status
   wsl-systemd-optimize
   ```

## Advanced Usage

### Custom Modules

Create custom WSL2-specific modules:

```nix
# modules/custom/wsl-dev.nix
{ config, lib, pkgs, ... }:
{
  # Custom development environment for WSL2
  environment.systemPackages = with pkgs; [
    # Your custom packages
  ];

  # Custom services
  systemd.user.services.my-dev-service = {
    # Service configuration
  };
}
```

### Multiple WSL Distributions

You can run multiple NixOS instances:

```powershell
# Export current installation
wsl --export NixOS-Template nixos-backup.tar

# Create new instance
wsl --import NixOS-Dev C:\WSL\NixOS-Dev nixos-backup.tar

# Customize each instance separately
wsl -d NixOS-Dev
# Edit /etc/nixos/configuration.nix with different settings
```

### Integration with IDEs

#### Visual Studio Code

1. **Install WSL extension**

1. **Open project in WSL**:

   ```bash
   code .
   ```

1. **Configure VS Code settings** for WSL development

#### JetBrains IDEs

1. **Use JetBrains Gateway** for remote development
1. **Configure SSH connection** to WSL2
1. **Set up project interpreter** pointing to WSL2

### Backup and Migration

#### Backup Configuration

```bash
# Backup system configuration
sudo cp -r /etc/nixos ~/nixos-backup

# Backup Home Manager configuration
cp -r ~/.config/home-manager ~/home-manager-backup

# Export WSL distribution
wsl --export NixOS-Template nixos-full-backup.tar
```

#### Migration

```bash
# On new system, import distribution
wsl --import NixOS-Template C:\WSL\NixOS-Template nixos-full-backup.tar

# Apply configurations
sudo nixos-rebuild switch
home-manager switch
```

### Container Integration

#### Docker Desktop Integration

The template works with Docker Desktop for Windows:

```bash
# Docker commands work transparently
docker run hello-world
docker-compose up
```

#### Podman Alternative

Or use Podman for a fully Linux solution:

```bash
# Podman with similar Docker experience
podman run hello-world
podman-compose up
```

### Networking

#### Port Forwarding

WSL2 handles port forwarding automatically, but for advanced cases:

```powershell
# Manual port forwarding (if needed)
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=WSL_IP
```

#### Custom Networking

Configure custom networking in your NixOS configuration:

```nix
# Advanced network configuration
networking = {
  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8080 ];
  };

  # Custom DNS
  nameservers = [ "1.1.1.1" "8.8.8.8" ];
};
```

## Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **NixOS-WSL Project**: https://github.com/nix-community/NixOS-WSL
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **WSL Documentation**: https://docs.microsoft.com/en-us/windows/wsl/
- **Template Repository**: https://github.com/yourusername/nixos-template

## Contributing

To improve WSL2 support in this template:

1. Fork the repository
1. Make improvements to WSL2 modules or configuration
1. Test thoroughly in WSL2 environment
1. Submit a pull request with detailed description

Common areas for contribution:

- Performance optimizations
- Windows integration improvements
- Additional development tools
- Better GUI application support
- Documentation improvements
