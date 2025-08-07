# Using NixOS Template on Non-NixOS Systems

This guide shows how to use this NixOS configuration template on Ubuntu, Fedora, Arch Linux, and other Linux distributions to test NixOS in virtual machines.

## Overview

You can use this repository to:

- Test NixOS configurations in VMs without installing NixOS
- Try different desktop environments safely
- Learn NixOS before committing to a full installation
- Develop NixOS configurations on your existing Linux system

## Prerequisites

### 1. Install Nix Package Manager

The Nix package manager can be installed on any Linux distribution:

#### Quick Installation (Recommended)

```bash
# Install Nix with flakes support (single-user mode)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This installer from Determinate Systems includes flakes support by default.

#### Manual Installation

If you prefer the official installer:

```bash
# Install Nix (official installer)
curl -L https://nixos.org/nix/install | sh

# Enable flakes (required for this template)
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

After installation, restart your shell or run:

```bash
source ~/.nix-profile/etc/profile.d/nix.sh
```

### 2. Install Virtualization Support

You need KVM/QEMU for running NixOS VMs:

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
```

#### Fedora/RHEL/CentOS

```bash
sudo dnf install qemu-kvm libvirt virt-manager bridge-utils
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
sudo systemctl enable --now libvirtd
```

#### Arch Linux

```bash
sudo pacman -S qemu-base libvirt virt-manager bridge-utils
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
sudo systemctl enable --now libvirtd
```

#### OpenSUSE

```bash
sudo zypper install qemu-kvm libvirt virt-manager bridge-utils
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
sudo systemctl enable --now libvirtd
```

**Important**: Log out and log back in after adding yourself to groups.

### 3. Verify Installation

Check that everything is working:

```bash
# Test Nix
nix --version

# Test flakes support
nix flake --help

# Test KVM access (should show KVM acceleration available)
kvm-ok  # Ubuntu/Debian
# or
lsmod | grep kvm  # Other distros

# Test QEMU
qemu-system-x86_64 --version
```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/nixos-template.git
cd nixos-template
```

### 2. Build Your First NixOS VM

The template includes pre-configured VMs ready for testing:

```bash
# Build a desktop testing VM with GNOME
nix build .#nixosConfigurations.desktop-test.config.system.build.vm

# Run the VM
./result/bin/run-desktop-test-vm
```

Login credentials:

- **Username**: `vm-user`
- **Password**: `nixos`

### 3. Available VM Configurations

List available VMs:

```bash
# Show all available configurations
ls hosts/
```

Pre-built VMs include:

- **desktop-test** - Full GNOME desktop environment
- **qemu-vm** - Basic NixOS VM
- **virtualbox-vm** - VirtualBox-optimized VM
- **microvm** - Minimal lightweight VM

Build any VM:

```bash
# Build specific VM
nix build .#nixosConfigurations.VMNAME.config.system.build.vm

# Run it
./result/bin/run-VMNAME-vm
```

## Creating Custom VMs

### 1. Using Templates

Create a new VM configuration:

```bash
# Copy a template
cp -r hosts/desktop-test hosts/my-test-vm

# Edit configuration
nano hosts/my-test-vm/configuration.nix
```

### 2. Add to Flake

Add your new VM to `flake.nix`:

```nix
# In flake.nix nixosConfigurations
my-test-vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs outputs; };
  modules = [
    ./hosts/my-test-vm/configuration.nix
    home-manager.nixosModules.home-manager
    {
      location.latitude = 40.7128;
      location.longitude = -74.0060;
      nixpkgs.config.allowUnfree = true;
    }
  ];
};
```

### 3. Build and Test

```bash
# Build your custom VM
nix build .#nixosConfigurations.my-test-vm.config.system.build.vm

# Run it
./result/bin/run-my-test-vm-vm
```

## Desktop Environment Testing

Test different desktop environments in VMs:

### GNOME Desktop

```bash
# Already configured in desktop-test
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm
```

### KDE Plasma

