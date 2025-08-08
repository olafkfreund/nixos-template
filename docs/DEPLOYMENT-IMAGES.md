# Deployment Images Guide

This NixOS template includes comprehensive deployment image generation using **nixos-generators**, providing ready-to-deploy images for various platforms and use cases.

## Quick Start

### Build a specific image:
```bash
# Cloud deployment images
nix build .#aws-ami          # Amazon EC2 AMI
nix build .#azure-vhd        # Microsoft Azure VHD
nix build .#gce-image        # Google Compute Engine
nix build .#do-image         # Digital Ocean

# Virtualization images
nix build .#vmware-image     # VMware VM
nix build .#virtualbox-ova   # VirtualBox OVA
nix build .#qemu-qcow2       # QEMU/KVM QCOW2

# Container images
nix build .#lxc-template     # LXC container

# Installation media
nix build .#live-iso         # Bootable live ISO

# ARM/Embedded
nix build .#rpi4-sd-image    # Raspberry Pi 4 SD card

# Specialized images
nix build .#development-vm   # Development environment
nix build .#production-server # Production server
```

### List all available images:
```bash
nix flake show | grep "packages.*-image\|packages.*-ami\|packages.*-iso"
```

## Available Deployment Images

### Cloud Platforms

#### **AWS AMI** (`aws-ami`)
- **Format**: Amazon Machine Image
- **Use Case**: EC2 instance deployment
- **Features**: EC2 metadata service, EBS-optimized, cloud-init
- **Deploy**: Upload to AWS AMI and launch EC2 instances

#### **Azure VHD** (`azure-vhd`) 
- **Format**: Virtual Hard Disk
- **Use Case**: Azure Virtual Machine deployment
- **Features**: Azure agent, cloud-init, optimized for Azure
- **Deploy**: Upload to Azure storage and create VM

#### **Google Cloud Image** (`gce-image`)
- **Format**: GCE-compatible image
- **Use Case**: Google Compute Engine deployment
- **Features**: GCE metadata service, automatic updates
- **Deploy**: Upload to GCP and create instances

#### **Digital Ocean Image** (`do-image`)
- **Format**: Digital Ocean compatible
- **Use Case**: Digital Ocean Droplet deployment
- **Features**: DO agent, optimized networking
- **Deploy**: Upload as custom image

### Virtualization

#### **VMware Image** (`vmware-image`)
- **Format**: VMware VMDK
- **Use Case**: VMware Workstation/vSphere
- **Features**: VMware Tools, paravirtualized drivers
- **Deploy**: Import into VMware environment

#### **VirtualBox OVA** (`virtualbox-ova`)
- **Format**: Open Virtualization Appliance
- **Use Case**: VirtualBox deployment
- **Features**: Guest additions, shared folders support
- **Deploy**: Import OVA file into VirtualBox

#### **QEMU QCOW2** (`qemu-qcow2`)
- **Format**: QCOW2 disk image
- **Use Case**: QEMU/KVM, Proxmox, OpenStack
- **Features**: Virtio drivers, SPICE support
- **Deploy**: Use with QEMU/KVM hypervisors

### Containers

#### **LXC Template** (`lxc-template`)
- **Format**: LXC container template
- **Use Case**: LXC/LXD containers, Proxmox CT
- **Features**: Container-optimized, minimal overhead
- **Deploy**: Import into LXC/LXD or Proxmox

### Installation Media

#### **Live ISO** (`live-iso`)
- **Format**: Bootable ISO image
- **Use Case**: Installation, recovery, testing
- **Features**: UEFI/BIOS boot, persistent storage
- **Deploy**: Burn to USB/DVD or boot from ISO

### ARM/Embedded

#### **Raspberry Pi 4 SD Image** (`rpi4-sd-image`)
- **Format**: SD card image for RPi4
- **Use Case**: Raspberry Pi 4 deployment
- **Features**: ARM64 kernel, RPi4 optimizations
- **Deploy**: Flash to SD card (8GB minimum)

### Specialized Images

#### **Development VM** (`development-vm`)
- **Format**: QCOW2 with development tools
- **Use Case**: Local development, testing
- **Features**: 
  - Full development stack (Node.js, Python, Rust)
  - Docker and Kubernetes tools
  - Monitoring enabled
  - VSCode and editors
- **Deploy**: Run locally with QEMU/KVM

#### **Production Server** (`production-server`)
- **Format**: QCOW2 hardened server
- **Use Case**: Production server deployment
- **Features**:
  - Security hardening (AppArmor, fail2ban, audit)
  - Comprehensive monitoring
  - Server packages (nginx, PostgreSQL)
  - Firewall configuration
- **Deploy**: Deploy to production hypervisors

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
nix build .#aws-ami

# Upload to AWS (requires AWS CLI)
aws ec2 import-image --description "NixOS Template" --disk-containers "Description=NixOS,Format=vmdk,UserBucket={S3Bucket=my-bucket,S3Key=nixos.vmdk}"
```

### Local VM Testing
```bash
# Build QCOW2 image
nix build .#qemu-qcow2

# Run with QEMU
qemu-system-x86_64 -hda ./result/nixos.qcow2 -m 2G -enable-kvm
```

### Raspberry Pi Deployment
```bash
# Build SD image
nix build .#rpi4-sd-image

# Flash to SD card (Linux)
sudo dd if=./result/sd-image/nixos-sd-image-*.img of=/dev/sdX bs=4M status=progress
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
2. **Build the appropriate image**: `nix build .#image-name`
3. **Deploy following platform instructions**
4. **SSH into system**: `ssh nixos@your-ip`
5. **Change default password**: `passwd`
6. **Customize configuration** and rebuild

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-generators Documentation](https://github.com/nix-community/nixos-generators)
- [NixOS Cloud Images](https://nixos.org/download#cloud-images)
- [Deployment Best Practices](./ADVANCED-FEATURES.md)

---

**Ready to deploy NixOS anywhere!**