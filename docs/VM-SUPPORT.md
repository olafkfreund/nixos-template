# Virtual Machine Support

This NixOS template includes comprehensive support for running in virtual machines with automatic detection and optimization for different hypervisors.

## Supported Virtual Machine Platforms

- **QEMU/KVM** - Complete support with VirtIO optimizations
- **VirtualBox** - Full guest additions integration
- **VMware** - VMware Tools integration
- **Hyper-V** - Microsoft Hyper-V guest services
- **Xen** - Xen paravirtualization support

## Quick Start for VMs

### 1. Automatic Detection and Setup

```bash
# Detect your VM environment
just detect-vm

# Initialize VM-optimized configuration (auto-detects VM type)
just init-vm my-vm-hostname

# Or specify VM type explicitly
just init-vm my-vm-hostname qemu
just init-vm my-vm-hostname virtualbox
```

### 2. Manual Configuration

Add VM guest support to any existing host:

```nix
# In your host's configuration.nix
modules.virtualization.vm-guest = {
  enable = true;
  type = "auto";  # or "qemu", "virtualbox", "vmware", "hyperv"
  
  optimizations = {
    performance = true;
    graphics = true;
    networking = true;
    storage = true;
  };
  
  guestTools = {
    enable = true;
    clipboard = true;
    folderSharing = true;
    timeSync = true;
  };
};
```

## Platform-Specific Features

### QEMU/KVM

**Optimizations**:
- VirtIO drivers for maximum performance
- SPICE guest agent for clipboard/display
- Paravirtualized network and storage
- Serial console support
- Memory ballooning

**Guest Tools**:
- Automatic screen resolution adjustment
- Clipboard sharing (bidirectional)
- File sharing between host and guest
- Time synchronization

**Example QEMU Launch**:
```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp 4 \
  -drive file=nixos.qcow2,format=qcow2 \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -vga qxl \
  -spice port=5930,addr=127.0.0.1,disable-ticketing \
  -device virtio-serial \
  -chardev spicevmc,id=vdagent,name=vdagent \
  -device virtserialport,chardev=vdagent,name=com.redhat.spice.0
```

### VirtualBox

**Optimizations**:
- VirtualBox Guest Additions integration
- Shared folders support
- 3D acceleration
- Seamless mode support

**Guest Tools**:
- Bidirectional clipboard
- Shared folders (automatically mounted)
- Dynamic display resolution
- Mouse integration

**Setup Requirements**:
```bash
# On host system, ensure VirtualBox Guest Additions ISO is available
# Enable 3D acceleration in VM settings
# Add shared folders in VM settings
# Enable bidirectional clipboard
```

### VMware

**Optimizations**:
- VMware Tools (open-vm-tools) integration
- VMXNET3 network driver
- PVSCSI storage driver
- VMware graphics driver

**Guest Tools**:
- Clipboard sharing
- Drag and drop support
- Shared folders
- Unity mode support

### Hyper-V

**Optimizations**:
- Hyper-V Integration Services
- Synthetic network adapters
- Dynamic memory
- Generation 2 VM support

**Guest Tools**:
- Enhanced session mode
- Copy/paste integration
- Time synchronization
- Heartbeat service

## VM-Specific Configurations

### Pre-built VM Configurations

The template includes ready-to-use VM configurations:

```bash
# Available VM configurations
just build qemu-vm           # QEMU/KVM optimized
just build virtualbox-vm     # VirtualBox optimized
just build microvm           # Minimal footprint VM
```

### Network Configuration

VMs are configured with flexible networking:

```nix
# Automatic interface detection for common VM setups
networking.interfaces = {
  enp0s3.useDHCP = true;  # VirtualBox NAT
  enp0s8.useDHCP = true;  # VirtualBox Host-only
  ens3.useDHCP = true;    # QEMU default
  eth0.useDHCP = true;    # Legacy naming
};
```

### Storage Optimization

VM storage is optimized for each platform:

```nix
fileSystems."/" = {
  options = [ "noatime" "nodiratime" ];  # Reduce I/O in VMs
};

# VirtIO block device support
boot.initrd.availableKernelModules = [
  "virtio_pci" "virtio_blk" "virtio_scsi"
  "ata_piix" "ahci" "sd_mod"
];
```

## Development Workflow in VMs

### 1. Quick VM Setup

```bash
# Clone template
git clone <template-url> my-nixos-vm
cd my-nixos-vm

# Auto-setup for current VM
just init-vm $(hostname) auto

# Test configuration
just test $(hostname)

# Apply configuration  
just switch $(hostname)
```

### 2. VM-Specific Development

```bash
# Enable development tools in VM
modules.development = {
  enable = true;
  languages = [ "nix" "rust" "go" "python" ];
};

# VM-friendly editors
programs.vscode = {
  enable = true;
  extensions = [
    "jnoortheen.nix-ide"
    "ms-vscode-remote.remote-ssh"
  ];
};
```

### 3. Shared Development Environment

```nix
# Mount host directories in VM
fileSystems."/host-projects" = {
  device = "host_shared";
  fsType = "9p";  # QEMU 9p sharing
  options = [ "trans=virtio" "version=9p2000.L" "rw" ];
};

# VirtualBox shared folders
fileSystems."/host-projects" = {
  device = "projects";
  fsType = "vboxsf";
  options = [ "rw" "uid=1000" "gid=100" ];
};
```

## Performance Tuning

### Memory Optimization

```nix
# VM-specific memory settings
boot.kernel.sysctl = {
  "vm.swappiness" = 10;           # Reduce swapping
  "vm.dirty_ratio" = 15;          # Faster writeback
  "vm.dirty_background_ratio" = 5;
};

# Disable memory-intensive services
services = {
  thermald.enable = false;      # No thermal management needed
  power-profiles-daemon.enable = false;
  bluetooth.enable = false;     # Usually not needed in VMs
};
```

