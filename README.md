# Modern NixOS Configuration Template

A modular NixOS configuration template using flakes, featuring:

- **VM Testing Ready** - Full desktop environment testing in VMs (works on any Linux distro)
- **Custom ISO Creation** - Build installer ISOs with preconfigured templates
- **Interactive Installers** - Template selection and automated deployment
- **Multi-Platform Support** - Works on any Linux distribution
- **Modular Architecture** - Organized, reusable modules
- **Home Manager Integration** - Declarative user environments
- **SOPS Secrets Management** - Encrypted secrets in Git
- **Multiple Host Support** - Desktop, laptop, server, VM configurations
- **GPU Support** - Manual configuration for AMD, NVIDIA, Intel with gaming/AI optimizations
- **AI/Compute Ready** - CUDA, ROCm, OneAPI for machine learning
- **Development Tools** - Scripts and utilities for easy management
- **Custom Packages & Overlays** - Extend and customize packages
- **Boot Reliability** - Fixed VM systemd conflicts and boot issues
- **Modern Development Tooling** - treefmt-nix formatting, git-hooks pre-commit, nh helper
- **NixOS 25.05/25.11 Compatible** - Latest NixOS features and deprecation fixes
- **Container Support** - Fixed podman system-generators conflicts, full container ecosystem
- **Modular Home Configuration** - Role-based Home Manager with common/host-specific separation
- **WSL2 Support** - Full Windows Subsystem for Linux integration with development environment

**[Complete Features Overview →](docs/FEATURES-OVERVIEW.md)**

## Table of Contents

