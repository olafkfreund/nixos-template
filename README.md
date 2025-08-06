# Modern NixOS Configuration Template

A sophisticated, modular NixOS configuration template using flakes, featuring:

- **Modular Architecture** - Organized, reusable modules
- **Home Manager Integration** - Declarative user environments
- **SOPS Secrets Management** - Encrypted secrets in Git
- **Multiple Host Support** - Desktop, server, VM, and custom configurations
- **GPU Support** - AMD, NVIDIA, Intel with gaming/AI optimizations
- **AI/Compute Ready** - CUDA, ROCm, OneAPI for machine learning
- **Development Tools** - Scripts and utilities for easy management
- **Custom Packages & Overlays** - Extend and customize packages

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
│   ├── example-desktop/    # Example desktop configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── home.nix        # Home Manager config
│   ├── example-server/     # Example server configuration (AI/compute)
│   ├── qemu-vm/            # QEMU/KVM virtual machine
│   └── microvm/            # Minimal MicroVM configuration
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
just switch desktop   # Switch configuration for 'desktop' host
just test server     # Test configuration for 'server' host

# Utility commands
just init-host myhost    # Initialize new host configuration
just diff               # Show configuration differences
just show-inputs        # Show flake input versions
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

## Troubleshooting

### Common Issues

1. **Build failures**: Check `nix flake check` for syntax errors
2. **Hardware issues**: Verify hardware-configuration.nix is correct
3. **Module conflicts**: Check for conflicting module options
4. **Permission errors**: Ensure user is in wheel group

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