### CPU Optimization

```nix
# VM-friendly CPU settings
powerManagement.enable = false;  # Disable power management
services.irqbalance.enable = true;  # Better IRQ distribution

# VM-specific kernel parameters
boot.kernelParams = [
  "elevator=noop"               # Better for VirtIO
  "transparent_hugepage=madvise"
  "console=tty0"
  "console=ttyS0,115200"        # Serial console
];
```

### Graphics Optimization

```nix
# VM graphics settings
hardware.graphics = {
  enable = true;
  extraPackages = with pkgs; [
    mesa
    virglrenderer  # 3D acceleration for QEMU
  ];
};

# Disable heavy desktop effects
services.xserver.desktopManager.gnome = {
  enable = true;
  extraGSettingsOverrides = ''
    [org.gnome.desktop.interface]
    enable-animations=false
    
    [org.gnome.desktop.background]
    picture-options='wallpaper'
    primary-color='#000000'
  '';
};
```

## Troubleshooting

### Common Issues

**VM not detected properly**:
```bash
# Manual detection
systemd-detect-virt

# Check DMI information
cat /sys/class/dmi/id/product_name
cat /sys/class/dmi/id/sys_vendor

# Check loaded modules
lsmod | grep -E "(virtio|vbox|vmw)"
```

**Guest tools not working**:
```bash
# QEMU/KVM
systemctl status qemu-guest-agent
systemctl status spice-vdagentd

# VirtualBox
systemctl status virtualbox-guest

# Check kernel modules
lsmod | grep vboxguest
lsmod | grep virtio
```

**Network issues**:
```bash
# Check interface names
ip link show

# Test connectivity
ping -c 3 8.8.8.8

# Check NetworkManager
systemctl status NetworkManager
nmcli device status
```

**Graphics problems**:
```bash
# Check graphics drivers
lspci | grep VGA
glxinfo | grep renderer

# For VirtualBox
VBoxClient --display
VBoxClient --clipboard
```

### Performance Issues

**Slow boot**:
```nix
# Reduce boot timeout
boot.loader.grub.timeout = 1;

# Disable unnecessary services
services.udisks2.enable = false;
services.gnome.evolution-data-server.enable = false;
```

**High CPU usage**:
```bash
# Check running processes
htop

# Disable CPU-intensive services
systemctl disable bluetooth
systemctl disable cups
```

**Memory pressure**:
```nix
# Reduce memory usage
services.gnome.gnome-keyring.enable = false;
services.accounts-daemon.enable = false;
programs.gnome-disks.enable = false;
```

## Advanced VM Features

### Nested Virtualization

```nix
# Enable nested virtualization in QEMU VMs
boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
boot.kernelParams = [ "kvm-intel.nested=1" "kvm-amd.nested=1" ];

# Enable libvirt in VM
modules.virtualization.libvirt.enable = true;
```

### GPU Passthrough (QEMU)

```nix
# Enable VFIO for GPU passthrough
boot.kernelParams = [ 
  "intel_iommu=on" 
  "vfio-pci.ids=10de:1234,10de:5678"  # GPU vendor:device IDs
];

boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];
```

### Cloud-Init Support

```nix
# Enable cloud-init for automated VM setup
services.cloud-init = {
  enable = true;
  settings = {
    datasource_list = [ "NoCloud" "ConfigDrive" ];
  };
};

# Resize root partition automatically
virtualisation.growPartition = true;
```

## Production VM Deployment

### Automated VM Creation

```bash
# Build VM disk image
nix build .#nixosConfigurations.my-vm.config.system.build.vm

# Create cloud image
nix build .#nixosConfigurations.my-vm.config.system.build.digitalOceanImage

# Generate installation ISO
nix build .#nixosConfigurations.my-vm.config.system.build.isoImage
```

### VM Template Creation

```bash
# Create template VM
just init-vm template-vm qemu

# Customize for your needs
# Build and sysprep
just build template-vm

# Convert to template
qemu-img convert -O qcow2 -c nixos.qcow2 nixos-template.qcow2
```

### Scaling and Management

```nix
# Multiple VM management
systemd.services."vm-manager" = {
  description = "VM Management Service";
  serviceConfig = {
    ExecStart = "${pkgs.libvirt}/bin/virsh list --all";
    Type = "oneshot";
  };
};
```

## Integration with Host Systems

### File Sharing

**QEMU 9P sharing**:
```bash
# Host side
qemu-system-x86_64 -virtfs local,path=/host/share,mount_tag=hostshare,security_model=passthrough,id=hostshare

# Guest side in configuration.nix
fileSystems."/mnt/host" = {
  device = "hostshare";
  fsType = "9p";
  options = [ "trans=virtio" "version=9p2000.L" ];
};
```

**VirtualBox shared folders**:
```nix
# Automatically mount VirtualBox shared folders
fileSystems."/media/sf_shared" = {
  device = "shared";
  fsType = "vboxsf";
  options = [ "rw" "uid=1000" "gid=100" ];
};

users.users.myuser.extraGroups = [ "vboxsf" ];
```

### Clipboard Integration

All VM platforms support bidirectional clipboard sharing when properly configured with guest tools.

### Network Bridging

```nix
# Bridge VM to host network
networking.bridges.br0.interfaces = [ "enp0s3" ];
networking.interfaces.br0.useDHCP = true;
```

This comprehensive VM support ensures the NixOS template works seamlessly across all major virtualization platforms, with automatic detection, optimization, and platform-specific integrations.