# Virtualization Configuration

This directory contains NixOS modules for comprehensive virtualization support including containers, virtual machines, and management applications. The modules provide enterprise-grade virtualization capabilities with security and performance optimizations.

## Modules

### podman.nix

Rootless container platform with Docker compatibility and comprehensive tooling.

#### Features

**Container Platform**:

- Rootless Podman with Docker compatibility
- OCI-compliant container runtime
- Comprehensive security policies
- Automatic container management

**Networking**:

- Netavark backend for modern networking
- Custom network configuration
- DNS and registry management
- Firewall integration

**Storage Management**:

- Configurable storage drivers
- Multiple storage pool support
- Automatic cleanup and pruning
- Performance optimization

#### Configuration

Enable Podman containers:

```nix
modules.virtualization.podman = {
  enable = true;

  # Docker compatibility
  dockerCompat = true;

  # Rootless configuration
  rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Additional tools
  additionalTools = {
    buildah = true;
    skopeo = true;
    podman-compose = true;
    podman-tui = true;
  };
};
```

#### Advanced Features

**Registry Configuration**:

```nix
modules.virtualization.podman = {
  registries = {
    search = [
      "registry.fedoraproject.org"
      "registry.access.redhat.com"
      "docker.io"
      "quay.io"
    ];
    insecure = [];  # HTTP registries
    block = [];     # Blocked registries
  };
};
```

**Auto-Update**:

```nix
modules.virtualization.podman = {
  autoUpdate = {
    enable = true;
    onCalendar = "daily";
  };
};
```

### libvirt.nix

Full KVM/QEMU virtualization with libvirt management layer.

#### Features

**Virtualization Platform**:

- QEMU/KVM hypervisor
- UEFI firmware support (OVMF)
- Software TPM emulation
- Nested virtualization

**Networking**:

- NAT and bridge networking
- Custom network pools
- DHCP and DNS services
- Advanced routing

**Storage Management**:

- Multiple storage pools
- Various storage backends
- Snapshot support
- Live migration capabilities

#### Configuration

Enable KVM virtualization:

```nix
modules.virtualization.libvirt = {
  enable = true;

  # QEMU configuration
  qemu = {
    ovmf.enable = true;     # UEFI support
    swtpm.enable = true;    # TPM support
  };

  # Networking
  networking = {
    defaultNetwork = true;
    bridgeInterface = "enp0s31f6";  # Optional bridging
  };

  # Storage pools
  storage.pools = [
    {
      name = "default";
      type = "dir";
      path = "/var/lib/libvirt/images";
    }
    {
      name = "nvme";
      type = "dir";
      path = "/fast/storage/vms";
    }
  ];

  # User access
  users = [ "username" ];
};
```

#### Advanced Configuration

**GPU Passthrough**:

```nix
modules.virtualization.libvirt = {
  # Enable IOMMU and VFIO
  # Additional kernel parameters set automatically
  extraConfig = ''
    # GPU isolation configuration
    isolate_gpu = 1
  '';
};
```

**Performance Tuning**:

```nix
boot.kernelParams = [
  "hugepagesz=2M"
  "hugepages=4096"  # 8GB huge pages
  "intel_iommu=on"  # IOMMU for passthrough
];
```

### virt-manager.nix

Virtual machine management applications for different desktop environments.

#### Features

**Management Applications**:

- virt-manager (GTK-based, universal)
- GNOME Boxes (GNOME native)
- virt-viewer (console access)
- Cockpit machines (web-based)

**Remote Management**:

- SSH-based remote connections
- TLS encrypted connections
- Web-based management interface

**Desktop Integration**:

- Proper MIME type associations
- Desktop environment specific features
- File manager integration

#### Configuration

Enable VM management:

```nix
modules.virtualization.virt-manager = {
  enable = true;

  # Applications
  applications = {
    virt-manager = true;      # Universal GTK manager
    gnome-boxes = true;       # GNOME native
    virt-viewer = true;       # Console viewer
    cockpit-machines = false; # Web interface
  };

  # Remote connections
  remoteConnections = {
    enable = true;
    ssh = true;
  };

  # Desktop integration
  integrations = {
    nautilus = true;   # GNOME Files integration
    dolphin = false;   # KDE Dolphin integration
  };
};
```

#### Cockpit Web Interface

For web-based management:

```nix
modules.virtualization.virt-manager = {
  applications.cockpit-machines = true;
};
```

Access via: `https://localhost:9090`

## Complete Virtualization Stack

For full virtualization capabilities:

```nix
# Enable all virtualization modules
modules.virtualization = {
  # Containers
  podman.enable = true;

  # Virtual machines
  libvirt.enable = true;

  # Management applications
  virt-manager.enable = true;
};
```

## Performance Optimization

### System Tuning

**CPU Configuration**:

