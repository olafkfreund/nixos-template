# Modern NixOS Configuration Template

A sophisticated, modular NixOS configuration template using flakes, featuring:

- **100% Green CI** - Comprehensive validation ensuring reliability
- **VM Testing Ready** - Full desktop environment testing in VMs
- **Modular Architecture** - Organized, reusable modules
- **Home Manager Integration** - Declarative user environments
- **SOPS Secrets Management** - Encrypted secrets in Git
- **Multiple Host Support** - Desktop, laptop, server, VM configurations
- **GPU Support** - AMD, NVIDIA, Intel with gaming/AI optimizations
- **AI/Compute Ready** - CUDA, ROCm, OneAPI for machine learning
- **Development Tools** - Scripts and utilities for easy management
- **Custom Packages & Overlays** - Extend and customize packages
- **Boot Reliability** - Fixed VM systemd conflicts and boot issues
- **NixOS 25.05 Compatible** - Latest NixOS features and deprecation fixes

## Quick Start

### New NixOS Users (Automated Setup)

For first-time users or quick deployments, use our automated setup scripts:

```bash
# Clone this template
git clone <your-repo> my-nixos-config
cd my-nixos-config

# Check if your system is ready
./scripts/check-prerequisites.sh

# Option 1: Quick setup with smart defaults (recommended for beginners)
./scripts/quick-setup.sh

# Option 2: Full interactive setup with all options
./scripts/nixos-setup.sh
```

The setup scripts will:

- Detect your hardware and VM environment
- Generate appropriate configurations
- Guide you through customization options
- Test and deploy the configuration
- Provide next steps and usage instructions

**[See detailed setup guide →](docs/SETUP.md)**

### Advanced Users (Manual Setup)

For users who prefer manual configuration:

```bash
# Clone this template
nix flake new my-nixos-config --template github:yourusername/nixos-template
cd my-nixos-config

# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hosts/$(hostname)/hardware-configuration.nix

# Customize your configuration
# Edit hosts/$(hostname)/configuration.nix and home.nix

# Build and switch
just switch

# Update flake inputs
just update-switch
```

## Project Structure

```
nixos-config/
├── flake.nix                 # Main flake configuration
├── flake.lock               # Reproducible input locks
├──
├── lib/                     # Custom utility functions
│   ├── default.nix         # Library exports
│   └── mkHost.nix          # Host builder utility
│
├── modules/                 # Reusable NixOS modules
│   ├── core/               # Essential system modules
│   │   ├── boot.nix        # Boot configuration
│   │   ├── locale.nix      # Localization
│   │   ├── networking.nix  # Network configuration
│   │   ├── nix.nix         # Nix settings
│   │   ├── security.nix    # Security settings
│   │   └── users.nix       # User management
│   ├── desktop/            # Desktop environment modules
│   │   ├── gnome.nix       # GNOME desktop
│   │   ├── audio.nix       # Audio configuration
│   │   └── fonts.nix       # Font configuration
│   ├── development/        # Development tool modules
│   │   └── git.nix         # Git configuration
│   ├── hardware/           # Hardware-specific modules
│   │   └── gpu/            # GPU configurations
│   │       ├── amd.nix     # AMD GPU support
│   │       ├── nvidia.nix  # NVIDIA GPU support
│   │       ├── intel.nix   # Intel GPU support
│   │       └── detection.nix # Auto-detection
│   ├── services/           # Service modules
│   └── virtualization/     # VM and container modules
│
├── hosts/                  # Per-host configurations
│   ├── common.nix          # Shared host configuration
│   ├── desktop-template/   # Desktop template configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── home.nix        # Home Manager config
│   ├── laptop-template/    # Laptop template configuration
│   ├── server-template/    # Server template configuration (AI/compute)
│   ├── qemu-vm/            # QEMU/KVM virtual machine
│   ├── virtualbox-vm/      # VirtualBox VM configuration
│   ├── microvm/            # Minimal MicroVM configuration
│   └── desktop-test/       # VM desktop testing environment
│
├── home/                   # Home Manager configurations
│   ├── profiles/           # Reusable user profiles
│   └── users/             # Per-user configurations
│
├── overlays/              # Package overlays
├── pkgs/                  # Custom packages
├── secrets/               # Encrypted secrets
├── scripts/               # Management and setup scripts
│   ├── nixos-setup.sh     # Full interactive setup wizard
│   ├── quick-setup.sh     # Quick setup with smart defaults
│   ├── check-prerequisites.sh # System validation
│   ├── detect-vm.sh       # VM environment detection
│   ├── setup-agenix.sh    # Secrets management setup
│   └── rebuild.sh         # Rebuild script
├── docs/                   # Documentation
│   ├── SETUP.md           # Comprehensive setup guide
│   ├── VM-SUPPORT.md      # Virtual machine documentation
│   └── GPU-CONFIGURATION.md # GPU setup guide
├──
├── justfile              # Task runner with convenient commands
└── README.md             # This file
```

