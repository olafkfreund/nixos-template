# NixOS Template Setup Guide

This NixOS template includes comprehensive setup scripts to help new users get up and running quickly with a fully configured NixOS system.

## Quick Start

For new NixOS users who want a guided setup experience:

```bash
# 1. Clone the template
git clone <your-template-repo> my-nixos-config
cd my-nixos-config

# 2. Run prerequisite checks
./scripts/check-prerequisites.sh

# 3. Choose your setup method:

# Option A: Quick setup with smart defaults
./scripts/quick-setup.sh

# Option B: Full interactive setup
./scripts/nixos-setup.sh
```

## Setup Scripts Overview

### 1. Prerequisites Checker (`check-prerequisites.sh`)

Validates your system before attempting configuration:

- **NixOS Environment**: Confirms you're running on NixOS
- **System Privileges**: Checks for root/sudo access
- **Nix Tools**: Validates all required Nix tools are available
- **System Resources**: Checks memory, disk space, and CPU
- **Network Connectivity**: Tests internet and NixOS channels
- **Hardware Support**: Detects system architecture and capabilities

**Usage:**

```bash
./scripts/check-prerequisites.sh
```

**What it checks:**

- NixOS version compatibility (23.11+)
- Nix flakes support
- Available system resources (memory, disk, CPU)
- Network connectivity to GitHub and NixOS channels
- Hardware virtualization capabilities
- Graphics hardware detection

### 2. Quick Setup (`quick-setup.sh`)

Minimal interaction setup with sensible defaults:

- **Auto-detection**: Automatically detects VM environment and hardware
- **Smart Defaults**: Chooses appropriate desktop environment based on resources
- **Fast Configuration**: Generates working config in minutes
- **Basic Customization**: Hostname, username, and desktop environment

**Best for:**

- First-time NixOS users
- Testing the template quickly
- VM deployments
- Getting a working system fast

**Features:**

- Automatic VM type detection (QEMU, VirtualBox, VMware, Hyper-V)
- Memory-based desktop recommendation (XFCE for <4GB, GNOME for >8GB)
- Hardware configuration generation
- Basic development tools inclusion
- SSH server setup with secure defaults

### 3. Full Interactive Setup (`nixos-setup.sh`)

Comprehensive guided setup with full customization:

- **Interactive Wizard**: Step-by-step configuration process
- **Feature Selection**: Choose exactly what you want
- **Template System**: Select from predefined user templates
- **Advanced Options**: Detailed customization of all aspects
- **Validation**: Comprehensive testing before deployment

**Best for:**

- Users who want full control
- Production deployments
- Complex configurations
- Learning NixOS configuration

**Features:**

- Multiple user templates (basic, developer, gamer, minimal, server)
- Desktop environment selection with preview
- Development language selection
- Gaming optimization options
- Virtualization and container setup
- Secrets management configuration
- Network and security settings

### 4. VM Detection (`detect-vm.sh`)

Specialized script for virtual machine environments:

- **Multi-method Detection**: Uses systemd, DMI, PCI, and kernel modules
- **Platform Recommendations**: Specific optimizations for each VM type
- **Confidence Scoring**: Reliability rating for detection results
- **Optimization Suggestions**: Performance and usability improvements

**Supported Platforms:**

- QEMU/KVM with VirtIO optimizations
- VirtualBox with Guest Additions
- VMware with VMware Tools
- Microsoft Hyper-V with Integration Services
- Xen paravirtualization

## Step-by-Step Setup Process

### For New NixOS Installations

1. **Boot NixOS Live ISO**
   - Download latest NixOS ISO
   - Boot from USB/DVD
   - Connect to internet

2. **Partition and Format Disks**

   ```bash
   # Example for UEFI systems
   sudo parted /dev/sda -- mklabel gpt
   sudo parted /dev/sda -- mkpart root ext4 512MB 100%
   sudo parted /dev/sda -- mkpart ESP fat32 1MB 512MB
   sudo parted /dev/sda -- set 2 esp on

   sudo mkfs.ext4 -L nixos /dev/sda1
   sudo mkfs.fat -F 32 -n boot /dev/sda2

   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mkdir -p /mnt/boot
   sudo mount /dev/disk/by-label/boot /mnt/boot
   ```

3. **Setup Template**

   ```bash
   cd /mnt
   sudo git clone <your-repo> nixos-config
   cd nixos-config
   sudo ./scripts/check-prerequisites.sh
   sudo ./scripts/nixos-setup.sh
   ```

4. **Install NixOS**

   ```bash
   # The setup script will guide you through installation
   # It will handle nixos-install automatically
   ```

### For Existing NixOS Systems

1. **Clone Template**

   ```bash
   git clone <your-repo> ~/.config/nixos-template
   cd ~/.config/nixos-template
   ```

2. **Check Prerequisites**

   ```bash
   ./scripts/check-prerequisites.sh
   ```

3. **Run Setup**

   ```bash
   # Quick setup
   ./scripts/quick-setup.sh

   # Or full setup
   ./scripts/nixos-setup.sh
   ```