1. [Quick Start](#quick-start)
   - [Non-NixOS Users (Try NixOS in VMs)](#non-nixos-users-try-nixos-in-vms)
   - [Custom NixOS Installer ISOs](#custom-nixos-installer-isos)
   - [New NixOS Users (Automated Setup)](#new-nixos-users-automated-setup)
   - [Advanced Users (Manual Setup)](#advanced-users-manual-setup)
1. [Project Structure](#project-structure)
1. [Available Commands](#available-commands)
1. [Module System](#module-system)
1. [GPU Configuration](#gpu-configuration)
1. [Virtual Machine Testing](#virtual-machine-testing)
1. [Custom NixOS Installer ISOs](#custom-nixos-installer-isos-1)
1. [Host Configurations](#host-configurations)
1. [WSL2 Support](#wsl2-support)
1. [Secrets Management](#secrets-management)
1. [Development Shell](#development-shell)
1. [Best Practices](#best-practices)
1. [Validation & CI/CD](#validation--cicd)
1. [Troubleshooting](#troubleshooting)

## Quick Start

### Non-NixOS Users (Try NixOS in VMs)

**Want to try NixOS without installing it?** You can test this entire configuration on Ubuntu,
Fedora, Arch, or any Linux distribution:

```bash
# Install Nix package manager (works on any Linux)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone and test NixOS in a VM
git clone <your-repo> nixos-test
cd nixos-test
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm

# Login: username=vm-user, password=nixos
```

**[Complete Non-NixOS Usage Guide →](docs/NON-NIXOS-USAGE.md)**

### Custom NixOS Installer ISOs

**Create bootable NixOS installers with your preconfigured templates:**

```bash
# Build preconfigured installer (recommended - includes all templates)
just build-iso-preconfigured

# Build minimal CLI installer (lightweight for servers)
just build-iso-minimal

# Build desktop installer (GNOME for newcomers)
just build-iso-desktop

# Create bootable USB (replace /dev/sdX with your USB device)
just create-bootable-usb nixos-preconfigured-installer.iso /dev/sdX
```

The **preconfigured installer** includes:

- Interactive template selection during installation
- All host configurations (desktop, laptop, server, VM)
- Automated deployment wizard
- Development tools pre-installed

**[Complete ISO Creation Guide →](docs/ISO-CREATION.md)**

### New NixOS Users (Automated Setup)

For first-time users or quick deployments, use our automated setup scripts:

```bash
# Clone this template
git clone <your-repo> my-nixos-config
cd my-nixos-config

# Check if your system is ready
./scripts/check-prerequisites.sh

# Option 1: Quick setup with smart defaults (recommended for beginners)
./scripts/quick-setup.sh

# Option 2: Full interactive setup with all options
./scripts/nixos-setup.sh
```

The setup scripts will:

- Detect your hardware and VM environment
- Generate appropriate configurations
- Guide you through customization options
- Test and deploy the configuration
- Provide next steps and usage instructions

**[See detailed setup guide →](docs/SETUP.md)**

### Advanced Users (Manual Setup)

For users who prefer manual configuration:

```bash
# Clone this template
nix flake new my-nixos-config --template github:yourusername/nixos-template
cd my-nixos-config

# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hosts/$(hostname)/hardware-configuration.nix

# Customize your configuration
# Edit hosts/$(hostname)/configuration.nix and home.nix

# Build and switch
just switch

# Update flake inputs
just update-switch
```

## Project Structure

```text
nixos-config/
├── flake.nix                 # Main flake configuration
├── flake.lock               # Reproducible input locks
├──
├── lib/                     # Custom utility functions
│   ├── default.nix         # Library exports
│   └── mkHost.nix          # Host builder utility
│
├── modules/                 # Reusable NixOS modules
│   ├── core/               # Essential system modules
│   │   ├── boot.nix        # Boot configuration
│   │   ├── locale.nix      # Localization
│   │   ├── networking.nix  # Network configuration
│   │   ├── nix.nix         # Nix settings
│   │   ├── security.nix    # Security settings
│   │   └── users.nix       # User management
│   ├── desktop/            # Desktop environment modules
│   │   ├── gnome.nix       # GNOME desktop
│   │   ├── audio.nix       # Audio configuration
│   │   └── fonts.nix       # Font configuration
│   ├── development/        # Development tool modules
│   │   └── git.nix         # Git configuration
│   ├── hardware/           # Hardware-specific modules
│   │   └── gpu/            # GPU configurations
│   │       ├── amd.nix     # AMD GPU support
│   │       ├── nvidia.nix  # NVIDIA GPU support
│   │       ├── intel.nix   # Intel GPU support
│   │       └── detection.nix # Auto-detection
│   ├── services/           # Service modules
│   ├── virtualization/     # VM and container modules
│   └── installer/          # Custom installer ISO modules
│
├── hosts/                  # Per-host configurations
│   ├── common.nix          # Shared host configuration
│   ├── desktop-template/   # Desktop template configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── home.nix        # Home Manager config
│   ├── laptop-template/    # Laptop template configuration
│   ├── server-template/    # Server template configuration (AI/compute)
│   ├── qemu-vm/            # QEMU/KVM virtual machine
│   ├── virtualbox-vm/      # VirtualBox VM configuration
│   ├── microvm/            # Minimal MicroVM configuration
│   ├── desktop-test/       # VM desktop testing environment
│   └── installer-isos/     # Custom installer ISO configurations
│
├── home/                   # Home Manager configurations
│   ├── common/             # Shared configurations used by all roles
│   │   ├── base.nix        # Universal settings (shell, XDG, basic programs)
│   │   ├── git.nix         # Common git configuration with user overrides
│   │   └── packages/       # Package groups (essential, development, desktop)
│   ├── roles/              # Role-based configurations
│   │   ├── developer.nix   # Full development environment
│   │   ├── gamer.nix      # Gaming setup with performance tools
│   │   ├── server-admin.nix # Server administration tools
│   │   └── minimal.nix    # Bare minimum for resource-constrained systems
│   ├── profiles/           # Desktop environment profiles
│   │   ├── gnome.nix      # GNOME-specific configuration
│   │   ├── kde.nix        # KDE-specific configuration
│   │   └── headless.nix   # No GUI configuration for servers
│   └── users/             # Legacy user configurations (deprecated)
│
├── overlays/              # Package overlays
├── pkgs/                  # Custom packages
├── secrets/               # Encrypted secrets
├── scripts/               # Management and setup scripts
│   ├── nixos-setup.sh     # Full interactive setup wizard
│   ├── quick-setup.sh     # Quick setup with smart defaults
│   ├── try-nixos.sh       # Try NixOS on non-NixOS systems
│   ├── check-prerequisites.sh # System validation
│   ├── detect-vm.sh       # VM environment detection
│   ├── setup-agenix.sh    # Secrets management setup
│   └── rebuild.sh         # Rebuild script
├── docs/                   # Documentation
│   ├── SETUP.md           # Comprehensive setup guide
│   ├── NON-NIXOS-USAGE.md # Guide for non-NixOS users
│   ├── ISO-CREATION.md    # Custom installer ISO guide
│   ├── FEATURES-OVERVIEW.md # Complete features documentation
│   ├── VM-SUPPORT.md      # Virtual machine documentation
│   └── GPU-CONFIGURATION.md # GPU setup guide
├──
├── justfile              # Task runner with convenient commands
└── README.md             # This file
```

## Available Commands

### Using just (Recommended)

```bash
just switch           # Build and switch to new configuration
just test            # Test configuration without switching
just boot            # Build configuration for next boot
just update          # Update flake inputs
just update-switch   # Update flake inputs and rebuild
just check           # Check flake for errors
just fmt             # Format Nix files
just clean           # Clean old generations and result symlinks
just clean-results   # Remove result symlinks (from nix build commands)
just shell           # Enter development shell
just info            # Show system information

# Host-specific commands
just switch desktop-template   # Switch configuration for 'desktop-template' host
just test server-template     # Test configuration for 'server-template' host

# VM and Testing Commands
just build-vm-image desktop-test    # Build VM image for desktop testing
just init-vm myhost qemu           # Initialize VM configuration
just list-vms                      # Show available VM configurations
just list-desktops                 # Show available desktop environments
just test-vm myhost                # Test VM configuration

#  ISO Creation Commands
just list-isos                     # List available ISO types with features
just build-iso-preconfigured       # Build preconfigured installer (recommended)
just build-iso-minimal             # Build minimal CLI installer (~800MB)
just build-iso-desktop             # Build desktop installer with GNOME (~2.5GB)
just build-all-isos                # Build all installer types
just test-iso preconfigured        # Test ISO configuration without building
just create-bootable-usb FILE DEV  # Create bootable USB from ISO
just iso-workflow                  # Complete ISO creation workflow guide

# Desktop Environment Commands
just test-desktop gnome myhost     # Test specific desktop configuration
just list-users                    # Show available user templates
just init-user myhost developer    # Initialize user configuration from template

# Utility commands
just init-host myhost              # Initialize new host configuration
just diff                          # Show configuration differences
just show-inputs                   # Show flake input versions
```

### Setup Scripts (For New Users)

```bash
# For non-NixOS users (Ubuntu, Fedora, Arch, etc.)
./scripts/try-nixos.sh

# Check system prerequisites (includes hardware detection)
./scripts/check-prerequisites.sh

# Quick automated setup (NixOS users)
./scripts/quick-setup.sh

# Full interactive setup wizard (NixOS users)
./scripts/nixos-setup.sh

# Hardware type detection
./scripts/detect-hardware.sh

# VM environment detection
./scripts/detect-vm.sh

# Setup secrets management
./scripts/setup-agenix.sh
```

### ISO Creation Workflow

```bash
# Complete ISO creation and deployment workflow
just iso-workflow                          # Step-by-step guide
just list-isos                            # Show all ISO types
just build-iso-preconfigured              # Build recommended installer
just create-bootable-usb nixos-preconfigured-installer.iso /dev/sdX
# Boot from USB → Select template → Automated installation
```

### Management Scripts

```bash
# Rebuild script with advanced options
./scripts/rebuild.sh                    # Basic switch
./scripts/rebuild.sh test              # Test mode
./scripts/rebuild.sh --host server     # Specific host
./scripts/rebuild.sh --update switch   # Update and switch
```

### Using Nix Directly

```bash
# Build specific host
sudo nixos-rebuild switch --flake .#hostname

# Update flake inputs
nix flake update

# Check flake
nix flake check

# Enter development shell
nix develop
```

## Module System

This configuration uses a modular approach where features are organized into reusable modules, providing a complete NixOS ecosystem from development to deployment.

## Complete NixOS Ecosystem

This template provides an end-to-end NixOS experience:

### **Development & Testing**

- **Non-NixOS Support**: Test on Ubuntu, Fedora, Arch, any Linux distribution
- **VM Testing**: Safe desktop environment testing without system changes
- **Live Development**: Edit configurations and test in VMs instantly
- **Multi-Platform**: Same configs work across different systems

### **Deployment Options**

- **Custom ISOs**: Build installer images with your configurations
- **Template Selection**: Interactive installer with pre-built templates
- **Automated Setup**: Skip manual NixOS configuration entirely
- **Bootable Media**: Create USB/DVD installers for any environment

### **Organizational Use**

- **Standardized Deployments**: Consistent configurations across teams
- **Educational Environments**: Pre-configured learning setups
- **Client Deployments**: Custom NixOS solutions for consulting
- **Development Teams**: Shared development environments

### **Full Workflow Coverage**

1. **Develop**: Create configurations using templates
1. **Test**: Validate in VMs on any Linux system
1. **Package**: Build custom installer ISOs
1. **Deploy**: Boot and install with template selection
1. **Maintain**: Update and redeploy as needed

### Enabling Modules

In your host configuration:

```nix
modules = {
  desktop = {
    gnome.enable = true;
    audio.enable = true;
    fonts.enable = true;
  };

  development = {
    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
    };
  };
};
```

### Creating Custom Modules

Add new modules in the `modules/` directory following the existing patterns.

## Home Manager Configuration

This template features a Home Manager structure that eliminates duplication and provides clear separation between common and host-specific settings.

### Role-Based Configuration System

Instead of duplicating configurations across hosts, use role-based imports:

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
  programs.zsh.shellAliases = {
    work = "cd ~/Work";
  };
}
```

### Available Roles

- **Developer** (`roles/developer.nix`) - Full development workstation with Zsh, Starship, Direnv, development tools
- **Gamer** (`roles/gamer.nix`) - Gaming setup with Steam, MangoHud, Discord, performance monitoring
- **Server Admin** (`roles/server-admin.nix`) - System monitoring, network tools, containers, Tmux configuration
- **Minimal** (`roles/minimal.nix`) - Bare minimum for resource-constrained environments

### Available Profiles

- **GNOME** (`profiles/gnome.nix`) - GNOME desktop environment configuration
- **KDE** (`profiles/kde.nix`) - KDE Plasma desktop environment configuration
- **Headless** (`profiles/headless.nix`) - No GUI, terminal-only configuration

### Benefits

- **No Duplication** - Common configurations shared across all hosts
- **Clear Intent** - Role and profile imports make purpose obvious
- **Easy Maintenance** - Update once, apply everywhere
- **Flexible Override** - Host-specific customizations still possible
- **Type Safety** - Fully typed with NixOS module system

See `home/README.md` for detailed usage examples and migration guide.

## GPU Configuration

This template includes comprehensive GPU support for AMD, NVIDIA, and Intel graphics cards with optimization profiles for different workloads.

### GPU Setup

GPU modules must be manually enabled in your host configuration. The system provides detection tools but cannot automatically configure drivers during evaluation:

```nix
# In your host configuration - you must manually enable your GPU type
modules.hardware.gpu = {
  # Optional: Enable detection service that logs found GPUs to /run/gpu-info
  autoDetect = true;
  profile = "desktop";  # desktop, gaming, ai-compute, server-compute

  # You must manually enable your specific GPU:
  # nvidia.enable = true;  # For NVIDIA GPUs
  # amd.enable = true;     # For AMD GPUs
  # intel.enable = true;   # For Intel GPUs
};
```

### Detailed GPU Configuration Examples

Enable and configure your specific GPU type:

```nix
# AMD GPU (desktop/gaming)
modules.hardware.gpu = {
  profile = "gaming";
  amd = {
    enable = true;
    gaming.enable = true;
  };
};

# NVIDIA GPU (AI/compute server)
modules.hardware.gpu = {
  profile = "ai-compute";
  nvidia = {
    enable = true;
    compute = {
      cuda = true;
      cudnn = true;
      containers = true;  # Docker GPU support
    };
  };
};

# Intel integrated graphics
modules.hardware.gpu = {
  profile = "desktop";
  intel = {
    enable = true;
    desktop.vaapi = true;
  };
};
```

### Supported Features

- **AMD**: ROCm for AI, Vulkan gaming, hardware acceleration
- **NVIDIA**: CUDA/cuDNN for AI, RTX features, PRIME for laptops
- **Intel**: VA-API acceleration, Arc/Xe compute, OneAPI

See [GPU Configuration Guide](docs/GPU-CONFIGURATION.md) for detailed setup instructions.

## Virtual Machine Testing

This template includes comprehensive VM testing capabilities for safe development and desktop environment testing.

### Quick VM Testing

```bash
# Build and run the desktop testing VM
just build-vm-image desktop-test
./result/bin/run-desktop-test-vm

# Login with: username=vm-user, password=nixos
```

### Available VM Configurations

- **desktop-test** - Full GNOME desktop for testing (with boot reliability fixes)
- **qemu-vm** - Basic QEMU VM configuration
- **virtualbox-vm** - VirtualBox-optimized configuration
- **microvm** - Minimal lightweight VM

### VM Management Commands

```bash
# List all VM configurations and their features
just list-vms

# Initialize new VM configuration
just init-vm myhost-vm qemu              # Auto-detect VM type
just init-vm myhost-vm virtualbox        # Specific VM type

# Build VM images
just build-vm-image desktop-test         # Build desktop testing VM
just build-vm-image qemu-vm              # Build basic QEMU VM

# Test VM configurations
just test-vm desktop-test                # Test without building

# Create QEMU disk and boot setup
just create-vm myhost-vm 4096 20G        # 4GB RAM, 20GB disk
```

### Desktop Environment Testing

Test different desktop environments safely in VMs:

```bash
# List available desktop environments
just list-desktops
# Available: gnome, kde, hyprland, niri

# Test specific desktop in VM
just test-desktop gnome desktop-test
just test-desktop kde my-kde-vm
just test-desktop hyprland my-hyprland-vm

# Build desktop-specific VMs
just init-vm gnome-test qemu
# Edit hosts/gnome-test/configuration.nix:
#   modules.desktop.gnome.enable = true;
just build-vm-image gnome-test
```

### VM Features & Optimizations

The VMs include:

**Boot Reliability** - Fixed systemd service conflicts and AppArmor issues\
**Desktop Ready** - Full GNOME with Wayland, optimized for VM performance\
**Guest Optimizations** - VirtIO drivers, shared clipboard, graphics acceleration\
**Development Tools** - Git, VS Code, terminal applications\
**SSH Access** - Port 22 open for remote development\
**User Environment** - Home Manager configuration with dotfiles\
**Network Access** - NAT networking with internet connectivity

### VM Troubleshooting

If VM boot hangs or fails:

```bash
# Check VM process
ps aux | grep qemu

# Kill stuck VM
pkill -f "qemu.*yourvm"

# Rebuild with latest fixes
just build-vm-image desktop-test

# Run with more verbose output
./result/bin/run-desktop-test-vm -serial stdio
```

### Advanced VM Usage

```bash
# Run VM in background with VNC
./result/bin/run-desktop-test-vm -vnc :1 -daemonize
# Connect to localhost:5901 with VNC viewer

# Run with more memory and cores
./result/bin/run-desktop-test-vm -m 4096 -smp 4

# Network port forwarding (SSH)
./result/bin/run-desktop-test-vm -netdev user,id=net0,hostfwd=tcp::2222-:22
# Then: ssh vm-user@localhost -p 2222
```

See [VM Documentation](docs/VM-SUPPORT.md) for detailed VM configuration and troubleshooting.

## Custom NixOS Installer ISOs

Transform this template into bootable NixOS installer ISOs with preconfigured settings and interactive template selection. Perfect for organizational deployments, development environments, and educational use.

### Quick ISO Creation

```bash
# List available installer types and their features
just list-isos

# Build preconfigured installer (RECOMMENDED)
just build-iso-preconfigured

# Build minimal CLI installer (lightweight for servers)
just build-iso-minimal

# Build desktop installer (GNOME for newcomers)
just build-iso-desktop

# Build all installer types at once
just build-all-isos
```

### Available ISO Types

| Type              | Size   | Interface       | Best For                | Key Features                               |
| ----------------- | ------ | --------------- | ----------------------- | ------------------------------------------ |
| **Minimal**       | ~800MB | CLI Only        | Servers, Experts        | SSH access, essential tools, lightweight   |
| **Desktop**       | ~2.5GB | GNOME Desktop   | Newcomers, Graphics     | Firefox, GParted, visual tools, auto-login |
| **Preconfigured** | ~1.5GB | Interactive CLI | Quick Deploy, Templates | All templates, wizard, dev tools           |

### Preconfigured Installer Features

The **preconfigured installer** is the star feature - it includes:

**Interactive Template Selection**

- Browse all available host configurations during installation
- Choose from desktop, laptop, server, or VM templates
- Preview template features and descriptions

**Automated Installation Wizard**

- Partition disks and select templates in guided workflow
- Automatic configuration deployment
- Skip manual NixOS configuration editing

**Development Environment Ready**

- Git, just, editors, and development tools pre-installed
- All templates available at `/etc/nixos-template/`
- Quick configuration customization workflow

### Creating Bootable Media

```bash
# Check available USB devices
lsblk

# Create bootable USB (DESTRUCTIVE - erases USB drive)
just create-bootable-usb nixos-preconfigured-installer.iso /dev/sdX

# Get complete workflow guide
just iso-workflow
```

### Installation Workflow

#### Preconfigured Installer (Recommended)

1. **Boot from USB/DVD** - Installer launches automatically
1. **Network Setup** - Connect to WiFi if needed
1. **Interactive Menu** - Select from available templates
1. **Partition Disks** - Standard disk partitioning
1. **Template Deployment** - Automatic configuration setup
1. **Installation** - `nixos-install` runs automatically
1. **Reboot** - Boot into your fully configured NixOS system

#### Traditional Installers (Minimal/Desktop)

1. **Boot from USB/DVD**
1. **Network Setup** (if needed)
1. **Manual Installation** - Follow standard NixOS installation process
1. **Browse Templates** - Templates available for reference at `/etc/nixos-template/`

### Customization Options

```bash
# Test ISO configuration without building
just test-iso preconfigured

# Customize installer modules
nano modules/installer/preconfigured-installer.nix

# Add your own packages to installers
# Edit hosts/installer-isos/*/configuration.nix
```

### Use Cases

- **Organizations**: Deploy standardized NixOS configurations
- **Development Teams**: Share development environment setups
- **Educational**: Distribute pre-configured learning environments
- **Personal**: Quick deployment of personal configurations
- **Consulting**: Client-specific NixOS deployments

See [ISO Creation Guide](docs/ISO-CREATION.md) for detailed instructions, customization options, and advanced usage patterns.

## WSL2 Support

This template provides comprehensive Windows Subsystem for Linux 2 (WSL2) support with full NixOS integration, enabling you to run a complete NixOS development environment directly on Windows with seamless Windows interoperability.

### Quick WSL2 Setup

```bash
# 1. Clone the template on Windows (PowerShell as Administrator)
git clone https://github.com/yourusername/nixos-template
cd nixos-template

# 2. Run the automated installation
.\scripts\install-wsl2.ps1

# 3. Start NixOS WSL2
wsl -d NixOS-Template
```

### Manual WSL2 Installation

```bash
# Build WSL2 distribution tarball
just build-wsl2-archive

# Import into WSL (from Windows PowerShell as Administrator)
wsl --import NixOS-Template C:\WSL\NixOS .\result\tarball\nixos-system-x86_64-linux.tar.xz

# Start WSL2 instance
wsl -d NixOS-Template

# Initial system configuration
sudo passwd nixos  # Set user password
sudo nixos-rebuild switch --flake /etc/nixos#wsl2-template
```

### WSL2 Complete Feature Set

**Windows Integration**
- **Seamless File Access** - Windows drives mounted at `/mnt/c`, `/mnt/d` with proper permissions
- **Clipboard Sharing** - Bidirectional clipboard integration between Windows and WSL2
- **Application Launching** - Launch Windows apps from WSL2 command line (`code.exe`, `explorer.exe`)
- **PATH Integration** - Windows executables available in WSL2 PATH
- **Start Menu Integration** - Linux GUI applications appear in Windows Start Menu

**Performance Optimizations**
- **Memory Management** - Optimized swappiness and caching for WSL2 environment
- **Network Stack** - BBR congestion control and optimized TCP settings
- **Filesystem Performance** - tmpfs for `/tmp`, optimized mount options for Windows drives
- **Service Optimization** - Disabled unnecessary services, faster boot times

**Development Environment**
- **Modern Shell** - Zsh with Oh-My-Zsh, Starship prompt, and WSL2-specific functions
- **Development Tools** - Node.js, Python, Rust, Go, with WSL2 performance optimizations
- **Container Support** - Podman configured for Windows integration
- **Editor Integration** - Pre-configured for VS Code with WSL2 extension support

**System Integration**
- **Systemd Support** - Full systemd functionality with WSL2 optimizations
- **SSH Server** - OpenSSH configured for remote development access
- **Audio Support** - PulseAudio configured for WSL2 audio forwarding
- **Graphics Support** - X11 forwarding and WSLg GUI application support

### WSL2-Specific Commands

```bash
# Build and test WSL2 configurations
just test-wsl2                    # Test system configuration
just build-wsl2-archive           # Build WSL2 distribution tarball
just build-wsl2-home             # Test Home Manager configuration
just wsl2-install-help           # Show installation instructions

# WSL2 system utilities (available in WSL2 shell)
wsl-info                         # Comprehensive system information
wsl-network-info                 # Network configuration details
wsl-performance-tune             # Performance optimization script
wsl-open .                       # Open directory in Windows Explorer
wsl-edit file.txt               # Edit file in VS Code

# Development environment helpers
dev-start                        # Start development servers
dev-stop                         # Stop development servers
dev-env-setup                    # Setup development directories
```

### Windows Integration Examples

**File System Integration**
```bash
# Navigate between Windows and WSL filesystems
cd /mnt/c/Users/YourName/Documents    # Access Windows files
wsl-open ~/Development                # Open WSL directory in Explorer
cp /mnt/c/file.txt ~/project/         # Copy from Windows to WSL
```

**Application Integration**
```bash
# Launch Windows applications from WSL2
explorer.exe .                        # Open current directory in Explorer
code.exe project/                     # Open project in VS Code
notepad.exe config.txt                # Edit file in Notepad
pwsh.exe                              # Launch PowerShell

# Development workflow
git clone https://github.com/user/repo.git
cd repo
code.exe .                            # Open in VS Code with WSL extension
npm run dev                           # Development server accessible from Windows
```

**Network and System Integration**
```bash
# Access development servers from Windows browser
# http://localhost:3000 automatically works

# System information and networking
wsl-network-info                      # Show WSL2 IP configuration
wsl-ports                            # List listening ports
host-ip                              # Get Windows host IP address
```

### WSL2 Development Workflow

**1. Initial Setup and Configuration**
```bash
# After installation, customize your environment
nano ~/.config/git/config            # Configure Git (or use wsl-edit)
dev-env-setup                        # Create development directories
```

**2. Optimal File Organization**
```bash
# For best performance, use WSL2 filesystem for development
mkdir -p ~/Development/projects/{web,api,mobile}
cd ~/Development/projects/web
git clone https://github.com/user/project.git

# Use Windows filesystem for large files or Windows-specific tools
ln -s /mnt/c/Tools ~/Tools            # Link to Windows tools
```

**3. Development Server Workflow**
```bash
cd ~/Development/projects/web/myproject
code.exe .                            # Opens in VS Code with WSL extension
npm install                           # Install dependencies in WSL2
npm run dev                           # Start development server

# Server automatically accessible from Windows:
# - http://localhost:3000 in Windows browser
# - Full hot-reload and debugging support
```

**4. Container Development**
```bash
# Podman configured for Windows integration
podman run -d -p 8080:80 --name webapp nginx
# Access from Windows: http://localhost:8080

# Docker Desktop integration (if installed)
docker run -d -p 9000:80 --name api myapi:latest
```

### WSL2 Module Architecture

The WSL2 implementation includes specialized modules:

- **`modules/wsl/interop.nix`** - Windows application integration and clipboard sharing
- **`modules/wsl/networking.nix`** - Network optimizations and firewall configuration
- **`modules/wsl/optimization.nix`** - Performance tuning for memory, filesystem, and services
- **`modules/wsl/systemd.nix`** - Systemd service optimizations for WSL2 environment

### Advanced WSL2 Configuration

**Custom Windows Integration**
```nix
# In your WSL2 host configuration
modules.wsl = {
  interop = {
    enable = true;
    windowsApps = true;      # Enable Windows app aliases
    clipboard = true;         # Bidirectional clipboard
    fileAssociations = true;  # Open files with Windows apps
  };
  
  networking = {
    enable = true;
    firewallConfig = "minimal";  # or "disabled" for development
    portForwarding = {
      web = 3000;
      api = 8080;
    };
  };
  
  optimization = {
    enable = true;
    memory.swappiness = 10;       # Lower swap usage
    filesystem.tmpfsSize = "4G";  # Larger /tmp for builds
    development.fastBuild = true; # Optimize for development
  };
};
```

**Performance Tuning**
```bash
# Available performance monitoring and tuning
wsl-performance-tune                   # System performance analysis
performance-monitor                    # Real-time performance monitoring
system-info                           # Comprehensive system information

# Windows-side WSL2 configuration (.wslconfig in Windows user directory)
# [wsl2]
# memory=8GB
# processors=4
# swap=2GB
```

### WSL2 Troubleshooting

**Common Issues and Solutions**
```bash
# WSL2 instance not starting
wsl --shutdown                         # Shutdown all WSL instances
wsl -d NixOS-Template                  # Restart specific instance

# Network connectivity issues
wsl-network-info                       # Check network configuration
sudo systemctl restart systemd-resolved

# Performance issues
wsl-performance-tune                   # Run performance diagnostics
wsl --shutdown && wsl -d NixOS-Template  # Restart WSL2

# Windows integration not working
sudo systemctl restart wsl-network-setup  # Restart WSL services
```

**System Maintenance**
```bash
# Regular maintenance tasks
sudo nix-collect-garbage -d            # Clean Nix store
just clean                            # Remove build artifacts
wsl --shutdown                         # Free memory (run from Windows)
```

**[Complete WSL2 Documentation →](docs/WSL2-CONFIGURATION.md)**

## Host Configurations

### Adding a New Host

1. Create a new directory under `hosts/`
1. Add `configuration.nix` and `hardware-configuration.nix`
1. Optional: Add `home.nix` for Home Manager configuration
1. Add the host to `flake.nix` nixosConfigurations

### Hardware Configuration

Generate hardware configuration for a new system:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```

## Secrets Management

This template includes SOPS for encrypted secrets management.

### Setup

1. Generate a key: `ssh-keygen -t ed25519 -f ~/.config/sops/age/keys.txt`
1. Configure `.sops.yaml` in the repository root
1. Create encrypted files: `sops secrets/example.yaml`

### Using Secrets

```nix
# In your configuration
sops.secrets."my-secret" = {
  sopsFile = ../secrets/secrets.yaml;
  owner = "user";
};
```

## Development Shell

This template includes modern Nix development tooling for a productive workflow:

### Quick Start

```bash
# Enter development shell
nix develop

# Format all code
just fmt
# or
nix fmt

# Setup pre-commit hooks
nix develop -c pre-commit install

# Use NixOS helper for system operations
nh os switch .  # Enhanced nixos-rebuild
nh home switch . # Enhanced home-manager
```

### Modern Development Tools

The development environment provides:

**Code Quality & Formatting**

- **treefmt-nix** - Multi-language code formatting (Nix, Shell, Markdown, YAML, JSON)
- **git-hooks.nix** - Pre-commit hooks with deadnix, statix, nixpkgs-fmt
- **Automatic formatting** - Format entire codebase with `just fmt`

**Enhanced System Management**

- **nh (Nix Helper)** - Modern replacement for nixos-rebuild and home-manager
- **Enhanced rebuild commands** - Better output, progress indication, error handling
- **System state management** - Track generations and rollback easily

**Development Utilities**

- **Nix LSP tools** - Language server support for editors
- **System utilities** - Git, just, direnv, and essential tools
- **Secrets management** - SOPS/agenix integration
- **Documentation tools** - Markdown processing and validation

### Development Workflow

1. **Setup**: `nix develop` to enter the environment
2. **Code**: Edit configurations with full LSP support
3. **Format**: `just fmt` runs treefmt on all code
4. **Commit**: Pre-commit hooks ensure code quality
5. **Deploy**: `nh os switch .` for enhanced rebuilds
6. **Test**: `just test` validates without switching

## Best Practices

### Configuration Management

1. **Keep modules focused** - Each module should handle one concern
1. **Use lib.mkDefault** - Allow easy overriding in host configs
1. **Document your modules** - Add descriptions to module options
1. **Test changes** - Use `make test` before `make switch`

### Security

1. **Review secrets** - Never commit unencrypted secrets
1. **Update regularly** - Keep system and inputs updated
1. **Minimal permissions** - Only enable needed services
1. **Backup configurations** - Keep your configuration in version control

### Performance

1. **Use binary caches** - Configure trusted substituters
1. **Enable auto-optimization** - Let Nix optimize the store
1. **Regular cleanup** - Use `make clean` periodically

## Validation & CI/CD

This template maintains **100% green CI status** with comprehensive validation to ensure reliability and compatibility:

### Multi-Level Validation

- **Syntax Validation**: All Nix files checked for correct syntax
- **Build Evaluation**: Templates evaluate without hardware dependencies
- **VM Testing**: Configurations build actual bootable VMs
- **ISO Validation**: Custom installer ISOs build and configure correctly
- **Module Validation**: All modules load correctly with proper dependencies
- **Script Testing**: Management scripts validated for functionality
- **Flake Validation**: Complete flake dependency resolution

### GitHub Actions CI (100% Passing)

Our comprehensive CI pipeline runs on every commit:

```bash
# Run validation locally (same as CI)
./scripts/validate-templates.sh standard

# Quick syntax-only check
./scripts/validate-templates.sh minimal

# Full validation including VM builds
./scripts/validate-templates.sh full
```

### NixOS 25.05 Compatibility

All configurations are updated for the latest NixOS:

- Modern option syntax (no deprecated warnings)
- Updated module system patterns
- Latest GPU driver configurations
- Current Home Manager integration
- Fixed podman system-generators conflicts
- Updated hardware.graphics options (replaced hardware.opengl)

## Troubleshooting

### Common Issues & Solutions

1. **Build failures**:

   ```bash
   nix flake check          # Check for syntax errors
   just validate            # Run full validation suite
   ```

1. **VM boot hangs**:

   ```bash
   just build-vm-image desktop-test    # Use latest boot fixes
   pkill -f qemu                       # Kill stuck VMs
   ```

1. **ISO creation issues**:

   ```bash
   just test-iso minimal               # Test without building
   just list-isos                      # Check available types
   nix-collect-garbage -d              # Free up disk space
   ```

1. **Hardware issues**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

1. **Annoying result symlinks**:

   ```bash
   just clean-results                   # Remove result symlinks from nix build
   just clean                          # Clean everything including result symlinks
   ```

1. **Module conflicts**: Check for conflicting options using `lib.mkForce`

1. **Permission errors**: Ensure user is in wheel group

   ```bash
   sudo usermod -a -G wheel $USER
   ```

1. **Flake lock issues**:

   ```bash
   nix flake update         # Update all inputs
   git add flake.lock       # Commit lock changes
   ```

1. **Bootable USB creation**:

   ```bash
   lsblk                    # Verify USB device path
   sudo umount /dev/sdX*    # Unmount before writing
   ```

### Getting Help

1. Check the [NixOS Manual](https://nixos.org/manual/nixos/stable/)
1. Browse [NixOS Options](https://search.nixos.org/options)
1. Visit the [NixOS Discourse](https://discourse.nixos.org/)
1. Join the [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)

## Contributing

1. Fork the repository
1. Create a feature branch
1. Make your changes
1. Test thoroughly
1. Submit a pull request

## License

This configuration template is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
