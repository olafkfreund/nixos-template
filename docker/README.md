# NixOS VM Builder Docker Image

A Docker-based solution for building NixOS virtual machines without installing Nix locally. Perfect for Windows users who want to try NixOS.

## Quick Start

### Using Pre-built Image (Recommended)

```bash
# Pull the image
docker pull ghcr.io/your-repo/nixos-vm-builder:latest

# Build a desktop VM
docker run --rm -v "$(pwd):/workspace" ghcr.io/your-repo/nixos-vm-builder:latest virtualbox --template desktop

# Build a server VM for Hyper-V
docker run --rm -v "$(pwd):/workspace" ghcr.io/your-repo/nixos-vm-builder:latest hyperv --template server
```

### Building the Image Locally

```bash
# Clone the repository
git clone https://github.com/your-repo/nixos-template
cd nixos-template/docker

# Build the Docker image
docker build -t nixos-vm-builder .

# Use the locally built image
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder virtualbox --template desktop
```

## Available VM Templates

| Template      | Description                          | Disk Size | Memory | Use Case                       |
| ------------- | ------------------------------------ | --------- | ------ | ------------------------------ |
| `desktop`     | Full GNOME desktop with applications | 20GB      | 4GB    | General desktop use, new users |
| `server`      | Headless server configuration        | 40GB      | 2GB    | Servers, CLI learning          |
| `gaming`      | Gaming-optimized with Steam          | 80GB      | 8GB    | Gaming, performance testing    |
| `minimal`     | Lightweight CLI-only system          | 10GB      | 1GB    | Learning NixOS basics          |
| `development` | Full development environment         | 60GB      | 6GB    | Software development           |

## Supported VM Formats

| Format       | File Extension | Platform Support       | Description          |
| ------------ | -------------- | ---------------------- | -------------------- |
| `virtualbox` | `.ova`         | Windows, macOS, Linux  | VirtualBox appliance |
| `hyperv`     | `.vhdx`        | Windows Pro/Enterprise | Hyper-V virtual disk |
| `vmware`     | `.vmdk`        | Windows, macOS, Linux  | VMware virtual disk  |
| `qemu`       | `.qcow2`       | Linux, Windows, macOS  | QEMU/KVM image       |

## Command Line Interface

### Basic Usage

```bash
# Build specific template and format
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder [FORMAT] [OPTIONS]

# Show help
docker run --rm nixos-vm-builder --help

# List available templates
docker run --rm nixos-vm-builder --list-templates
```

### Build Examples

```bash
# Build VirtualBox desktop VM
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder virtualbox --template desktop

# Build Hyper-V server VM with custom specs
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder hyperv \
  --template server \
  --disk-size 81920 \
  --memory 4096 \
  --vm-name my-server

# Build all formats for gaming template
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder all --template gaming

# Build with custom configuration
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder virtualbox \
  --config /workspace/my-config.nix
```

### Command Line Options

| Option                 | Description                | Example                          |
| ---------------------- | -------------------------- | -------------------------------- |
| `-c, --config FILE`    | Custom NixOS configuration | `--config /workspace/server.nix` |
| `-o, --output DIR`     | Output directory           | `--output /workspace/builds`     |
| `-s, --disk-size SIZE` | Disk size in MB            | `--disk-size 40960`              |
| `-m, --memory SIZE`    | Memory size in MB          | `--memory 8192`                  |
| `-n, --vm-name NAME`   | VM name                    | `--vm-name my-nixos-vm`          |
| `-t, --template NAME`  | Use predefined template    | `--template desktop`             |
| `--validate-only`      | Only validate config       | `--validate-only`                |

## Directory Structure

```
docker/
├── Dockerfile              # Main Docker image definition
├── README.md               # This file
├── scripts/
│   └── build-vm.sh         # Main build script
└── templates/
    ├── desktop-template.nix     # Desktop environment
    ├── server-template.nix      # Headless server
    ├── gaming-template.nix      # Gaming optimized
    ├── minimal-template.nix     # Minimal installation
    └── development-template.nix # Development environment
```

## Docker Image Details

### Base Image

- **Base**: `nixos/nix:latest`
- **Size**: ~2GB (layered image)
- **Architecture**: `linux/amd64`, `linux/arm64`

### Included Tools