4. **Apply Configuration**

   ```bash
   # Generated configuration will be tested and applied automatically
   # Or manually apply later:
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

## Configuration Templates

### User Templates

The template system provides pre-configured user environments:

#### Basic (`user`)

- Essential applications (Firefox, file manager, text editor)
- Basic development tools (git, vim)
- Standard desktop experience
- Suitable for general computing tasks

#### Developer (`developer`)

- Multiple programming languages (Python, Rust, Go, JavaScript)
- Advanced editors (VSCode, Neovim) with LSP
- Development tools (Docker/Podman, Git, databases)
- Terminal enhancements (fish shell, starship prompt)

#### Gamer (`gamer`)

- Steam with Proton-GE and optimizations
- Gaming tools (GameMode, MangoHud)
- Discord and multimedia applications
- Performance-optimized kernel parameters

#### Minimal (`minimal`)

- Lightweight applications only
- Resource-efficient choices
- Essential system tools
- Suitable for older hardware or VMs

#### Server (`server`)

- Server administration tools
- System monitoring (htop, iotop, nethogs)
- Network utilities
- No desktop environment

### Desktop Environments

#### GNOME

- Modern Wayland-first desktop
- Integrated applications suite
- Touch-friendly interface
- Good hardware acceleration support

#### KDE Plasma 6

- Highly customizable desktop
- Rich feature set
- Traditional desktop paradigm
- Excellent multi-monitor support

#### Hyprland

- Tiling window manager
- Wayland native
- Highly customizable
- Great for developers and power users

#### Niri

- Innovative scrollable tiling
- Wayland compositor
- Unique workflow approach
- Modern and efficient

## Advanced Features

### Virtual Machine Optimization

The template automatically detects and optimizes for VM environments:

- **QEMU/KVM**: VirtIO drivers, SPICE guest agent, 9P file sharing
- **VirtualBox**: Guest Additions, shared folders, clipboard sync
- **VMware**: Open VM Tools, enhanced graphics, Unity mode
- **Hyper-V**: Integration Services, Enhanced Session Mode

### Secrets Management

Integrated agenix support for secure secret management:

- Age-based encryption
- Per-secret permissions and ownership
- Multiple identity sources
- Template-based secret configuration

### Container Support

Built-in containerization with Podman:

- Rootless containers by default
- Docker compatibility
- Advanced networking
- Compose support

### Gaming Optimizations

When gaming template is selected:

- Steam with Proton-GE for Windows games
- GameMode for CPU scheduling optimization
- MangoHud for performance monitoring
- Optimized kernel parameters for gaming

## Troubleshooting

### Common Issues

**Script Permission Denied**

```bash
chmod +x scripts/*.sh
```

**Prerequisites Check Fails**

- Ensure you're running on NixOS
- Check internet connectivity
- Verify sufficient disk space (>10GB recommended)

**Configuration Build Fails**

- Check syntax with: `just validate`
- Review error messages for specific issues
- Ensure all required inputs were provided

**VM Detection Issues**

```bash
# Manual VM detection
systemd-detect-virt
cat /sys/class/dmi/id/product_name
```

**Network Configuration Problems**

- Check interface names: `ip link show`
- Verify NetworkManager status: `systemctl status NetworkManager`
- Test connectivity: `ping 8.8.8.8`

### Getting Help

1. **Check Logs**

   ```bash
   journalctl -xeu nixos-rebuild
   ```

2. **Validate Configuration**

   ```bash
   just validate
   nixos-rebuild dry-run --flake .#hostname
   ```

3. **Test Without Applying**

   ```bash
   just test hostname
   ```

4. **Restore Previous Generation**

   ```bash
   sudo nixos-rebuild switch --rollback
   ```

### Manual Configuration

If automated setup doesn't meet your needs:

1. **Copy Example Configuration**

   ```bash
   cp -r hosts/example-desktop hosts/my-host
   ```

2. **Customize Configuration**
   - Edit `hosts/my-host/configuration.nix`
   - Update `hosts/my-host/home.nix`
   - Generate hardware config: `sudo nixos-generate-config --show-hardware-config > hosts/my-host/hardware-configuration.nix`

3. **Add to Flake**

   ```nix
   # In flake.nix
   nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
     inherit system;
     modules = [ ./hosts/my-host ];
     specialArgs = { inherit inputs outputs; };
   };
   ```

4. **Build and Switch**

   ```bash
   just switch my-host
   ```

## Next Steps

After successful setup:

1. **Customize Your Configuration**
   - Explore `hosts/your-hostname/` directory
   - Modify applications and settings
   - Add custom modules

2. **Learn NixOS**
   - Read the NixOS manual: <https://nixos.org/manual/nixos/stable/>
   - Explore Nix language: <https://nix.dev/>
   - Join the community: <https://discourse.nixos.org/>

3. **Keep Updated**

   ```bash
   just update        # Update flake inputs
   just switch        # Apply updates
   ```

4. **Backup Your Configuration**
   - Commit changes to git
   - Consider hosting on GitHub/GitLab
   - Document custom modifications

This setup system makes NixOS accessible to new users while providing the flexibility and power that experienced users expect.
