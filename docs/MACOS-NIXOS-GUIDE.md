# NixOS on macOS Guide

This comprehensive guide covers running and testing NixOS configurations on macOS using UTM, QEMU, and other virtualization solutions.

## Table of Contents

1. [Overview](#overview)
1. [Prerequisites](#prerequisites)
1. [Quick Start](#quick-start)
1. [Virtual Machine Configurations](#virtual-machine-configurations)
1. [ISO Installers](#iso-installers)
1. [UTM Setup Guide](#utm-setup-guide)
1. [Performance Optimization](#performance-optimization)
1. [Architecture Considerations](#architecture-considerations)
1. [Development Workflow](#development-workflow)
1. [Troubleshooting](#troubleshooting)
1. [Advanced Usage](#advanced-usage)

## Overview

This template provides comprehensive macOS support including:

**NixOS Virtualization:**

- **Test NixOS configurations** before deploying to real hardware
- **Develop NixOS systems** using familiar macOS tools
- **Create custom installers** optimized for different use cases
- **Learn NixOS** in a safe, isolated environment

**Native macOS Management:**

- **nix-darwin** for declarative macOS system management
- **Home Manager** integration for user environments
- **Homebrew integration** for GUI applications
- **Cross-platform** configuration sharing with NixOS

### Supported Configurations

**Virtual Machines:**

- **Desktop VM**: Full GNOME desktop environment with development tools
- **Laptop VM**: Laptop-optimized with power management and mobile features
- **Server VM**: Headless server configuration for development and testing

**Architecture Support:**

- **Apple Silicon** (M1/M2/M3): Native aarch64-linux VMs for optimal performance
- **Intel Macs**: x86_64-linux VMs with excellent compatibility

**ISO Installers:**

- **Desktop ISO**: GNOME-based graphical installer
- **Minimal ISO**: Lightweight command-line installer for servers

**nix-darwin Configurations:**

- **Desktop**: Full desktop environment with development tools
- **Laptop**: Mobile-optimized for MacBooks
- **Server**: Headless development server setup

## Prerequisites

### System Requirements

**Hardware:**

- **Apple Silicon**: 8GB+ RAM, 50GB+ free storage
- **Intel Mac**: 8GB+ RAM, 50GB+ free storage
- macOS 11.0 (Big Sur) or later

**Software:**

- **Nix package manager** (with flakes enabled)
- **UTM** (recommended) or QEMU
- **Command line tools** (Xcode Command Line Tools)

### Installing Prerequisites

1. **Install Nix**:

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

1. **Install UTM** (recommended):
   - From Mac App Store: Search "UTM"
   - From GitHub: Download from https://github.com/utmapp/UTM/releases

1. **Enable Nix Flakes** (if not enabled):

   ```bash
   echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
   ```

## Quick Start

### Option 1: Native macOS Management (nix-darwin)

For managing your Mac directly with Nix:

```bash
# Clone the template
git clone https://github.com/yourusername/nixos-template
cd nixos-template

# Install nix-darwin
./scripts/install-nix-darwin.sh
```

### Option 2: NixOS Virtualization (Testing)

For testing NixOS configurations in VMs:

```bash
# Clone the template
git clone https://github.com/yourusername/nixos-template
cd nixos-template

# Run the interactive macOS script
./scripts/try-nixos-macos.sh
```

### Option 3: Direct Commands

```bash
# Build desktop VM (auto-detects your Mac's architecture)
just build-macos-vm desktop

# Run the VM
./result/bin/run-desktop-macos-vm

# Login: nixos/nixos
```

### Option 4: Using Just Commands

```bash
# List all macOS options
just list-macos

# Build specific configurations
just build-macos-vm laptop aarch64    # For Apple Silicon
just build-macos-vm server x86_64     # For Intel Mac
just build-macos-iso desktop          # Build installer ISO

# Test without building
just test-macos desktop aarch64

# Get comprehensive help
just macos-help
```

## nix-darwin Native macOS Management

### What is nix-darwin?

nix-darwin brings the power of NixOS configuration management to macOS. Instead of manually installing and configuring software, you declare your entire system configuration in code.

### Benefits of nix-darwin

**Reproducible Systems:**

- Version control your entire macOS configuration
- Reproduce your setup on any Mac instantly
- Share configurations across team members

**Rollback Capability:**

- Every change creates a new "generation"
- Roll back to previous working configurations
- Safe to experiment with system changes

**Integration:**

- Works alongside existing macOS applications
- Integrates with Homebrew for GUI apps
- Manages system preferences declaratively

### nix-darwin Configurations

#### Desktop Configuration

**Target:** Primary development machines, iMacs, Mac Studios
**Features:**

- Full development environment (Node.js, Python, Go, Rust, Java)
- GUI applications via Homebrew (VS Code, Docker, browsers)
- Development databases (PostgreSQL, Redis, MongoDB)
- Media tools and productivity applications
- Comprehensive shell setup with Zsh and Starship

#### Laptop Configuration

**Target:** MacBooks, mobile development
**Features:**

- Battery-optimized settings and power management
- Lightweight development tools
- Mobile-friendly applications
- Network connectivity tools
- Power-aware development environments

#### Server Configuration

**Target:** Headless development, CI/CD, Mac minis
**Features:**

- Server development stack
- Container orchestration tools
- Monitoring and logging
- Database servers
- Minimal GUI overhead

### Installation

**Quick Installation:**

```bash
git clone https://github.com/yourusername/nixos-template
cd nixos-template
./scripts/install-nix-darwin.sh
```

**Manual Installation:**

```bash
# Clone template
git clone https://github.com/yourusername/nixos-template ~/.config/nix-darwin
cd ~/.config/nix-darwin

# Install for Apple Silicon
nix run nix-darwin -- switch --flake .#darwin-desktop

# Install for Intel Mac
nix run nix-darwin -- switch --flake .#darwin-desktop-intel
```

### Usage

**System Management:**

```bash
# Apply configuration changes
darwin-rebuild switch --flake ~/.config/nix-darwin

# Update system and packages
darwin-update

# Show system information
darwin-info

# List previous generations
darwin-rebuild --list-generations

# Rollback to previous generation
darwin-rebuild --rollback
```

**Customization:**
Edit configuration files in `~/.config/nix-darwin/hosts/darwin-*/`:

- `configuration.nix` - System-level settings
- `home.nix` - User environment and applications

**Example Changes:**

```nix
# Add a new package
environment.systemPackages = with pkgs; [
  # existing packages...
  neofetch  # Add this line
];

# Change system preferences
system.defaults.dock.tilesize = 64;  # Larger dock icons

# Add Homebrew application
homebrew.casks = [
  # existing apps...
  "spotify"  # Add this line
];
```

Then apply changes:

```bash
darwin-rebuild switch --flake ~/.config/nix-darwin
```

### For More Information

See the complete **[nix-darwin Guide](NIX-DARWIN-GUIDE.md)** for:

- Detailed configuration options
- Advanced customization
- Troubleshooting
- Best practices

## Virtual Machine Configurations

### Desktop VM

**Purpose**: Full desktop environment for testing and development

**Specifications**:

- **RAM**: 4GB (recommended)
- **Storage**: 20GB+
- **Desktop**: GNOME with Wayland
- **User**: nixos/nixos

**Features**:

- Complete GNOME desktop environment
- Firefox, VS Code, development tools
- Clipboard integration with macOS
- VirtIO drivers for optimal performance
- Guest tools for seamless integration

**Build Commands**:

```bash
# Apple Silicon
just build-macos-vm desktop aarch64

# Intel Mac
just build-macos-vm desktop x86_64

# Or use architecture detection
just build-macos-vm desktop
```

### Laptop VM

**Purpose**: Laptop-specific features testing and mobile computing simulation

**Specifications**:

- **RAM**: 3GB (laptop-like constraints)
- **Storage**: 15GB+
- **User**: laptop-user/nixos

**Features**:

- Power management simulation
- NetworkManager for WiFi simulation
- Bluetooth support (simulated)
- Battery status emulation
- Mobile-optimized applications
- Redshift for eye care

**Unique Utilities**:

- `laptop-vm-info`: System information
- `laptop-vm-optimize`: Performance tuning
- `battery`: Power status (simulated)
- `wifi`: Network management

### Server VM

**Purpose**: Headless server development and testing

**Specifications**:

- **RAM**: 2GB (server baseline)
- **Storage**: 10GB+
- **Interface**: Headless (SSH only)
- **User**: server-admin/nixos

**Features**:

- SSH server enabled
- Container support (Podman)
- Development databases (PostgreSQL, Redis)
- Web server (Nginx)
- Monitoring (Prometheus, Node Exporter)
- No desktop environment

**Services**:

- SSH (port 22)
- HTTP (ports 80, 8080)
- PostgreSQL (port 5432)
- Redis (port 6379)
- Prometheus (port 9090)

**Management Commands**:

- `server-status`: Service status overview
- `server-logs [service]`: View service logs
- `containers`: List running containers

## ISO Installers

### Desktop ISO

**Purpose**: Graphical NixOS installer with desktop environment

**Features**:

- Full GNOME desktop
- Firefox for documentation access
- GParted for disk partitioning
- Automated installation scripts
- Template selection wizard
- Development tools included

**Usage**:

1. Build the ISO: `just build-macos-iso desktop`
1. Import into UTM as CD/DVD
1. Create new VM with appropriate settings
1. Boot from ISO and follow installer

**Installation Scripts**:

- `install-nixos-macos`: Interactive installation guide
- `nixos-macos-auto-install`: Automated installation
- `optimize-for-macos-vm`: VM optimizations

### Minimal ISO

**Purpose**: Lightweight server installer

**Features**:

- Command-line interface only
- Essential system tools
- SSH access enabled
- Minimal resource usage
- Perfect for server installations

**Usage**:

1. Build the ISO: `just build-macos-iso minimal`
1. Boot in UTM with minimal resources
1. SSH access: `ssh nixos@<vm-ip>`
1. Use installation scripts or manual process

**Installation Scripts**:

- `install-nixos-server-macos`: Server installation guide
- `server-auto-install`: Automated server setup
- `vm-network-check`: Network diagnostics

## UTM Setup Guide

### Creating a New VM in UTM

1. **Download UTM**:
   - Mac App Store (easiest)
   - GitHub releases (latest features)

1. **Create New VM**:
   - Click "Create a New Virtual Machine"
   - Choose "Virtualize" (Apple Silicon) or "Emulate" (Intel/compatibility)

1. **Operating System**:
   - Select "Linux"
   - Choose architecture: ARM64 (M1/M2/M3) or x86_64 (Intel)

1. **Configuration**:

   ```
   Architecture: ARM64 (Apple Silicon) or x86_64 (Intel)
   System:      QEMU 7.0+ ARM/x86 Virtual Machine
   Memory:      4096 MB (desktop), 2048 MB (server)
   Storage:     20 GB+ (varies by use case)
   ```

1. **Boot Configuration**:
   - Enable UEFI Boot
   - Add CD/DVD drive for ISOs
   - Network: Shared Network (NAT)

### Importing Pre-built VMs

1. **Build VM with this template**:

   ```bash
   just build-macos-vm desktop
   ```

1. **Extract QEMU command**:
   - The built VM includes a run script
   - Copy QEMU parameters for UTM

1. **Create UTM VM**:
   - Use "Custom" configuration
   - Apply extracted parameters
   - Import disk image

### UTM Performance Settings

**Apple Silicon Optimization**:

- Enable "Use Apple Virtualization"
- Select ARM64 architecture
- Enable hardware acceleration
- Use VirtIO devices for better performance

**Intel Mac Optimization**:

- Use QEMU virtualization
- Enable hardware acceleration if available
- Allocate appropriate CPU cores
- Use VirtIO network and storage

## Performance Optimization

### Architecture-Specific Optimizations

**Apple Silicon (M1/M2/M3)**:

- Use native aarch64-linux VMs for best performance
- Enable hardware virtualization in UTM
- Allocate sufficient memory (4GB+ for desktop)
- Use VirtIO drivers for network and storage

**Intel Macs**:

- Use x86_64-linux VMs for compatibility
- Enable hardware acceleration when possible
- Consider emulation overhead in resource allocation
- Use VirtIO devices for optimal performance

### VM Resource Allocation

**Desktop VM**:

- **Memory**: 4GB+ (8GB for heavy development)
- **CPUs**: 2-4 cores
- **Storage**: 20GB+ (SSD recommended)
- **Graphics**: VirtIO GPU with 128MB+ VRAM

**Laptop VM**:

- **Memory**: 3GB (simulate laptop constraints)
- **CPUs**: 2 cores
- **Storage**: 15GB+
- **Graphics**: Basic VirtIO GPU

**Server VM**:

- **Memory**: 2GB (minimal for server workloads)
- **CPUs**: 2 cores
- **Storage**: 10GB+
- **Graphics**: None (headless)

### Host System Optimization

**macOS Settings**:

- Disable automatic graphics switching (Intel Macs)
- Ensure adequate cooling for sustained workloads
- Use external power when possible
- Close unnecessary applications

**Storage Optimization**:

- Use SSD storage for VM images
- Regular cleanup: `nix-collect-garbage -d`
- Monitor disk usage during builds

## Architecture Considerations

### Apple Silicon (aarch64)

**Advantages**:

- Native ARM64 virtualization
- Excellent performance
- Hardware acceleration support
- Lower power consumption

**Considerations**:

- Some x86_64-only software may not be available
- Cross-compilation may be needed for some packages
- Newer architecture with occasional compatibility issues

**Recommended Usage**:

- Primary development on Apple Silicon
- Use aarch64-linux VMs
- Cross-compile when needed

### Intel Macs (x86_64)

**Advantages**:

- Maximum software compatibility
- Extensive package availability
- Well-tested virtualization stack
- Industry standard architecture

**Considerations**:

- Higher power consumption
- Less efficient virtualization on newer Macs
- Legacy architecture

**Recommended Usage**:

- Use for maximum compatibility
- Good for production environment testing
- Stable for development workflows

### Cross-Architecture Support

This template supports both architectures with:

- Automatic architecture detection
- Architecture-specific optimizations
- Cross-compilation capabilities
- Unified configuration management

## Development Workflow

### Typical Development Process

1. **Start with VM Development**:

   ```bash
   # Build and test in VM first
   just build-macos-vm desktop
   ./result/bin/run-desktop-macos-vm
   ```

1. **Iterate on Configurations**:

   ```bash
   # Edit configurations
   vim hosts/macos-vms/desktop-macos.nix

   # Rebuild and test
   just build-macos-vm desktop
   ```

1. **Create Custom ISOs**:

   ```bash
   # Build installer with your configs
   just build-macos-iso desktop
   ```

1. **Deploy to Real Hardware**:
   - Use ISOs to install on physical machines
   - Apply tested configurations
   - Minimal migration needed

### Integration with macOS Development

**File Sharing**:

- Shared directories between macOS and NixOS VMs
- Clipboard integration
- Drag-and-drop file transfer (UTM)

**Tool Integration**:

- Use macOS editors with NixOS projects
- SSH into VMs for command-line work
- Port forwarding for web development

**Version Control**:

- Git repositories shared between host and VMs
- Consistent development environments
- Easy backup and synchronization

## Troubleshooting

### Common Issues

**VM Won't Boot**:

- Check architecture match (ARM64 vs x86_64)
- Verify UEFI boot is enabled
- Ensure adequate resources allocated
- Check UTM console for error messages

**Slow Performance**:

- Enable hardware acceleration in UTM
- Increase memory allocation
- Use SSD storage for VM images
- Close unnecessary macOS applications

**Network Issues**:

- Use bridged networking for better connectivity
- Check firewall settings in NixOS
- Verify DHCP configuration
- Test with different network modes

**Graphics Problems**:

- Install VirtIO drivers
- Enable hardware graphics acceleration
- Check display scaling settings
- Use VNC for headless access

**Build Failures**:

- Check internet connectivity
- Ensure sufficient disk space (10GB+)
- Clear Nix cache: `nix-collect-garbage -d`
- Verify flakes are enabled

### Architecture-Specific Issues

**Apple Silicon**:

- Rosetta 2 required for some x86_64 binaries
- Some packages may not support aarch64 yet
- Hardware acceleration may need specific drivers

**Intel Mac**:

- Slower virtualization on newer macOS versions
- Higher resource usage
- May need compatibility flags for newer packages

### Debug Commands

```bash
# Check system information
system -version
uname -a

# Monitor VM resources
htop
iotop

# Network diagnostics
ping google.com
nslookup nixos.org
netstat -rn

# Nix debugging
nix --version
nix show-config
```

### Getting Help

**Template-Specific**:

- Run `just macos-help` for comprehensive guidance
- Check documentation in `docs/`
- Review example configurations in `hosts/macos-vms/`

**Community Resources**:

- NixOS Discourse: https://discourse.nixos.org
- Matrix Chat: #nixos:nixos.org
- GitHub Issues: Template repository issues
- UTM Community: UTM GitHub discussions

## Advanced Usage

### Custom VM Configurations

**Creating Custom VMs**:

1. Copy existing configuration:

   ```bash
   cp -r hosts/macos-vms/desktop-macos hosts/my-custom-vm
   ```

1. Customize configuration:

   ```bash
   vim hosts/my-custom-vm/configuration.nix
   ```

1. Add to flake.nix:

   ```nix
   my-custom-vm = mkSystem {
     hostname = "my-custom-vm";
     system = "aarch64-linux";
     extraModules = [ templateConfig ];
   };
   ```

1. Build and test:

   ```bash
   nix build .#nixosConfigurations.my-custom-vm.config.system.build.vm
   ```

### Cross-Compilation

**Building for Different Architectures**:

```bash
# Build aarch64 on Intel Mac
nix build .#nixosConfigurations.desktop-macos.config.system.build.vm --system aarch64-linux

# Build x86_64 on Apple Silicon
nix build .#nixosConfigurations.desktop-macos-intel.config.system.build.vm --system x86_64-linux
```

### Remote Development

**SSH into VMs**:

```bash
# Start VM with port forwarding
ssh -p 2222 nixos@localhost

# Or use direct VM IP
ssh nixos@192.168.64.xxx
```

**VS Code Remote Development**:

1. Install "Remote - SSH" extension
1. Connect to VM via SSH
1. Develop directly in VM environment

### Container Development

**Using Podman in VMs**:

```bash
# In server VM
podman run -d -p 8080:80 nginx
podman build -t myapp .
podman-compose up
```

**Docker Alternative**:

- Podman provides Docker-compatible interface
- Rootless containers for security
- Direct integration with development workflow

### Shared Folder Configuration

**UTM Shared Folders**:

1. Enable in UTM VM settings
1. Mount in NixOS:
   ```nix
   fileSystems."/mnt/shared" = {
     device = "share";
     fsType = "9p";
     options = [ "trans=virtio" "version=9p2000.L" ];
   };
   ```

### Automation and CI/CD

**Automated Testing**:

```bash
# Test all macOS configurations
just test-all-macos

# Build verification
just build-all-macos
```

**Integration with CI/CD**:

- Use GitHub Actions with macOS runners
- Automated testing of configurations
- Cross-platform compatibility verification

## Resources

### Documentation

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **UTM Documentation**: https://docs.getutm.app/
- **QEMU Documentation**: https://www.qemu.org/docs/

### Community

- **NixOS Discourse**: https://discourse.nixos.org/
- **Matrix Chat**: #nixos:nixos.org
- **Reddit**: r/NixOS
- **Stack Overflow**: nixos tag

### Apple-Specific Resources

- **Apple Virtualization Framework**: Technical documentation
- **UTM Community**: GitHub discussions and issues
- **macOS Development**: Apple Developer documentation

### Learning Resources

- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **NixOS & Flakes Book**: https://nixos-and-flakes.thiscute.world/
- **Zero to Nix**: https://zero-to-nix.com/

This guide provides comprehensive coverage of running NixOS on macOS. For additional help, run `just macos-help` or refer to the template documentation.
