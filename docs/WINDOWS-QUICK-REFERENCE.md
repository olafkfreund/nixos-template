# Windows Quick Reference - NixOS VMs

Quick reference for Windows users wanting to try NixOS virtual machines.

## 🚀 Quick Start (2 Minutes)

### Method 1: Pre-built VMs (Easiest)

```powershell
# 1. Download VirtualBox: https://www.virtualbox.org/
# 2. Get VM: https://github.com/olafkfreund/nixos-template/releases
# 3. Import OVA file in VirtualBox
# 4. Login: nixos / nixos
```

### Method 2: Build with Docker

```powershell
# 1. Install Docker Desktop
# 2. Build VM
mkdir C:\NixOS-VMs
cd C:\NixOS-VMs
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest virtualbox --template desktop
```

## 📋 VM Templates

| Template        | Size | Description   | Best For    |
| --------------- | ---- | ------------- | ----------- |
| **Desktop**     | 20GB | GNOME + apps  | New users   |
| **Gaming**      | 80GB | Steam + tools | Gamers      |
| **Development** | 60GB | Full dev env  | Programmers |
| **Server**      | 40GB | CLI only      | Servers     |
| **Minimal**     | 10GB | Basic system  | Learning    |

## 🖥️ VM Platform Support

| Platform       | File Format | Windows Version |
| -------------- | ----------- | --------------- |
| **VirtualBox** | `.ova`      | All Windows     |
| **Hyper-V**    | `.vhdx`     | Pro/Enterprise  |
| **VMware**     | `.vmdk`     | All Windows     |
| **QEMU**       | `.qcow2`    | Advanced users  |

## ⚡ Common Commands

```powershell
# List available templates
docker run --rm ghcr.io/olafkfreund/nixos-vm-builder:latest --list-templates

# Build specific template
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest [FORMAT] --template [TEMPLATE]

# Build all formats
docker run --rm -v "${PWD}:/workspace" ghcr.io/olafkfreund/nixos-vm-builder:latest all --template desktop
```

## 🔧 First Steps in NixOS

```bash
# Change password (IMPORTANT!)
passwd

# Update system
sudo nixos-rebuild switch --upgrade

# Search packages
nix search firefox

# System info
nixos-version
```

## 🆘 Troubleshooting

| Problem          | Solution                      |
| ---------------- | ----------------------------- |
| VM won't boot    | Enable virtualization in BIOS |
| Slow performance | Increase RAM to 4GB+          |
| No internet      | Use NAT networking            |
| Graphics issues  | Install VM guest tools        |

## 📖 Documentation

- **Complete Guide**: [docs/WINDOWS-HOWTO.md](WINDOWS-HOWTO.md)
- **Docker Details**: [docs/WINDOWS-VM-BUILDER.md](WINDOWS-VM-BUILDER.md)
- **Technical Docs**: [docker/README.md](../docker/README.md)

## 💡 Tips

- **Performance**: Allocate 4GB+ RAM for desktop VMs
- **Security**: Change default password immediately
- **Integration**: Use shared folders for file transfer
- **Learning**: Start with Desktop template, try others later
- **Support**: Join NixOS Discord for help

---

**Need detailed help?** See [Complete Windows How-To Guide](WINDOWS-HOWTO.md)

**Ready to start?** Download from [Releases](https://github.com/olafkfreund/nixos-template/releases) or build with Docker!