## Available Commands

### Using just (Recommended)

```bash
just switch           # Build and switch to new configuration
just test            # Test configuration without switching
just boot            # Build configuration for next boot
just update          # Update flake inputs
just update-switch   # Update flake inputs and rebuild
just check           # Check flake for errors
just fmt             # Format Nix files
just clean           # Clean old generations
just shell           # Enter development shell
just info            # Show system information

# Host-specific commands
just switch desktop-template   # Switch configuration for 'desktop-template' host
just test server-template     # Test configuration for 'server-template' host

# VM and Testing Commands
just build-vm-image desktop-test    # Build VM image for desktop testing
just init-vm myhost qemu           # Initialize VM configuration
just list-vms                      # Show available VM configurations
just list-desktops                 # Show available desktop environments
just test-vm myhost                # Test VM configuration

# Desktop Environment Commands
just test-desktop gnome myhost     # Test specific desktop configuration
just list-users                    # Show available user templates
just init-user myhost developer    # Initialize user configuration from template

# Utility commands
just init-host myhost              # Initialize new host configuration
just diff                          # Show configuration differences
just show-inputs                   # Show flake input versions
```

### Setup Scripts (For New Users)

```bash
# Check system prerequisites (includes hardware detection)
./scripts/check-prerequisites.sh

# Quick automated setup
./scripts/quick-setup.sh

# Full interactive setup wizard
./scripts/nixos-setup.sh

# Hardware type detection
./scripts/detect-hardware.sh

# VM environment detection
./scripts/detect-vm.sh

# Setup secrets management
./scripts/setup-agenix.sh
```

### Management Scripts

```bash
# Rebuild script with advanced options
./scripts/rebuild.sh                    # Basic switch
./scripts/rebuild.sh test              # Test mode
./scripts/rebuild.sh --host server     # Specific host
./scripts/rebuild.sh --update switch   # Update and switch
```

### Using Nix Directly

```bash
# Build specific host
sudo nixos-rebuild switch --flake .#hostname

# Update flake inputs
nix flake update

# Check flake
nix flake check

# Enter development shell
nix develop
```

## Module System

This configuration uses a modular approach where features are organized into reusable modules.

### Enabling Modules

In your host configuration:

```nix
modules = {
  desktop = {
    gnome.enable = true;
    audio.enable = true;
    fonts.enable = true;
  };

  development = {
    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
    };
  };
};
```

### Creating Custom Modules

Add new modules in the `modules/` directory following the existing patterns.

## GPU Configuration

This template includes comprehensive GPU support with automatic detection and optimization profiles.

### Quick GPU Setup

The system can automatically detect and configure your GPU:

```nix
# In your host configuration
modules.hardware.gpu = {
  autoDetect = true;
  profile = "desktop";  # desktop, gaming, ai-compute, server-compute
};
```

### Manual GPU Configuration

For manual control, specify your GPU type:

```nix
# AMD GPU (desktop/gaming)
modules.hardware.gpu = {
  profile = "gaming";
  amd = {
    enable = true;
    gaming.enable = true;
  };
};

# NVIDIA GPU (AI/compute server)
modules.hardware.gpu = {
  profile = "ai-compute";
  nvidia = {
    enable = true;
    compute = {
      cuda = true;
      cudnn = true;
      containers = true;  # Docker GPU support
    };
  };
};

# Intel integrated graphics
modules.hardware.gpu = {
  profile = "desktop";
  intel = {
    enable = true;
    desktop.vaapi = true;
  };
};
```

