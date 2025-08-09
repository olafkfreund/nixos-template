# How to Try NixOS on Windows - Complete Guide

This step-by-step guide shows Windows users how to run NixOS virtual machines without installing any Linux tools or complex setup. Perfect for exploring NixOS safely alongside your existing Windows installation.

## Why NixOS Virtual Machines?

- **Safe to Try** - No risk to your Windows installation
- **Easy Setup** - Just download and import
- **Full Experience** - Complete NixOS environment
- **Multiple Options** - Desktop, server, gaming, development environments
- **Learn First** - Perfect for learning before committing to dual-boot

## Method 1: Download Pre-built VMs (Easiest)

### Step 1: Choose Your Virtual Machine Software

#### Option A: VirtualBox (Recommended for Beginners)

**✅ Best for**: First-time users, free option, works on all Windows versions

1. **Download VirtualBox**: Visit [virtualbox.org](https://www.virtualbox.org/wiki/Downloads)
1. **Install VirtualBox**: Run the installer with default settings
1. **Install Extension Pack**: Download and install for better performance

#### Option B: VMware Workstation (Professional Users)

**✅ Best for**: Better performance, professional use

1. **Download VMware**: [VMware Workstation Pro](https://www.vmware.com/products/workstation-pro.html)
1. **30-day trial** available for testing

#### Option C: Hyper-V (Windows Pro/Enterprise)

**✅ Best for**: Windows Pro users, native Microsoft virtualization

1. **Enable Hyper-V**: Open PowerShell as Administrator:

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```

1. **Restart computer** when prompted

### Step 2: Download Your NixOS VM

1. **Visit Releases**: Go to [GitHub Releases](https://github.com/olafkfreund/nixos-template/releases)

1. **Choose Your Template**:

   | Template        | Best For               | File to Download                   |
   | --------------- | ---------------------- | ---------------------------------- |
   | **Desktop**     | New users, general use | `nixos-desktop-virtualbox.ova`     |
   | **Gaming**      | Gaming, Steam          | `nixos-gaming-virtualbox.ova`      |
   | **Development** | Programming, coding    | `nixos-development-virtualbox.ova` |
   | **Server**      | Learning Linux servers | `nixos-server-virtualbox.ova`      |
   | **Minimal**     | Learning NixOS basics  | `nixos-minimal-virtualbox.ova`     |

1. **Download the appropriate file** for your VM software:
   - VirtualBox: `.ova` files
   - VMware: `.vmdk` files
   - Hyper-V: `.vhdx` files

### Step 3: Import and Start Your VM

#### VirtualBox Import

1. **Open VirtualBox**
1. **File Menu** → **Import Appliance**
1. **Select your downloaded `.ova` file**
1. **Review settings** (can adjust memory/CPU if needed)
1. **Click Import** (takes 5-10 minutes)
1. **Double-click the VM** to start it

#### VMware Import

1. **Open VMware Workstation**
1. **File Menu** → **Open**
1. **Select your downloaded `.vmdk` file**
1. **Create new VM** and use the VMDK as the hard drive
1. **Adjust settings** as needed
1. **Power on the VM**

#### Hyper-V Import

1. **Open Hyper-V Manager**
1. **Action Menu** → **New** → **Virtual Machine**
1. **Use existing virtual hard disk**
1. **Select your downloaded `.vhdx` file**
1. **Complete wizard** and start VM

### Step 4: First Login

1. **VM will boot to login screen**
1. **Default credentials**:
   - **Username**: `nixos`
   - **Password**: `nixos`
1. **⚠️ IMPORTANT**: Change password immediately:

   ```bash
   passwd
   ```

### Step 5: Initial Setup

1. **Update system**:

   ```bash
   sudo nixos-rebuild switch --upgrade
   ```

1. **Install VM Guest Tools** (for better integration):
   - **VirtualBox**: Menu → Devices → Insert Guest Additions CD
   - **VMware**: VM → Install VMware Tools
   - **Hyper-V**: Integration services auto-installed

1. **Connect to internet** (should work automatically)

## Method 2: Build Custom VMs with Docker

### Prerequisites

- **Docker Desktop** for Windows
- **8GB+ RAM** recommended
- **20GB+ free disk space**

### Step 1: Install Docker Desktop

1. **Download**: [Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
1. **Install** with default settings
1. **Start Docker Desktop**
1. **Verify installation**: Open PowerShell and run:

   ```powershell
   docker --version
   ```

### Step 2: Create Workspace

1. **Open PowerShell** and create a folder:

   ```powershell
   mkdir C:\NixOS-VMs
   cd C:\NixOS-VMs
   ```

### Step 3: Build Your VM

1. **Pull the VM builder**:

   ```powershell
   docker pull ghcr.io/olafkfreund/nixos-vm-builder:latest
   ```

1. **Build a desktop VM**:

   ```powershell
   docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest virtualbox --template desktop
   ```

1. **Wait for build** (30-60 minutes depending on template)

1. **Find your VM**: Check the `output` folder for your VM file

### Advanced Build Options

```powershell
# Build for Hyper-V with custom specs
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest hyperv --template server --disk-size 40960 --memory 4096

# Build gaming VM for VMware
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest vmware --template gaming

# Build development environment
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest virtualbox --template development

# See all options
docker run --rm ghcr.io/olafkfreund/nixos-vm-builder:latest --help
```

## What's Included in Each Template

### 🖥️ Desktop Template

**Perfect for**: First-time NixOS users, general desktop use

**What you get**:

- GNOME desktop environment (modern, user-friendly)
- Firefox web browser
- Thunderbird email client
- LibreOffice office suite
- VLC media player
- GIMP image editor
- VS Code text editor
- Git version control
- File manager, terminal, settings

**System specs**: 20GB disk, 4GB RAM

### 🎮 Gaming Template

**Perfect for**: Gamers wanting to try Linux gaming

**What you get**:

- GNOME desktop with gaming optimizations
- Steam gaming platform
- Lutris (game launcher)
- Heroic Games Launcher (Epic Games)
- GameMode (performance optimization)
- MangoHUD (performance overlay)
- Discord
- OBS Studio (streaming)

**System specs**: 80GB disk, 8GB RAM

### 💻 Development Template

**Perfect for**: Programmers and developers

**What you get**:

- GNOME desktop environment
- Programming languages: Python, Node.js, Rust, Go, Java
- IDEs: VS Code, Neovim, Emacs
- Development tools: Git, Docker, Kubernetes
- Databases: PostgreSQL, Redis
- Web browsers: Firefox
- Terminal with zsh shell

**System specs**: 60GB disk, 6GB RAM

### 🖧 Server Template

**Perfect for**: Learning Linux server administration

**What you get**:

- Command-line interface only (no desktop)
- SSH server for remote access
- Docker and container tools
- Network utilities
- System monitoring tools
- Text editors (vim, nano)
- Git version control

**System specs**: 40GB disk, 2GB RAM

### ⚡ Minimal Template

**Perfect for**: Learning NixOS basics, low-resource systems

**What you get**:

- Command-line interface only
- Essential system tools
- SSH access
- Text editors
- Basic utilities

**System specs**: 10GB disk, 1GB RAM

## Getting Started with Your NixOS VM

### Essential First Steps

1. **Change the password**:

   ```bash
   passwd
   ```

1. **Update the system**:

   ```bash
   sudo nixos-rebuild switch --upgrade
   ```

1. **Learn basic commands**:

   ```bash
   # List installed packages
   nix-env -q

   # Search for packages
   nix-env -qaP firefox

   # System information
   nixos-version
   ```

### Desktop Template Quick Tour

1. **Activities Overview**: Click top-left corner or press Super key
1. **Applications**: Click the 9-dot grid in bottom-left
1. **Terminal**: Press Ctrl+Alt+T
1. **Files**: File manager for browsing
1. **Settings**: System configuration

### Learning NixOS

1. **Configuration File**: `/etc/nixos/configuration.nix`
   - This file defines your entire system
   - Changes require rebuilding: `sudo nixos-rebuild switch`

1. **Package Management**:

   ```bash
   # Search packages
   nix search firefox

   # Install temporarily
   nix-shell -p firefox

   # Edit system config to install permanently
   sudo nano /etc/nixos/configuration.nix
   ```

1. **Key Concepts**:
   - **Declarative**: Describe what you want, not how to get it
   - **Reproducible**: Same config = same system
   - **Rollback**: Easy to undo changes
   - **Generations**: System snapshots

## Troubleshooting Common Issues

### VM Performance Issues

**Problem**: VM runs slowly
**Solutions**:

- Increase RAM allocation (4GB minimum for desktop)
- Enable hardware acceleration in VM settings
- Close other applications
- Use SSD storage if available

**Problem**: Graphics are slow/choppy
**Solutions**:

- Install VM guest additions/tools
- Enable 3D acceleration in VM settings
- Increase video memory allocation
- Update graphics drivers on Windows

### Networking Issues

**Problem**: No internet in VM
**Solutions**:

- Check VM network settings (use NAT mode)
- Restart NetworkManager: `sudo systemctl restart NetworkManager`
- Try different network adapter type in VM settings

**Problem**: Can't SSH to server VM
**Solutions**:

- Get VM IP: `ip addr show`
- Check SSH service: `sudo systemctl status sshd`
- Use VM console for initial troubleshooting

### System Issues

**Problem**: System won't update
**Solutions**:

- Check internet connection
- Try: `sudo nix-channel --update`
- Then: `sudo nixos-rebuild switch`

**Problem**: Package installation fails
**Solutions**:

- Check package name: `nix search packagename`
- Update channels first: `nix-channel --update`
- Use system config instead of nix-env

## Next Steps: Learning Path

### Week 1: Basic Exploration

- [ ] Try all applications in desktop template
- [ ] Learn terminal basics
- [ ] Understand file system layout
- [ ] Practice basic commands

### Week 2: Package Management

- [ ] Search for packages
- [ ] Install packages temporarily with nix-shell
- [ ] Edit configuration.nix to add packages permanently
- [ ] Learn about generations and rollbacks

### Week 3: System Configuration

- [ ] Modify system settings in configuration.nix
- [ ] Learn about NixOS modules
- [ ] Practice rebuilding system
- [ ] Understand the Nix language basics

### Month 2: Advanced Topics

- [ ] Learn about Home Manager
- [ ] Understand Nix flakes
- [ ] Create development environments
- [ ] Explore custom packages

## Getting Help

### Official Resources

- **NixOS Manual**: [nixos.org/manual](https://nixos.org/manual/nixos/stable/)
- **Package Search**: [search.nixos.org](https://search.nixos.org/packages)
- **NixOS Wiki**: [nixos.wiki](https://nixos.wiki/)

### Community Support

- **Discord**: [NixOS Discord Server](https://discord.gg/RbvHtGa)
- **Forum**: [NixOS Discourse](https://discourse.nixos.org/)
- **Reddit**: [r/NixOS](https://www.reddit.com/r/NixOS/)
- **Matrix**: #nixos:nixos.org

### This Repository

- **Issues**: Report bugs or ask questions
- **Discussions**: General help and ideas
- **Wiki**: Community documentation

## Frequently Asked Questions

### Q: Is it safe to run these VMs on Windows?

**A**: Yes! VMs are completely isolated from your Windows system. They can't harm your Windows installation.

### Q: Which template should I choose as a beginner?

**A**: Start with the **Desktop template**. It's the most user-friendly and includes everything you need to explore NixOS.

### Q: Can I run multiple VMs at once?

**A**: Yes, but ensure you have enough RAM. Each desktop VM needs 4GB, so 16GB+ Windows RAM is recommended for multiple VMs.

### Q: How do I share files between Windows and the VM?

**A**:

- **VirtualBox**: Install Guest Additions, then use Shared Folders
- **VMware**: Install VMware Tools, then use Shared Folders
- **Hyper-V**: Use Enhanced Session mode

### Q: Can I access my Windows files from the VM?

**A**: Yes, through shared folders (VM tools required) or network shares.

### Q: Should I use these VMs for production work?

**A**: These VMs use default passwords and are optimized for learning. For production, change all passwords and apply security hardening.

### Q: Can I convert from VM to dual-boot later?

**A**: Yes! Once comfortable with NixOS in a VM, you can install it directly on hardware or dual-boot with Windows.

### Q: How much disk space do I need?

**A**:

- **Desktop**: ~25GB (VM file + space for data)
- **Gaming**: ~90GB (large games)
- **Development**: ~70GB (development projects)
- **Server/Minimal**: ~15GB

### Q: Can I customize the VMs?

**A**: Absolutely! After import, you can modify `/etc/nixos/configuration.nix` and rebuild the system. You can also build custom VMs using the Docker method.

---

**Ready to start?** Pick a template above and follow the steps. The Desktop template is perfect for first-time users!

**Need help?** Join the NixOS community or create an issue in this repository.

Built with ❄️ NixOS - Welcome to the future of Linux! 🚀
