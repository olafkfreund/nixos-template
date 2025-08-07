# NixOS ISO Creation Guide

This guide shows how to create custom NixOS installer ISOs with preconfigured settings and templates.

## Overview

This template provides three types of NixOS installer ISOs:

1. **Minimal Installer** - Lightweight command-line installer (~800MB)
1. **Desktop Installer** - GNOME desktop installer (~2.5GB)
1. **Preconfigured Installer** - Template-enabled installer with all configurations (~1.5GB)

## Quick Start

```bash
# See available ISO types
just list-isos

# Build minimal installer
just build-iso-minimal

# Build desktop installer
just build-iso-desktop

# Build preconfigured installer (recommended)
just build-iso-preconfigured

# Build all ISO types
just build-all-isos
```

## ISO Types Explained

### 1. Minimal Installer

**Best for:** Server installations, experienced users, low bandwidth

```bash
just build-iso-minimal
```

**Features:**

- Lightweight (~800MB)
- Command-line interface only
- SSH access enabled (password: `nixos`)
- Essential tools: nano, vim, git, wget, curl
- Hardware detection tools
- Network configuration tools
- Perfect for headless server installs

**Login:** `root` / `nixos`

### 2. Desktop Installer

**Best for:** Desktop installations, newcomers, graphical preference

```bash
just build-iso-desktop
```

**Features:**

- Full GNOME desktop environment (~2.5GB)
- Firefox browser for accessing documentation
- GParted for disk partitioning
- Visual file manager (Nautilus)
- Auto-login to desktop environment
- All minimal installer features plus GUI tools
- Auto-start installer information

**Login:** `installer` / `installer` (desktop user) or `root` / `nixos`

### 3. Preconfigured Installer ⭐ **Recommended**

**Best for:** Quick deployment, template-based installations, development

```bash
just build-iso-preconfigured
```

**Features:**

- Interactive installer with template selection (~1.5GB)
- All configuration templates included
- Quick installation wizard
- Development tools: git, just, editors
- Smart hardware detection and configuration
- One-click installation from templates
- Advanced shell with helpful aliases

**What's included:**

- Complete copy of this template repository
- All host configurations (desktop, laptop, server, VM)
- Interactive template browser
- Automated installation scripts
- Development environment setup

**Login:** `root` / `nixos`

## Building ISOs

### Prerequisites

- NixOS system or Nix package manager installed
- Sufficient disk space (2-4GB per ISO)
- Internet connection for downloading packages

### Basic Build Commands

```bash
# Build specific ISO type
just build-iso-minimal
just build-iso-desktop
just build-iso-preconfigured

# Build all types (takes longer but gives you all options)
just build-all-isos

# Test configuration without building
just test-iso minimal
just test-iso desktop
just test-iso preconfigured
```

### Advanced Build Options

```bash
# Build with custom settings
nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage

# Build for different architecture (if supported)
nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage --system aarch64-linux
```

## Using the ISOs

### Creating Bootable Media

#### USB Drive (Recommended)

```bash
# Find your USB device
lsblk

# Create bootable USB (DESTRUCTIVE - erases USB drive)
just create-bootable-usb nixos-minimal-installer.iso /dev/sdX

# Manual method
sudo dd if=result/iso/nixos-minimal-installer.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

#### DVD/CD

Burn the ISO using your preferred burning software (K3b, Brasero, etc.)

### Booting and Installation

1. **Boot from USB/DVD**
   - Insert bootable media
   - Boot from USB/DVD (may need BIOS/UEFI settings change)
   - Select NixOS installer from boot menu

1. **Network Setup** (if needed)

   ```bash
   # WiFi connection
   nmcli dev wifi connect "SSID" password "password"

   # Check connection
   ping google.com
   ```

1. **Installation Process**

#### Minimal/Desktop Installer

Follow standard NixOS installation:

```bash
# Partition disks
fdisk /dev/sdX

# Format partitions
mkfs.ext4 -L nixos /dev/sdX1
mkfs.fat -F 32 -n BOOT /dev/sdX2

# Mount filesystems
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot

# Generate configuration
nixos-generate-config --root /mnt

# Edit configuration
nano /mnt/etc/nixos/configuration.nix

# Install
nixos-install

# Reboot
reboot
```

#### Preconfigured Installer ⭐

The preconfigured installer provides an interactive experience:

1. **Automatic Start**: Installer script launches automatically
1. **Template Selection**: Choose from available configurations
1. **Quick Install**: Automated setup with chosen template
1. **Customization**: Templates can be modified before installation

**Interactive Installation:**

```bash
# The installer script starts automatically
# Or run manually:
/etc/installer/preconfigured-install.sh

# Browse available templates:
templates
ls /etc/nixos-template/hosts/