### Supported Features

- **AMD**: ROCm for AI, Vulkan gaming, hardware acceleration
- **NVIDIA**: CUDA/cuDNN for AI, RTX features, PRIME for laptops
- **Intel**: VA-API acceleration, Arc/Xe compute, OneAPI

See [GPU Configuration Guide](docs/GPU-CONFIGURATION.md) for detailed setup instructions.

## Virtual Machine Testing

This template includes comprehensive VM testing capabilities for safe development and desktop environment testing.

### Quick VM Testing

```bash
# Build and run the desktop testing VM
just build-vm-image desktop-test
./result/bin/run-desktop-test-vm

# Login with: username=vm-user, password=nixos
```

### Available VM Configurations

- **desktop-test** - Full GNOME desktop for testing (with boot reliability fixes)
- **qemu-vm** - Basic QEMU VM configuration
- **virtualbox-vm** - VirtualBox-optimized configuration
- **microvm** - Minimal lightweight VM

### VM Management Commands

```bash
# List all VM configurations and their features
just list-vms

# Initialize new VM configuration
just init-vm myhost-vm qemu              # Auto-detect VM type
just init-vm myhost-vm virtualbox        # Specific VM type

# Build VM images
just build-vm-image desktop-test         # Build desktop testing VM
just build-vm-image qemu-vm              # Build basic QEMU VM

# Test VM configurations
just test-vm desktop-test                # Test without building

# Create QEMU disk and boot setup
just create-vm myhost-vm 4096 20G        # 4GB RAM, 20GB disk
```

### Desktop Environment Testing

Test different desktop environments safely in VMs:

```bash
# List available desktop environments
just list-desktops
# Available: gnome, kde, hyprland, niri

# Test specific desktop in VM
just test-desktop gnome desktop-test
just test-desktop kde my-kde-vm
just test-desktop hyprland my-hyprland-vm

# Build desktop-specific VMs
just init-vm gnome-test qemu
# Edit hosts/gnome-test/configuration.nix:
#   modules.desktop.gnome.enable = true;
just build-vm-image gnome-test
```

### VM Features & Optimizations

The VMs include:

**Boot Reliability** - Fixed systemd service conflicts and AppArmor issues  
**Desktop Ready** - Full GNOME with Wayland, optimized for VM performance  
**Guest Optimizations** - VirtIO drivers, shared clipboard, graphics acceleration  
**Development Tools** - Git, VS Code, terminal applications  
**SSH Access** - Port 22 open for remote development  
**User Environment** - Home Manager configuration with dotfiles  
**Network Access** - NAT networking with internet connectivity

### VM Troubleshooting

If VM boot hangs or fails:

```bash
# Check VM process
ps aux | grep qemu

# Kill stuck VM
pkill -f "qemu.*yourvm"

# Rebuild with latest fixes
just build-vm-image desktop-test

# Run with more verbose output
./result/bin/run-desktop-test-vm -serial stdio
```

### Advanced VM Usage

```bash
# Run VM in background with VNC
./result/bin/run-desktop-test-vm -vnc :1 -daemonize
# Connect to localhost:5901 with VNC viewer

# Run with more memory and cores
./result/bin/run-desktop-test-vm -m 4096 -smp 4

# Network port forwarding (SSH)
./result/bin/run-desktop-test-vm -netdev user,id=net0,hostfwd=tcp::2222-:22
# Then: ssh vm-user@localhost -p 2222
```

See [VM Documentation](docs/VM-SUPPORT.md) for detailed VM configuration and troubleshooting.

## Host Configurations

### Adding a New Host

1. Create a new directory under `hosts/`
2. Add `configuration.nix` and `hardware-configuration.nix`
3. Optional: Add `home.nix` for Home Manager configuration
4. Add the host to `flake.nix` nixosConfigurations

### Hardware Configuration

