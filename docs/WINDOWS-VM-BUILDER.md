# NixOS VM Builder for Windows Users

This guide helps Windows users create NixOS virtual machines without installing Nix locally.
Using Docker, you can build customized NixOS VMs that work with popular virtualization
platforms on Windows.

## Overview

The NixOS VM Builder provides:

- **Docker-based Building** - No need to install Nix on Windows
- **Multiple VM Templates** - Desktop, server, gaming, minimal, and development configurations
- **Multi-Platform Support** - VirtualBox, Hyper-V, VMware, and QEMU formats
- **Automated Builds** - Pre-built images available via GitHub releases
- **Customizable** - Modify templates for your specific needs

## Quick Start (Pre-built Images)

### Option 1: Download Pre-built VMs

1. **Visit Releases**: Go to [GitHub Releases](https://github.com/olafkfreund/nixos-template/releases)

1. **Choose Template**: Download your preferred VM template:
   - `nixos-desktop-virtualbox.ova` - Full desktop environment
   - `nixos-server-virtualbox.ova` - Headless server
   - `nixos-gaming-virtualbox.ova` - Gaming-optimized
   - `nixos-minimal-virtualbox.ova` - Lightweight installation
   - `nixos-development-virtualbox.ova` - Development environment

1. **Import VM**: Use your virtualization software to import the downloaded file

1. **Login**: Default credentials are `nixos` / `nixos` (change immediately!)

### Option 2: Build Custom VMs with Docker

#### Prerequisites

- **Docker Desktop** installed on Windows
- **8GB+ RAM** recommended for building
- **20GB+ free disk space** for VM builds

#### Build Your First VM

1. **Open PowerShell** and create a workspace:

   ```powershell
   mkdir nixos-vms
   cd nixos-vms
   ```

1. **Pull the builder image**:

   ```powershell
   docker pull olafkfreund/nixos-vm-builder:latest
   ```

1. **Build a desktop VM**:

   ```powershell
   docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest virtualbox --template desktop
   ```

1. **Find your VM**: Check the `output/` directory for the generated `.ova` file

## VM Templates

### Desktop Template (`desktop`)

**Perfect for**: New NixOS users, general desktop use

**Includes**:

- GNOME desktop environment
- Firefox, Thunderbird, LibreOffice
- Development tools (Git, VS Code)
- Media applications (VLC, GIMP)
- 20GB disk, 4GB RAM (default)

**Import Instructions**:

- VirtualBox: File → Import Appliance
- VMware: File → Open → Select .vmdk
- Hyper-V: Quick Create → Use .vhdx file

### Server Template (`server`)

**Perfect for**: Headless servers, learning Linux administration

**Includes**:

- No desktop environment (CLI only)
- SSH server enabled
- Docker and container tools
- Network and monitoring utilities
- 40GB disk, 2GB RAM (default)

**Access**: SSH to VM IP address with `nixos` user

### Gaming Template (`gaming`)

**Perfect for**: Gaming on NixOS, Steam gaming

**Includes**:

- GNOME desktop with gaming optimizations
- Steam, Lutris, Heroic launcher
- Performance tools (GameMode, MangoHUD)
- Latest kernel for gaming
- 80GB disk, 8GB RAM (default)

**Note**: Requires GPU passthrough for best performance

### Minimal Template (`minimal`)

**Perfect for**: Learning NixOS basics, resource-constrained environments

**Includes**:

- Minimal CLI installation
- Essential tools only
- SSH access enabled
- 10GB disk, 1GB RAM (default)

**Use Case**: Perfect for learning NixOS without GUI overhead

### Development Template (`development`)

**Perfect for**: Software development, programming

**Includes**:

- Full desktop environment
- Programming languages (Node.js, Python, Rust, Go, Java)
- IDEs and editors (VS Code, Neovim, Emacs)
- Database tools (PostgreSQL, Redis)
- Container tools (Docker, Kubernetes)
- 60GB disk, 6GB RAM (default)

## Virtualization Platform Setup

### VirtualBox (Recommended for Beginners)

1. **Download VirtualBox**: [virtualbox.org](https://www.virtualbox.org/)

1. **Install Extension Pack** for better performance

1. **Import OVA**:
   - File → Import Appliance
   - Select your `nixos-*.ova` file
   - Adjust VM settings if needed
   - Click Import

1. **First Boot**:
   - Start the VM
   - Login with `nixos` / `nixos`
   - Change password: `passwd`

### Hyper-V (Windows Pro/Enterprise)

1. **Enable Hyper-V**:

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```

1. **Hyper-V Manager**:
   - Open Hyper-V Manager
   - Action → New → Virtual Machine
   - Use existing virtual hard disk
   - Select your `nixos-*.vhdx` file

1. **VM Settings**:
   - Enable Dynamic Memory
   - Set appropriate CPU cores
   - Connect to virtual switch

### VMware Workstation/Player

1. **Create New VM**:
   - File → New Virtual Machine
   - Select "I will install the operating system later"
   - Choose Linux → Other Linux

1. **Add Disk**:
   - Remove default disk
   - Add existing disk
   - Select your `nixos-*.vmdk` file

1. **VM Settings**:
   - Adjust memory and CPU
   - Enable virtualization features

### QEMU (Advanced Users)

```powershell
# Install QEMU for Windows
winget install qemu

# Run VM
qemu-system-x86_64 -m 4096 -hda nixos-desktop.qcow2 -enable-kvm
```

## Building Custom VMs

### Basic Build Commands

```powershell
# Build specific template and format
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest <FORMAT> --template <TEMPLATE>

# Examples:
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest virtualbox --template desktop
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest hyperv --template server
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest vmware --template gaming
```

### Advanced Build Options

```powershell
# Custom VM specifications
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest virtualbox `
  --template desktop `
  --disk-size 40960 `
  --memory 8192 `
  --vm-name my-custom-desktop

# Build all formats at once
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest all --template development

# List available templates
docker run --rm olafkfreund/nixos-vm-builder:latest --list-templates

# Validate configuration only
docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest --validate-only --template server
```

### Custom Configuration Files

1. **Create custom config**:

   ```powershell
   # Create custom-config.nix in your workspace
   @"
   { config, pkgs, lib, ... }:
   {
     # Your custom NixOS configuration
     environment.systemPackages = with pkgs; [
       firefox
       git
       docker
     ];

     services.openssh.enable = true;
   }
   "@ | Out-File -FilePath custom-config.nix -Encoding utf8
   ```

1. **Build with custom config**:

   ```powershell
   docker run --rm -v "${PWD}:/workspace" olafkfreund/nixos-vm-builder:latest virtualbox `
     --config /workspace/custom-config.nix
   ```

## Troubleshooting

### Build Issues

**Problem**: Docker build fails with "out of space"
**Solution**: Increase Docker Desktop disk space in settings

**Problem**: Build takes very long
**Solution**:

- Increase Docker memory allocation
- Use pre-built binary cache
- Build smaller templates first (minimal)

**Problem**: VM doesn't boot
**Solution**:

- Check virtualization is enabled in BIOS
- Verify VM memory allocation
- Try different VM format

### VM Performance

**Slow Performance**:

- Increase RAM allocation
- Enable hardware acceleration
- Disable unnecessary services
- Use SSD for VM storage

**Graphics Issues**:

- Install guest additions/tools
- Enable 3D acceleration in VM settings
- Adjust video memory allocation

### Network Issues

**No Internet Access**:

- Check VM network settings
- Use NAT or Bridged networking
- Restart NetworkManager: `sudo systemctl restart NetworkManager`

**SSH Connection Failed**:

- Verify SSH service: `sudo systemctl status sshd`
- Check firewall: `sudo systemctl status firewall`
- Use VM console to troubleshoot

## Security Best Practices

### Initial Setup

1. **Change Default Password**:

   ```bash
   passwd nixos
   ```

1. **Update System**:

   ```bash
   sudo nixos-rebuild switch --upgrade
   ```

1. **Configure SSH Keys** (for server VMs):

   ```bash
   # Generate SSH key on Windows
   ssh-keygen -t ed25519

   # Copy to VM
   ssh-copy-id nixos@vm-ip-address
   ```

1. **Enable Firewall**:

   ```bash
   sudo systemctl enable firewall
   sudo systemctl start firewall
   ```

### Production Considerations

- **Change all default passwords**
- **Configure proper SSH keys**
- **Enable automatic security updates**
- **Set up backup procedures**
- **Configure monitoring and logging**

## Next Steps

### Learning NixOS

1. **Official Manual**: [NixOS Manual](https://nixos.org/manual/nixos/stable/)
1. **Community Wiki**: [NixOS Wiki](https://nixos.wiki/)
1. **Package Search**: [search.nixos.org](https://search.nixos.org/)

### Advanced Usage

1. **Flakes**: Modern NixOS configuration management
1. **Home Manager**: User environment management
1. **Development Shells**: Project-specific development environments
1. **Custom Packages**: Creating your own Nix packages

### Community

- **Discord**: [NixOS Discord](https://discord.gg/RbvHtGa)
- **Forum**: [NixOS Discourse](https://discourse.nixos.org/)
- **Reddit**: [r/NixOS](https://reddit.com/r/NixOS)

## FAQ

### Q: Do I need to install Nix on Windows?

**A**: No! The Docker-based builder handles everything. You only need Docker Desktop.

### Q: Can I run NixOS alongside Windows?

**A**: Yes! These are virtual machines that run inside Windows. You can also dual-boot, but VMs are safer for learning.

### Q: Which template should I choose?

**A**:

- **New to Linux**: Desktop template
- **Server/DevOps**: Server template
- **Gaming**: Gaming template
- **Learning**: Minimal template
- **Programming**: Development template

### Q: How much disk space do I need?

**A**:

- Building: 20GB+ free space
- Running VMs: 10-80GB depending on template
- Pre-built images: Download size only

### Q: Can I modify the templates?

**A**: Yes! Fork the repository and customize the template files, or create your own configuration files.

### Q: Is this secure for production use?

**A**: The VMs use default passwords and are configured for ease of use.
For production, change all passwords, configure SSH keys, and apply security hardening.

### Q: Can I run multiple VMs?

**A**: Yes! Each VM is independent. Just ensure you have enough system resources.

---

**Need Help?**

- Check the [Issues](https://github.com/olafkfreund/nixos-template/issues) page
- Ask questions in [Discussions](https://github.com/olafkfreund/nixos-template/discussions)
- Join the NixOS community Discord

Built with NixOS and Docker