```nix
# Enable all CPU virtualization features
boot.kernelModules = [
  "kvm-intel" "kvm-amd"
  "vhost-net" "vfio"
];

boot.kernelParams = [
  "intel_iommu=on"
  "amd_iommu=on"
  "hugepagesz=2M"
  "hugepages=2048"
];
```

**Memory Management**:

```nix
# Sysctl tuning for virtualization
boot.kernel.sysctl = {
  "vm.swappiness" = 10;
  "vm.nr_hugepages" = 2048;
  "net.bridge.bridge-nf-call-iptables" = 0;
};
```

### Storage Optimization

**Fast Storage**:

- Use NVMe SSDs for VM images
- Configure appropriate I/O schedulers
- Enable host-side caching where appropriate

**Storage Pools**:

- Separate pools for different use cases
- Raw vs qcow2 based on needs
- Snapshot and backup strategies

### Network Performance

**Bridge Networking**:

```nix
networking.bridges.br0.interfaces = [ "enp0s31f6" ];
```

**SR-IOV** (for advanced setups):

- Hardware-level network virtualization
- Direct hardware access for VMs
- Minimal host networking overhead

## Security Considerations

### Container Security

**Rootless Containers**:

- Run without root privileges
- User namespace isolation
- SELinux/AppArmor integration

**Registry Security**:

- Image signing verification
- Registry authentication
- Network policy enforcement

### VM Security

**Isolation**:

- Hardware-enforced isolation
- UEFI Secure Boot support
- TPM for attestation

**Network Security**:

- Firewall integration
- Network segmentation
- VPN and encrypted connections

## User Setup

### Container Users

Users are automatically configured for containers:

```bash
# Container management
podman ps
podman run -it fedora bash

# Docker compatibility
docker ps
docker run hello-world

# Container development
buildah bud -t myapp .
skopeo copy docker://alpine:latest containers-storage:alpine:local
```

### VM Users

For virtual machine management:

```bash
# virt-manager GUI
virt-manager

# Command line management
virsh list --all
virsh start myvm

# GNOME Boxes
gnome-boxes

# Remote connections
virt-manager -c qemu+ssh://user@remote/system
```

## Troubleshooting

### Container Issues

**Permission Problems**:

```bash
# Check user namespaces
cat /proc/sys/user/max_user_namespaces

# Verify cgroups
systemctl status user@$(id -u).service
```

**Network Issues**:

```bash
# Check container networking
podman network ls
podman network inspect podman

# Firewall conflicts
firewall-cmd --list-all
```

### VM Issues

**KVM Not Available**:

```bash
# Check KVM support
lscpu | grep Virtualization
ls -l /dev/kvm

# Verify modules
lsmod | grep kvm
```

**Networking Problems**:

```bash
# Check libvirt networks
virsh net-list --all
virsh net-start default

# Bridge configuration
ip addr show br0
brctl show
```

**Performance Issues**:

```bash
# Check hugepages
cat /proc/meminfo | grep Huge

# Monitor VM performance
virsh domstats myvm
```

## Integration Examples

### Development Workflow

**Container Development**:

```bash
# Development container
podman run -it --rm -v $(pwd):/work fedora bash

# Build and test
buildah bud -t myapp .
podman run --rm myapp test

# Deploy with compose
podman-compose up -d
```

**VM Development**:

```bash
# Create development VM
virt-install --name devvm --ram 4096 --vcpus 2 \
  --disk size=20 --os-variant fedora38 \
  --network bridge=br0 --cdrom fedora.iso
```

### Production Deployment

**Container Services**:

```systemd
[Unit]
Description=My App Container
After=network.target

[Service]
ExecStart=podman run --name myapp -p 8080:80 myapp:latest
ExecStop=podman stop myapp
Restart=always

[Install]
WantedBy=multi-user.target
```

**VM Services**:

```bash
# Autostart VMs
virsh autostart production-vm

# VM snapshots for backup
virsh snapshot-create-as production-vm backup-$(date +%Y%m%d)
```

## Monitoring

### Container Monitoring

```bash
# Resource usage
podman stats

# System events
journalctl -u podman.service -f

# Container logs
podman logs -f mycontainer
```

### VM Monitoring

```bash
# VM resource usage
virsh domstats --all

# Host resources
virsh nodeinfo
virsh freecell

# Network monitoring
virsh domifstat vmname vnet0
```

## Backup and Migration

### Container Backup

```bash
# Export containers
podman export mycontainer > container-backup.tar

# Save images
podman save myapp:latest > myapp-backup.tar

# Backup volumes
rsync -av ~/.local/share/containers/ /backup/containers/
```

### VM Backup

```bash
# VM snapshots
virsh snapshot-create-as vmname snapshot1

# Export VM
virsh dumpxml vmname > vmname.xml
cp /var/lib/libvirt/images/vmname.qcow2 /backup/

# Live migration
virsh migrate --live vmname qemu+ssh://dest/system
```