# Quick template installation:
# 1. Partition and mount your disk
# 2. Select template from installer menu
# 3. Installer copies configuration automatically
# 4. Run: nixos-install
```

## Customizing ISOs

### Creating Custom ISO Configurations

1. **Create new installer module:**

   ```bash
   # Copy existing module
   cp modules/installer/minimal-installer.nix modules/installer/my-installer.nix

   # Edit for your needs
   nano modules/installer/my-installer.nix
   ```

1. **Create host configuration:**

   ```bash
   # Create ISO host config
   mkdir -p hosts/installer-isos
   cp hosts/installer-isos/minimal-installer.nix hosts/installer-isos/my-installer.nix

   # Edit to use your module
   nano hosts/installer-isos/my-installer.nix
   ```

1. **Add to flake.nix:**

   ```nix
   my-installer = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = { inherit inputs outputs; };
     modules = [
       ./hosts/installer-isos/my-installer.nix
       {
         nixpkgs.config.allowUnfree = true;
       }
     ];
   };
   ```

1. **Build custom ISO:**

   ```bash
   nix build .#nixosConfigurations.my-installer.config.system.build.isoImage
   ```

### Customization Options

#### Adding Packages

```nix
# In your installer module
environment.systemPackages = with pkgs; [
  # Add your packages
  firefox
  libreoffice
  vscode
];
```

#### Custom Services

```nix
# Enable additional services
services.openssh.enable = true;
services.samba.enable = true;

# Add custom startup scripts
systemd.services.my-setup = {
  description = "My custom setup";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash /etc/setup-script.sh";
  };
};
```

#### Branding and Customization

```nix
# Custom ISO metadata
isoImage = {
  isoName = "my-custom-nixos.iso";
  volumeID = "MY_NIXOS";

  # Custom splash screen
  grubTheme = pkgs.nixos-grub2-theme;
};
```

## Tips and Best Practices

### Development Workflow

1. **Test in VM first:**

   ```bash
   # Build VM instead of ISO for testing
   just build-vm-image installer-minimal
   ./result/bin/run-installer-minimal-vm
   ```

1. **Iterative development:**

   ```bash
   # Quick syntax check
   just test-iso minimal

   # Build and test
   just build-iso-minimal
   # Test in VM or real hardware
   ```

1. **Version control:**

   ```bash
   # Tag stable ISO versions
   git tag iso-v1.0

   # Build reproducible ISOs
   nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage --no-link
   ```

### Performance Tips

- **Parallel builds:** Use `--max-jobs` to speed up builds
- **Binary cache:** Configure trusted substituters
- **Disk space:** Clean old builds with `nix-collect-garbage`
- **Network:** Use fast mirrors for downloads

### Security Considerations

- **Default passwords:** Change default passwords in production ISOs
- **SSH keys:** Consider embedding SSH keys for secure access
- **Package selection:** Only include necessary packages
- **Network security:** Configure firewalls appropriately

### Size Optimization

```nix
# Reduce ISO size
isoImage.squashfsCompression = "gzip -Xcompression-level 6";

# Minimize packages
environment.systemPackages = with pkgs; [
  # Only essential packages
];

# Remove unnecessary services
services.udisks2.enable = lib.mkForce false;
```

## Troubleshooting

### Common Issues

1. **Build failures:**

   ```bash
   # Check syntax
   nix flake check

   # Clean and retry
   nix-collect-garbage
   just build-iso-minimal
   ```

1. **ISO won't boot:**
   - Verify ISO integrity: `sha256sum result/iso/*.iso`
   - Check UEFI/BIOS boot settings
   - Try different USB creation method

1. **Network issues in installer:**

   ```bash
   # Check network interface
   ip link show

   # Manual network setup
   dhcpcd enp0s3
   ```

1. **Storage space:**

   ```bash
   # Check available space
   df -h

   # Clean Nix store
   nix-collect-garbage -d
   sudo nix-collect-garbage -d
   ```

### Getting Help

- **NixOS Manual:** https://nixos.org/manual/nixos/stable/
- **Installation Guide:** https://nixos.org/manual/nixos/stable/#ch-installation
- **Community:** https://discourse.nixos.org/
- **Matrix/Discord:** NixOS community channels

## Advanced Usage

### Automated Deployment

```bash
# Script for automated ISO creation and deployment
#!/usr/bin/env bash

# Build ISO
just build-iso-preconfigured

# Create bootable USB
USB_DEVICE="/dev/sdX"  # Change to your device
just create-bootable-usb nixos-preconfigured-installer.iso $USB_DEVICE

# Or upload to network location
rsync -av result/iso/*.iso user@server:/path/to/isos/
```

### Integration with CI/CD

```yaml
# GitHub Actions example
name: Build NixOS ISOs
on: [push, pull_request]

jobs:
  build-isos:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - name: Build ISOs
        run: |
          nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage
          nix build .#nixosConfigurations.installer-desktop.config.system.build.isoImage
          nix build .#nixosConfigurations.installer-preconfigured.config.system.build.isoImage
```

### Network Installation

```bash
# Create network-bootable installer
nix build .#nixosConfigurations.installer-minimal.config.system.build.netbootRamdisk
nix build .#nixosConfigurations.installer-minimal.config.system.build.kernel

# Setup PXE server (advanced topic)
# Copy kernel and initrd to TFTP server
# Configure DHCP for PXE boot
```

---

**Ready to create your custom NixOS installer ISO?** Start with the preconfigured installer for the best experience, or choose the minimal installer for lightweight deployments.
