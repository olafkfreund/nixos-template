# Deployment Images Guide

This NixOS template includes comprehensive deployment image generation using our
**deployment factory**, providing ready-to-deploy images for various platforms and use cases
through a modular, unified system.

## Quick Start

### Build a specific image

```bash
# Cloud deployment images
nix build .#aws              # Amazon EC2 AMI
nix build .#azure            # Microsoft Azure VHD
nix build .#digitalocean     # Digital Ocean Droplet

# Virtualization images
nix build .#vmware           # VMware VM
nix build .#virtualbox-desktop # VirtualBox OVA with desktop
nix build .#qemu             # QEMU/KVM QCOW2

# Container images
nix build .#lxc              # LXC container

# Installation media
nix build .#iso              # Bootable live ISO

# Specialized images
nix build .#development-vm      # Full development environment
nix build .#development-minimal # Lightweight development VM
nix build .#production-server   # Hardened production server
nix build .#nixos-vm-builder-docker # Docker image for VM building
```

### List all available images

```bash
nix flake show | grep "packages"
```

## Available Deployment Images

### Cloud Platforms

#### **AWS AMI** (`aws`)

- **Format**: Amazon Machine Image
- **Use Case**: EC2 instance deployment
- **Features**: EC2 metadata service, EBS-optimized, automatic hardware optimization
- **Deploy**: Upload to AWS AMI and launch EC2 instances

#### **Azure VHD** (`azure`)

- **Format**: Virtual Hard Disk
- **Use Case**: Azure Virtual Machine deployment
- **Features**: Azure agent, automatic hardware detection, optimized for Azure
- **Deploy**: Upload to Azure storage and create VM

#### **Digital Ocean Image** (`digitalocean`)

- **Format**: Digital Ocean compatible
- **Use Case**: Digital Ocean Droplet deployment
- **Features**: DO agent, optimized networking, automatic scaling
- **Deploy**: Upload as custom image

### Virtualization

#### **VMware Image** (`vmware`)

- **Format**: VMware VMDK
- **Use Case**: VMware Workstation/vSphere
- **Features**: VMware Tools, paravirtualized drivers, automatic optimization
- **Deploy**: Import into VMware environment

#### **VirtualBox Desktop** (`virtualbox-desktop`)

- **Format**: Open Virtualization Appliance with GNOME desktop
- **Use Case**: VirtualBox deployment with GUI
- **Features**: Guest additions, shared folders, full desktop environment
- **Deploy**: Import OVA file into VirtualBox

#### **QEMU QCOW2** (`qemu`)

- **Format**: QCOW2 disk image
- **Use Case**: QEMU/KVM, Proxmox, OpenStack
- **Features**: Virtio drivers, SPICE support, KVM optimization
- **Deploy**: Use with QEMU/KVM hypervisors

### Containers

#### **LXC Container** (`lxc`)

- **Format**: LXC container template
- **Use Case**: LXC/LXD containers, Proxmox CT
- **Features**: Container-optimized, minimal overhead, security hardening
- **Deploy**: Import into LXC/LXD or Proxmox

### Installation Media

#### **Live ISO** (`iso`)

- **Format**: Bootable ISO image
- **Use Case**: Installation, recovery, testing
- **Features**: UEFI/BIOS boot, automatic hardware detection
- **Deploy**: Burn to USB/DVD or boot from ISO

### Specialized Images

#### **Development VM** (`development-vm`)

- **Format**: QCOW2 with comprehensive development tools
- **Use Case**: Full-featured local development, testing
- **Features**:
  - Development stack (Node.js, Python, Docker)
  - Virtualization support (libvirtd enabled)
  - GUI applications and code editors
  - Aggressive disk space optimization
- **Deploy**: Run locally with QEMU/KVM

#### **Development Minimal** (`development-minimal`)

- **Format**: Lightweight QCOW2 development environment
- **Use Case**: Resource-constrained development, quick testing
- **Features**:
  - Essential development tools only (Node.js, Python)
  - No GUI/desktop environment for minimal footprint
  - Maximum space optimization with aggressive cleanup
  - Docker support enabled
- **Deploy**: Run locally with QEMU/KVM (minimal resources)

#### **Production Server** (`production-server`)

- **Format**: QCOW2 hardened server
- **Use Case**: Production server deployment
- **Features**:
  - Security hardening (AppArmor, fail2ban, audit)
  - Server packages (nginx, PostgreSQL, borgbackup)
  - Firewall configuration and monitoring
  - Optimized for server workloads
- **Deploy**: Deploy to production hypervisors

#### **VM Builder Docker** (`nixos-vm-builder-docker`)

- **Format**: Docker container image
- **Use Case**: Building NixOS VMs on any system (especially Windows)
- **Features**:
  - Complete Nix toolchain for VM building
  - QEMU and libvirt tools included
  - Cross-platform VM generation
- **Deploy**: Use with Docker on any OS

## Deployment Factory Architecture

This template uses a **deployment factory** system (located in `lib/deployment-images.nix`) that
provides:

### Benefits

- **Unified Configuration**: All images share a common base with platform-specific optimizations
- **Consistent Security**: Locked root accounts, SSH configuration, firewall settings
- **Automatic Optimization**: Hardware detection, Nix store optimization, garbage collection
- **Space Efficiency**: Documentation disabled, aggressive cleanup, optimized journaling
- **Modular Design**: Easy to add new image types or modify existing ones