Generate hardware configuration for a new system:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```

## Secrets Management

This template includes SOPS for encrypted secrets management.

### Setup

1. Generate a key: `ssh-keygen -t ed25519 -f ~/.config/sops/age/keys.txt`
2. Configure `.sops.yaml` in the repository root
3. Create encrypted files: `sops secrets/example.yaml`

### Using Secrets

```nix
# In your configuration
sops.secrets."my-secret" = {
  sopsFile = ../secrets/secrets.yaml;
  owner = "user";
};
```

## Development Shell

Enter a development environment with all necessary tools:

```bash
nix develop
# or
make shell
```

This provides:

- Nix formatting and LSP tools
- System utilities
- Secrets management tools
- Documentation tools

## Best Practices

### Configuration Management

1. **Keep modules focused** - Each module should handle one concern
2. **Use lib.mkDefault** - Allow easy overriding in host configs
3. **Document your modules** - Add descriptions to module options
4. **Test changes** - Use `make test` before `make switch`

### Security

1. **Review secrets** - Never commit unencrypted secrets
2. **Update regularly** - Keep system and inputs updated
3. **Minimal permissions** - Only enable needed services
4. **Backup configurations** - Keep your configuration in version control

### Performance

1. **Use binary caches** - Configure trusted substituters
2. **Enable auto-optimization** - Let Nix optimize the store
3. **Regular cleanup** - Use `make clean` periodically

## Validation & CI/CD

This template maintains **100% green CI status** with comprehensive validation to ensure reliability and compatibility:

### Multi-Level Validation

- **Syntax Validation**: All Nix files checked for correct syntax
- **Build Evaluation**: Templates evaluate without hardware dependencies
- **VM Testing**: Configurations build actual bootable VMs
- **Module Validation**: All modules load correctly with proper dependencies
- **Script Testing**: Management scripts validated for functionality
- **Flake Validation**: Complete flake dependency resolution

### GitHub Actions CI (100% Passing)

Our comprehensive CI pipeline runs on every commit:

```bash
# Run validation locally (same as CI)
./scripts/validate-templates.sh standard

# Quick syntax-only check
./scripts/validate-templates.sh minimal

# Full validation including VM builds
./scripts/validate-templates.sh full
```

**CI Pipeline Status:**

- **Nix Code Validation** - Flake check, syntax validation, module imports
- **Code Quality Checks** - nixpkgs-fmt, statix linting, deadnix analysis
- **Shell Script Validation** - shellcheck compliance, executability checks
- **Documentation Validation** - Markdown linting, broken link detection
- **Template Validation** - Host templates, user templates, structure validation
- **Security Scanning** - Hardcoded secrets detection, permission auditing
- **Integration Testing** - Flake evaluation, development shell, justfile commands
- **Pre-commit Hooks** - Automated formatting and linting

### Quality Improvements

Recent quality improvements ensuring 100% CI success:

- **Fixed Undefined Variables** - Resolved flake validation failures
- **Code Formatting** - Consistent nixpkgs-fmt across all files
- **Linting Compliance** - Addressed statix warnings and suggestions
- **Shell Script Quality** - All scripts pass shellcheck validation
- **Documentation Quality** - Markdown files follow style guidelines
- **VM Boot Reliability** - Fixed systemd conflicts and boot hangs

### NixOS 25.05 Compatibility

All configurations are updated for the latest NixOS:

- Modern option syntax (no deprecated warnings)
- Updated module system patterns
- Latest GPU driver configurations
- Current Home Manager integration

## Troubleshooting

### Common Issues & Solutions

1. **Build failures**:

   ```bash
   nix flake check          # Check for syntax errors
   just validate            # Run full validation suite
   ```

2. **VM boot hangs**:

   ```bash
   just build-vm-image desktop-test    # Use latest boot fixes
   pkill -f qemu                       # Kill stuck VMs
   ```

3. **Hardware issues**:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

4. **Module conflicts**: Check for conflicting options using `lib.mkForce`

5. **Permission errors**: Ensure user is in wheel group

   ```bash
   sudo usermod -a -G wheel $USER
   ```

6. **Flake lock issues**:

   ```bash
   nix flake update         # Update all inputs
   git add flake.lock       # Commit lock changes
   ```

### Getting Help

1. Check the [NixOS Manual](https://nixos.org/manual/nixos/stable/)
2. Browse [NixOS Options](https://search.nixos.org/options)
3. Visit the [NixOS Discourse](https://discourse.nixos.org/)
4. Join the [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This configuration template is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