```bash
# Use the kde-test configuration
nix build .#nixosConfigurations.kde-test.config.system.build.vm
./result/bin/run-kde-test-vm
```

### Custom Desktop Environment

Edit any VM configuration to try different desktops:

```nix
# In hosts/my-vm/configuration.nix
modules.desktop.gnome.enable = false;  # Disable GNOME
modules.desktop.kde.enable = true;     # Enable KDE
# or
modules.desktop.hyprland.enable = true; # Enable Hyprland
```

## Advanced Usage

### VM with More Resources

Run VMs with custom memory and CPU allocation:

```bash
# Run with 4GB RAM and 4 CPU cores
./result/bin/run-desktop-test-vm -m 4096 -smp 4

# Run with port forwarding for SSH access
./result/bin/run-desktop-test-vm -netdev user,id=net0,hostfwd=tcp::2222-:22
# Then: ssh vm-user@localhost -p 2222
```

### Persistent VM Disk

Create a persistent VM disk instead of temporary storage:

```bash
# Create a 20GB disk image
qemu-img create -f qcow2 nixos-vm.qcow2 20G

# Run VM with persistent disk
./result/bin/run-desktop-test-vm -hda nixos-vm.qcow2
```

### Development Workflow

Use VMs for NixOS configuration development:

1. **Edit configurations** on your host system
1. **Rebuild VMs** to test changes
1. **SSH into VMs** for testing
1. **Iterate quickly** without affecting your host

```bash
# Development cycle
nano hosts/desktop-test/configuration.nix  # Edit config
nix build .#nixosConfigurations.desktop-test.config.system.build.vm  # Rebuild
./result/bin/run-desktop-test-vm &  # Start VM in background
ssh vm-user@localhost -p 2222  # SSH into VM to test
```

## Troubleshooting

### Common Issues

1. **KVM permission denied**:

   ```bash
   # Check group membership
   groups
   # Should include 'kvm' and 'libvirt'

   # If not, add and re-login
   sudo usermod -a -G kvm,libvirt $USER
   ```

1. **Nix flakes not working**:

   ```bash
   # Ensure experimental features are enabled
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

1. **VM won't start**:

   ```bash
   # Check if KVM is available
   lsmod | grep kvm

   # Try without KVM acceleration
   ./result/bin/run-desktop-test-vm -accel tcg
   ```

1. **Build failures**:

   ```bash
   # Check flake syntax
   nix flake check

   # Update flake inputs
   nix flake update
   ```

1. **Out of disk space**:

   ```bash
   # Clean old Nix builds
   nix-collect-garbage -d

   # Clean old VM results
   rm -rf result result-*
   ```

### Performance Tips

1. **Enable KVM acceleration** (much faster than emulation)
1. **Allocate sufficient RAM** (minimum 2GB, recommend 4GB+)
1. **Use SSD storage** for better VM performance
1. **Close unused applications** when running VMs

## Learning NixOS

This setup is perfect for learning NixOS:

### 1. Start with Templates

- Use `desktop-test` to explore GNOME on NixOS
- Try `qemu-vm` for a minimal NixOS experience
- Experiment with different configurations

### 2. Modify Configurations

- Edit `hosts/*/configuration.nix` files
- Try enabling/disabling different modules
- Test changes in VMs before real installations

### 3. Explore the Module System

- Look at `modules/` directory structure
- Understand how modules compose together
- Create your own custom modules

### 4. Practice Nix Language

- Read existing configurations
- Modify and experiment
- Use `nix repl` to explore Nix interactively

## Next Steps

Once comfortable with NixOS in VMs:

1. **Install NixOS** on real hardware using your tested configurations
1. **Contribute back** improvements to this template
1. **Create your own** NixOS configurations repository
1. **Join the community** - NixOS Discord, Matrix, or Discourse

## Getting Help

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **NixOS Options**: https://search.nixos.org/options
- **Community**: https://discourse.nixos.org/
- **This Repo Issues**: For template-specific questions

---

**Happy NixOS exploration!** 🚀