### Factory Features

All images automatically include:

- **Base Security**: Root account locked, SSH keys recommended, firewall enabled
- **Hardware Optimization**: Automatic detection and optimization for target platform
- **Nix Optimization**: Store optimization, garbage collection, binary cache usage
- **Essential Tools**: git, vim, curl, wget, htop, tree for all images
- **Network Management**: NetworkManager enabled, DHCP configuration

### Platform-Specific Optimizations

Each image type includes platform-specific features:

- **Cloud images**: Metadata services, cloud-init, auto-scaling preparation
- **VM images**: Guest tools, paravirtualized drivers, display optimization
- **Container images**: Container-specific networking, minimal overhead
- **Development images**: Development tools, Docker support, monitoring

## Advanced Configuration

### Custom Image Configuration

Create your own image variant by extending the base configuration:

```nix
# custom-image.nix
{ config, pkgs, ... }:
{
  imports = [
    ./hosts/common.nix
  ];

  # Your custom configuration
  services.myCustomService.enable = true;
  environment.systemPackages = with pkgs; [ customPackage ];
}
```

Then build with:

```bash
nixos-generate -f qcow -c ./custom-image.nix
```

### Image Customization Options

All images include these base features:

- **Hardware detection** - Automatic optimization
- **Nix optimization** - Enhanced performance
- **SSH access** - Default user: `nixos` (password: `nixos`)
- **Essential tools** - git, vim, curl, wget, htop
- **Network management** - NetworkManager enabled

### Override Default Settings

```nix
# In your configuration.nix
{
  # Change default user
  users.users.nixos.initialPassword = "mypassword";

  # Enable monitoring
  modules.services.monitoring.enable = true;

  # Add custom packages
  environment.systemPackages = with pkgs; [
    myCustomPackage
  ];
}
```

## Use Cases and Recommendations

### **Cloud Deployment**

- Use **AWS AMI** for scalable EC2 deployments
- Use **Azure VHD** for enterprise Azure environments
- Use **GCE Image** for Google Cloud infrastructure
- Use **DO Image** for cost-effective deployments

### **Local Development**

- Use **development-vm** for full-featured development
- Use **qemu-qcow2** for testing configurations
- Use **live-iso** for rescue and installation

### **Production Servers**

- Use **production-server** for secure server deployment
- Use **vmware-image** for enterprise VMware environments
- Use **qemu-qcow2** for KVM/OpenStack clouds

### **Edge/IoT Deployment**

- Use **rpi4-sd-image** for Raspberry Pi projects
- Use **lxc-template** for lightweight containers

### **Testing and Validation**

- Use **virtualbox-ova** for easy sharing and testing
- Use **live-iso** for hardware compatibility testing

## Build Optimization

### Parallel Building

```bash
# Build multiple images in parallel
nix build .#aws-ami .#azure-vhd .#gce-image --max-jobs auto
```

### Caching Strategy

The template includes optimized caching:

- Binary cache substitution from multiple sources
- Shared base configurations to maximize cache hits
- Optimized build settings for faster generation

### Storage Requirements

Typical image sizes:

- **Cloud images**: 2-4 GB
- **Live ISO**: 1-2 GB
- **Container templates**: 500MB-1GB
- **Development VM**: 4-8 GB
- **Production server**: 3-6 GB

## Deployment Examples

### AWS EC2 Deployment

```bash
# Build AMI
nix build .#aws

# Upload to AWS (requires AWS CLI)
aws ec2 import-image --description "NixOS Template" --disk-containers "Description=NixOS,Format=vmdk,UserBucket={S3Bucket=my-bucket,S3Key=nixos.vmdk}"
```

### Local VM Testing

```bash
# Build QCOW2 image
nix build .#qemu

# Run with QEMU
qemu-system-x86_64 -hda ./result/nixos.qcow2 -m 2G -enable-kvm
```

### Development Environment Testing

```bash
# Build full development VM
nix build .#development-vm

# Build lightweight development VM
nix build .#development-minimal

# Run development VM
qemu-system-x86_64 -hda ./result/nixos.qcow2 -m 4G -enable-kvm -display gtk
```

## Security Considerations

### Default Credentials

- **Default user**: `nixos`
- **Default password**: `nixos`
- **IMPORTANT: Change immediately** after deployment

### SSH Access

- SSH enabled by default on port 22
- Password authentication enabled initially
- **Recommended**: Set up SSH keys and disable password auth

### Firewall

- Basic firewall enabled
- Only SSH (22) open by default
- Customize `networking.firewall` for your needs

### Updates

```bash
# After deployment, update system
sudo nixos-rebuild switch --upgrade
sudo nix-collect-garbage -d
```

## Getting Started

1. **Choose your deployment target**
1. **Build the appropriate image**: `nix build .#image-name`
1. **Deploy following platform instructions**
1. **SSH into system**: `ssh nixos@your-ip`
1. **Change default password**: `passwd`
1. **Customize configuration** and rebuild

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-generators Documentation](https://github.com/nix-community/nixos-generators)
- [NixOS Cloud Images](https://nixos.org/download#cloud-images)
- [Deployment Best Practices](./ADVANCED-FEATURES.md)

---

**Ready to deploy NixOS anywhere!**