- Nix package manager with flakes support
- nixos-generators for VM building
- Build scripts and templates
- JSON processing tools (jq)
- Standard Unix utilities

### Environment Variables

- `NIX_CONF_DIR=/root/.config/nix`
- `NIXOS_GENERATORS_VERSION=1.8.0`
- Working directory: `/workspace`

## Custom Templates

### Creating Custom Templates

1. **Create template file** in `/workspace`:

   ```nix
   # my-template.nix
   { config, pkgs, lib, ... }:
   {
     imports = [
       <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
     ];

     system.stateVersion = "24.05";

     environment.systemPackages = with pkgs; [
       firefox
       git
       vim
     ];

     users.users.nixos = {
       isNormalUser = true;
       extraGroups = [ "wheel" ];
       password = "nixos";
     };
   }
   ```

1. **Build with custom template**:

   ```bash
   docker run --rm -v "$(pwd):/workspace" nixos-vm-builder virtualbox \
     --config /workspace/my-template.nix
   ```

### Template Best Practices

- **Always include VM guest tools** for your target platform
- **Set system.stateVersion** to match NixOS release
- **Create default user** with appropriate groups
- **Enable SSH** for remote access (servers)
- **Optimize for VM** environment (disable unnecessary services)

## Build Process

### Build Steps

1. **Validation**: Check template syntax and dependencies
1. **Generation**: Use nixos-generators to create VM image
1. **Optimization**: Apply VM-specific optimizations
1. **Packaging**: Create final VM file (OVA, VHDX, etc.)
1. **Metadata**: Generate JSON with VM information

### Build Performance

| Template    | Build Time | Output Size | Memory Usage |
| ----------- | ---------- | ----------- | ------------ |
| Minimal     | 15-30 min  | 2-4 GB      | 2GB RAM      |
| Desktop     | 30-60 min  | 8-12 GB     | 4GB RAM      |
| Server      | 20-45 min  | 6-10 GB     | 3GB RAM      |
| Gaming      | 45-90 min  | 15-25 GB    | 6GB RAM      |
| Development | 40-75 min  | 12-20 GB    | 5GB RAM      |

_Build times depend on internet speed and system performance_

## Troubleshooting

### Common Issues

**Docker Permission Errors**:

```bash
# On Linux, ensure user is in docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**Out of Disk Space**:

```bash
# Check Docker disk usage
docker system df

# Clean up Docker cache
docker system prune -f

# Increase Docker Desktop disk allocation (Windows/macOS)
```

**Build Timeouts**:

```bash
# Increase Docker memory allocation
# Use faster internet connection
# Try minimal template first
```

**VM Won't Boot**:

- Verify virtualization is enabled in BIOS/UEFI
- Check VM memory allocation meets minimum requirements
- Try different VM format for your platform

### Debug Mode

```bash
# Enable debug output
docker run --rm -v "$(pwd):/workspace" nixos-vm-builder virtualbox \
  --template desktop \
  --debug

# Interactive shell in container
docker run -it --rm -v "$(pwd):/workspace" nixos-vm-builder bash
```

## Development

### Building Development Image

```bash
# Build with development tools
docker build -f Dockerfile.dev -t nixos-vm-builder-dev .

# Mount source code for development
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/../:/source" \
  nixos-vm-builder-dev bash
```

### Testing Changes

```bash
# Test build script locally
./scripts/build-vm.sh virtualbox --template minimal --validate-only

# Test all templates
for template in desktop server gaming minimal development; do
  ./scripts/build-vm.sh virtualbox --template $template --validate-only
done
```

## GitHub Actions Integration

The repository includes GitHub Actions for automated builds:

- **Trigger**: Push to main, PR, schedule, manual
- **Matrix**: All templates × all formats
- **Artifacts**: VM images and checksums
- **Releases**: Automated release creation
- **Registry**: Docker image publishing

See `.github/workflows/build-vm-images.yml` for details.

## License

This project is licensed under the GNU GPL v3 - see the [LICENSE](../LICENSE) file for details.

## Contributing

1. Fork the repository
1. Create a feature branch
1. Make your changes
1. Test with multiple templates
1. Submit a pull request

## Support

- **Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Wiki**: Community documentation
- **Discord**: Real-time community chat

Built with ❄️ NixOS
