# NixOS Configuration Justfile
# Provides convenient commands for managing the configuration
#
# Quick Start:
#   just          - Open the guided menu (browse categories & pick an action)
#   just menu     - Same as above (explicit alias)
#   just list     - Show all available recipes (raw)
#   just switch   - Build and apply configuration

# Default hostname (can be overridden)
hostname := `hostname`

# Default recipe - friendly, menu-driven control panel (zero dependencies)
default:
    @bash scripts/menu.sh

# Interactive menu (alias for the default)
menu:
    @bash scripts/menu.sh

# Quick alias for the interactive menu
m:
    @bash scripts/menu.sh

# Show all available recipes (traditional list view)
list:
    @just --list

# Build and switch to new configuration
switch host=hostname:
    sudo nixos-rebuild switch --flake .#{{host}}

# Test configuration without switching
test host=hostname:
    sudo nixos-rebuild test --flake .#{{host}}

# Build configuration for next boot
boot host=hostname:
    sudo nixos-rebuild boot --flake .#{{host}}

# Build configuration without switching
build host=hostname:
    sudo nixos-rebuild build --flake .#{{host}}

# Show what would be built
dry-run host=hostname:
    nixos-rebuild dry-run --flake .#{{host}}

# Update flake inputs
update:
    nix flake update

# Update and rebuild
update-switch host=hostname:
    just update
    just switch {{host}}

# Code Quality and Validation Commands

# Check flake for errors
check:
    @echo "🔍 Running flake check..."
    nix flake check

# Comprehensive code validation
validate:
    @echo "🔍 Running comprehensive validation..."
    just check
    just lint
    just format-check
    just dead-code-check
    @echo "✅ All validation checks passed"

# Format Nix files
fmt:
    @echo "🎨 Formatting Nix files..."
    nixpkgs-fmt .
    @echo "✅ Formatting complete"

# Check if files are properly formatted (without modifying)
format-check:
    @echo "🔍 Checking code formatting..."
    @if nixpkgs-fmt --check .; then \
        echo "✅ All files are properly formatted"; \
    else \
        echo "❌ Some files need formatting. Run 'just fmt' to fix."; \
        exit 1; \
    fi

# Lint Nix code for common issues
lint:
    @echo "🔍 Linting Nix code..."
    @if command -v statix >/dev/null 2>&1; then \
        statix check .; \
        echo "✅ Statix linting complete"; \
    else \
        echo "⚠️  statix not found, installing..."; \
        nix profile install nixpkgs#statix; \
        statix check .; \
    fi

# Check for dead code (unused imports, functions, etc.)
dead-code-check:
    @echo "🔍 Checking for dead code..."
    @if command -v deadnix >/dev/null 2>&1; then \
        deadnix --fail .; \
        echo "✅ No dead code found"; \
    else \
        echo "⚠️  deadnix not found, installing..."; \
        nix profile install nixpkgs#deadnix; \
        deadnix --fail .; \
    fi

# Fix dead code automatically (removes unused code)
dead-code-fix:
    @echo "🔧 Fixing dead code..."
    @if command -v deadnix >/dev/null 2>&1; then \
        deadnix --edit .; \
        echo "✅ Dead code removed"; \
    else \
        echo "⚠️  deadnix not found, installing..."; \
        nix profile install nixpkgs#statix; \
        deadnix --edit .; \
    fi

# Run security audit on dependencies
security-audit:
    @echo "🛡️  Running security audit..."
    @if command -v vulnix >/dev/null 2>&1; then \
        vulnix --system; \
        echo "✅ Security audit complete"; \
    else \
        echo "⚠️  vulnix not found, running basic security check..."; \
        nix-store --verify --repair --check-contents; \
        echo "✅ Basic security check complete"; \
    fi

# Check for outdated dependencies
outdated-check:
    @echo "🔍 Checking for outdated dependencies..."
    nix flake update --dry-run
    @echo "💡 Run 'just update' to update dependencies"

# Full code quality suite
quality:
    @echo "🎯 Running full code quality suite..."
    just validate
    just security-audit
    just outdated-check
    @echo "✅ Code quality suite complete"

# Check specific file or directory
check-path path:
    @echo "🔍 Checking {{path}}..."
    nixpkgs-fmt --check {{path}}
    @if command -v statix >/dev/null 2>&1; then statix check {{path}}; fi
    @if command -v deadnix >/dev/null 2>&1; then deadnix --fail {{path}}; fi
    @echo "✅ {{path}} validation complete"

# Git Hooks and Automation

# Install pre-commit hooks
install-hooks:
    @echo "Installing pre-commit hooks..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit install; \
        echo "Pre-commit hooks installed"; \
        echo "Hooks will now run automatically on git commits"; \
    else \
        echo "pre-commit not found. Installing..."; \
        nix profile install nixpkgs#pre-commit; \
        pre-commit install; \
    fi

# Run pre-commit hooks on all files
run-hooks:
    @echo "Running pre-commit hooks on all files..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit run --all-files; \
        echo "All hooks completed"; \
    else \
        echo "pre-commit not found. Installing..."; \
        nix profile install nixpkgs#pre-commit; \
        pre-commit run --all-files; \
    fi

# Update pre-commit hooks
update-hooks:
    @echo "📦 Updating pre-commit hooks..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit autoupdate; \
        echo "✅ Hooks updated"; \
    else \
        echo "❌ pre-commit not found. Run 'nix develop' first."; \
    fi

# Run pre-commit hooks manually (useful for testing)
test-hooks:
    @echo "🧪 Testing pre-commit hooks..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit run --all-files --verbose; \
    else \
        echo "❌ pre-commit not found. Run 'nix develop' first."; \
    fi

# Complete development setup
dev-setup:
    @echo "Setting up development environment..."
    just install-hooks
    just validate
    @echo "Development environment ready!"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Edit your configuration files"
    @echo "  2. Run 'just validate' to check your changes"
    @echo "  3. Run 'just switch' to apply changes"
    @echo "  4. Git hooks will automatically validate commits"

# CI/CD Commands

# Run full CI validation locally
ci-validate:
    @echo "Running full CI validation locally..."
    just validate
    just run-hooks
    just security-check
    @echo "CI validation complete"

# Prepare for release
prepare-release version:
    @echo "Preparing release {{version}}..."
    just validate
    just run-hooks
    just security-check
    git tag {{version}}
    @echo "Release {{version}} prepared"
    @echo "Push with: git push origin {{version}}"

# Security checks
security-check:
    @echo "Running security checks..."
    @echo "Checking for potential security issues..."
    @if grep -r "eval.*\\$" --include="*.sh" --include="*.nix" . 2>/dev/null; then \
        echo "WARNING: Found 'eval' with variable expansion - review for security"; \
    fi
    @if grep -r "rm -rf /" --include="*.sh" . 2>/dev/null; then \
        echo "ERROR: Found dangerous rm command"; \
        exit 1; \
    fi
    @echo "Basic security check completed"

# Enter development shell
shell:
    nix develop

# Clean build artifacts
clean:
    sudo nix-collect-garbage
    nix-collect-garbage
    @rm -f result result-*

# Remove old system generations (keep last 3)
clean-old:
    sudo nix-collect-garbage --delete-older-than 7d
    sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system

# Remove result symlinks (the annoying files from nix build)
clean-results:
    @echo "🧹 Cleaning result symlinks..."
    @rm -f result result-*
    @echo "✅ Result symlinks removed"

# List system generations
list-generations:
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Show system information
info:
    @echo "Current hostname: {{hostname}}"
    @echo "Available configurations:"
    @nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' 2>/dev/null || echo "Run 'nix flake show' to see configurations"
    @echo ""
    @echo "Current generation:"
    @sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1

# Secrets Management Commands

# Setup agenix secrets management
setup-secrets:
    @echo "🔐 Setting up agenix secrets management..."
    ./scripts/setup-agenix.sh

# Edit a secret with agenix
edit-secret SECRET:
    @echo "🔐 Editing secret: {{SECRET}}"
    cd secrets && agenix -e {{SECRET}}.age

# Create new secret
new-secret SECRET:
    @echo "🔐 Creating new secret: {{SECRET}}"
    cd secrets && agenix -e {{SECRET}}.age

# List all secrets
list-secrets:
    @echo "🔐 Available secrets:"
    @find secrets -name "*.age" -type f | sed 's|secrets/||g' | sed 's|\.age||g' | sort

# Re-encrypt all secrets (useful after adding new keys)
rekey-secrets:
    @echo "🔐 Re-encrypting all secrets..."
    cd secrets && agenix -r

# Show secrets that are currently decrypted
show-decrypted:
    @echo "🔐 Currently decrypted secrets:"
    @ls -la /run/agenix/ 2>/dev/null || echo "No secrets currently decrypted"

# Validate secrets configuration
check-secrets:
    @echo "🔐 Validating secrets configuration..."
    @cd secrets && nix-instantiate --eval --strict secrets.nix >/dev/null && echo "✓ secrets.nix is valid" || echo "✗ secrets.nix has errors"

# WSL2 Commands

# Build WSL2 distribution archive (alternative to ISO for Windows)
build-wsl2-archive:
    @echo "🐧 Building WSL2 distribution archive..."
    nix build .#nixosConfigurations.wsl2-template.config.system.build.tarball
    @echo "✅ WSL2 archive built: result/tarball/nixos-system-x86_64-linux.tar.xz"
    @echo "📝 Import with: wsl --import NixOS-Template C:\\WSL\\NixOS result/tarball/nixos-system-x86_64-linux.tar.xz"

# Test WSL2 configuration (build only, no installation)
test-wsl2:
    @echo "🧪 Testing WSL2 configuration..."
    nix build .#nixosConfigurations.wsl2-template.config.system.build.toplevel
    @echo "✅ WSL2 configuration builds successfully"

# Build WSL2 home configuration
build-wsl2-home:
    @echo "🏠 Building WSL2 Home Manager configuration..."
    nix build .#homeConfigurations."nixos@wsl2-template".activationPackage
    @echo "✅ WSL2 Home Manager configuration built successfully"

# Show WSL2 installation instructions
wsl2-install-help:
    @echo "📋 WSL2 Installation Instructions"
    @echo "=================================="
    @echo ""
    @echo "1. Build the WSL2 archive:"
    @echo "   just build-wsl2-archive"
    @echo ""
    @echo "2. Run the installation script (from Windows):"
    @echo "   .\\scripts\\install-wsl2.sh"
    @echo ""
    @echo "3. Or manually import the archive:"
    @echo "   wsl --import NixOS-Template C:\\WSL\\NixOS result/tarball/nixos-system-x86_64-linux.tar.xz"
    @echo ""
    @echo "4. Start NixOS WSL2:"
    @echo "   wsl -d NixOS-Template"
    @echo ""
    @echo "5. Apply configuration (from inside WSL2):"
    @echo "   sudo nixos-rebuild switch --flake /etc/nixos#wsl2-template"
    @echo ""
    @echo "📚 Full documentation: docs/WSL2-CONFIGURATION.md"

# Virtual Machine Commands

# Detect if running in VM and get recommendations
detect-vm:
    @echo "🖥️  Detecting virtualization environment..."
    ./scripts/detect-vm.sh

# Detect hardware type (laptop, desktop, workstation, server)
detect-hardware:
    @echo "🔍 Detecting hardware type..."
    ./scripts/detect-hardware.sh

# Initialize VM-optimized configuration
init-vm host vm_type="auto":
    #!/usr/bin/env bash
    echo "🖥️  Initializing VM configuration for host: {{host}} (type: {{vm_type}})"

    # Detect VM type if auto
    if [ "{{vm_type}}" = "auto" ]; then
        vm_type=$(./scripts/detect-vm.sh | grep "VM_TYPE=" | cut -d= -f2)
        if [ -z "$vm_type" ] || [ "$vm_type" = "none" ]; then
            echo "❌ No virtualization detected. Use a specific type or run on a VM."
            exit 1
        fi
        echo "🔍 Auto-detected VM type: $vm_type"
    else
        vm_type="{{vm_type}}"
    fi

    # Create host directory
    mkdir -p hosts/{{host}}

    # Copy appropriate VM template
    case "$vm_type" in
        qemu|kvm)
            cp -r hosts/qemu-vm/* hosts/{{host}}/
            ;;
        virtualbox)
            cp -r hosts/virtualbox-vm/* hosts/{{host}}/
            ;;
        vmware)
            cp -r hosts/qemu-vm/* hosts/{{host}}/  # Use QEMU template as base
            sed -i 's/type = "qemu"/type = "vmware"/g' hosts/{{host}}/configuration.nix
            ;;
        hyperv)
            cp -r hosts/qemu-vm/* hosts/{{host}}/  # Use QEMU template as base
            sed -i 's/type = "qemu"/type = "hyperv"/g' hosts/{{host}}/configuration.nix
            ;;
        *)
            echo "❌ Unsupported VM type: $vm_type"
            echo "Supported types: qemu, virtualbox, vmware, hyperv"
            exit 1
            ;;
    esac

    # Update hostname in configuration
    sed -i "s/networking.hostName = \".*\"/networking.hostName = \"{{host}}\"/g" hosts/{{host}}/configuration.nix

    # Generate hardware configuration
    if [ ! -f "hosts/{{host}}/hardware-configuration.nix" ]; then
        echo "📝 Generating hardware configuration..."
        sudo nixos-generate-config --show-hardware-config > hosts/{{host}}/hardware-configuration.nix
        echo "✅ Generated hardware-configuration.nix"
    fi

    echo "✅ VM configuration initialized for {{host}}"
    echo "📝 Next steps:"
    echo "   1. Review hosts/{{host}}/configuration.nix"
    echo "   2. Update hardware-configuration.nix UUIDs if needed"
    echo "   3. Run: just test {{host}}"
    echo "   4. Run: just switch {{host}}"

# Test VM configuration
test-vm host:
    @echo "🧪 Testing VM configuration for {{host}}..."
    just test {{host}}

# Build VM ISO for installation
build-vm-iso host:
    @echo "💿 Building installation ISO for VM host {{host}}..."
    nix build .#nixosConfigurations.{{host}}.config.system.build.isoImage

# Show VM optimization recommendations
vm-recommendations:
    @echo "🖥️  VM Optimization Recommendations..."
    ./scripts/detect-vm.sh | grep -A 20 "Recommended configuration:" || echo "Run 'just detect-vm' for detailed recommendations"

# Initialize new host configuration
init-host host:
    #!/usr/bin/env bash
    echo "Initializing configuration for host: {{host}}"
    mkdir -p hosts/{{host}}

    # Generate hardware configuration
    if [ ! -f "hosts/{{host}}/hardware-configuration.nix" ]; then
        echo "Generating hardware configuration..."
        sudo nixos-generate-config --show-hardware-config > hosts/{{host}}/hardware-configuration.nix
        echo "Generated hardware-configuration.nix"
    else
        echo "hardware-configuration.nix already exists"
    fi

    # Create basic configuration if it doesn't exist
    if [ ! -f "hosts/{{host}}/configuration.nix" ]; then
        echo "Creating basic configuration..."
        cp hosts/example-desktop/configuration.nix hosts/{{host}}/configuration.nix
        sed -i 's/example-desktop/{{host}}/g' hosts/{{host}}/configuration.nix
        echo "Created configuration.nix (copied from example-desktop)"
    else
        echo "configuration.nix already exists"
    fi

    # Create basic home configuration if it doesn't exist
    if [ ! -f "hosts/{{host}}/home.nix" ]; then
        echo "Creating basic home configuration..."
        cp hosts/example-desktop/home.nix hosts/{{host}}/home.nix
        echo "Created home.nix (copied from example-desktop)"
    else
        echo "home.nix already exists"
    fi

    echo ""
    echo "Host {{host}} initialized!"
    echo "Next steps:"
    echo "1. Edit hosts/{{host}}/hardware-configuration.nix if needed"
    echo "2. Customize hosts/{{host}}/configuration.nix"
    echo "3. Update hosts/{{host}}/home.nix for your user"
    echo "4. Add {{host}} to flake.nix nixosConfigurations"
    echo "5. Run: just switch {{host}}"

# Rebuild with script (alternative method)
rebuild *args:
    ./scripts/rebuild.sh {{args}}

# Show flake inputs and their versions
show-inputs:
    @nix flake metadata

# Show package versions for debugging
show-versions:
    @echo "System packages:"
    @nix-env -q --installed --profile /nix/var/nix/profiles/system
    @echo ""
    @echo "User packages:"
    @nix-env -q --installed

# Template validation commands

# Validate all templates (comprehensive)
validate-templates level="standard":
    @echo "Running template validation (level: {{level}})..."
    ./scripts/validate-templates.sh {{level}}

# Quick template validation (syntax only)
validate-templates-quick:
    @echo "Running quick template validation..."
    ./scripts/validate-templates.sh minimal

# Full template validation with VM builds (slow)
validate-templates-full:
    @echo "Running full template validation with VM builds..."
    @echo "This may take 10-15 minutes..."
    ./scripts/validate-templates.sh full

# Validate specific template by building it
validate-template template:
    @echo "Validating specific template: {{template}}"
    @if [ -d "hosts/{{template}}" ]; then \
        echo "Checking template structure..."; \
        test -f "hosts/{{template}}/configuration.nix" || { echo "Missing configuration.nix"; exit 1; }; \
        test -f "hosts/{{template}}/home.nix" || { echo "Missing home.nix"; exit 1; }; \
        echo "Template {{template}} structure is valid"; \
    else \
        echo "Template {{template}} not found"; \
        echo "Available templates:"; \
        ls hosts/*-template | sed 's|hosts/||g'; \
        exit 1; \
    fi

# Diff current and new configuration
diff host=hostname:
    sudo nixos-rebuild build --flake .#{{host}}
    nix store diff-closures /run/current-system ./result

# Deploy to remote host
deploy host user="root":
    nixos-rebuild switch --flake .#{{host}} --target-host {{user}}@{{host}} --use-remote-sudo

# VM-specific commands

# Build QEMU VM image
build-vm-image host=hostname:
    nix build .#nixosConfigurations.{{host}}.config.system.build.vm
    @echo "VM image built: result/bin/run-nixos-vm"

# Build NixOS installer ISO images

# Build minimal installer ISO (lightweight, command-line only)
build-iso-minimal:
    @echo "🔥 Building minimal NixOS installer ISO..."
    nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage
    @echo "✅ Minimal installer ISO built!"
    @echo "📍 Location: result/iso/nixos-minimal-installer.iso"
    @echo "💾 Size: $(du -h result/iso/*.iso | cut -f1)"

# Build desktop installer ISO (GNOME desktop for graphical installation)
build-iso-desktop:
    @echo "🔥 Building desktop NixOS installer ISO..."
    nix build .#nixosConfigurations.installer-desktop.config.system.build.isoImage
    @echo "✅ Desktop installer ISO built!"
    @echo "📍 Location: result/iso/nixos-desktop-installer.iso"
    @echo "💾 Size: $(du -h result/iso/*.iso | cut -f1)"

# Build preconfigured installer ISO (includes all templates ready to install)
build-iso-preconfigured:
    @echo "🔥 Building preconfigured NixOS installer ISO..."
    nix build .#nixosConfigurations.installer-preconfigured.config.system.build.isoImage
    @echo "✅ Preconfigured installer ISO built!"
    @echo "📍 Location: result/iso/nixos-preconfigured-installer.iso"
    @echo "💾 Size: $(du -h result/iso/*.iso | cut -f1)"
    @echo ""
    @echo "🎯 This ISO includes:"
    @echo "   • All configuration templates from this repository"
    @echo "   • Interactive installer with template selection"
    @echo "   • Development tools (git, just, editors)"
    @echo "   • Quick installation wizard"

# Build all installer ISOs
build-all-isos:
    @echo "🔥 Building all NixOS installer ISOs..."
    just build-iso-minimal
    just build-iso-desktop
    just build-iso-preconfigured
    @echo ""
    @echo "✅ All installer ISOs built!"
    @echo "📦 Available ISOs:"
    @find result/iso/ -name "*.iso" -exec echo "   {}" \; 2>/dev/null || echo "   Check result/iso/ directory"

# Show available ISO configurations
list-isos:
    @echo "📀 Available NixOS installer ISO configurations:"
    @echo ""
    @echo "  🔧 minimal       - Lightweight command-line installer (~800MB)"
    @echo "     • SSH access enabled"
    @echo "     • Essential tools (nano, vim, git)"
    @echo "     • Perfect for server installations"
    @echo "     • Build: just build-iso-minimal"
    @echo ""
    @echo "  🖥️  desktop       - GNOME desktop installer (~2.5GB)"
    @echo "     • Full GNOME desktop environment"
    @echo "     • Firefox browser for documentation"
    @echo "     • GParted for disk partitioning"
    @echo "     • Visual tools for easier installation"
    @echo "     • Build: just build-iso-desktop"
    @echo ""
    @echo "  ⚡ preconfigured - Template-enabled installer (~1.5GB)"
    @echo "     • All configuration templates included"
    @echo "     • Interactive template selection"
    @echo "     • Quick installation wizard"
    @echo "     • Development tools pre-installed"
    @echo "     • Build: just build-iso-preconfigured"
    @echo ""
    @echo "🏗️  Build all ISOs: just build-all-isos"

# Test ISO configuration without building
test-iso iso="minimal":
    @echo "🧪 Testing {{iso}} installer ISO configuration..."
    @case "{{iso}}" in \
        minimal) \
            just test installer-minimal ;; \
        desktop) \
            just test installer-desktop ;; \
        preconfigured) \
            just test installer-preconfigured ;; \
        *) \
            echo "❌ Unknown ISO: {{iso}}"; \
            echo "Available: minimal, desktop, preconfigured"; \
            exit 1 ;; \
    esac
    @echo "✅ {{iso}} ISO configuration is valid"

# Create bootable USB from built ISO (requires USB device path)
create-bootable-usb iso device:
    #!/usr/bin/env bash

    # Validate inputs
    if [ ! -f "result/iso/{{iso}}" ]; then
        echo "❌ ISO not found: result/iso/{{iso}}"
        echo "Build it first with: just build-iso-*"
        exit 1
    fi

    if [ ! -b "{{device}}" ]; then
        echo "❌ Device not found: {{device}}"
        echo "Available devices:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "sd|nvme"
        exit 1
    fi

    # Safety check
    echo "⚠️  This will ERASE all data on {{device}}"
    echo "ISO: {{iso}}"
    echo "Device: {{device}}"
    read -p "Continue? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi

    # Create bootable USB
    echo "🔥 Writing ISO to USB device..."
    sudo dd if="result/iso/{{iso}}" of="{{device}}" bs=4M status=progress oflag=sync
    sudo sync

    echo "✅ Bootable USB created!"
    echo "🚀 You can now boot from {{device}} to install NixOS"

# Show ISO creation workflow
iso-workflow:
    @echo "📋 NixOS ISO Creation Workflow:"
    @echo ""
    @echo "1️⃣  Choose your installer type:"
    @echo "   just list-isos              # See available options"
    @echo ""
    @echo "2️⃣  Build the ISO:"
    @echo "   just build-iso-minimal      # Lightweight CLI installer"
    @echo "   just build-iso-desktop      # GNOME desktop installer"
    @echo "   just build-iso-preconfigured # Template-enabled installer"
    @echo "   just build-all-isos         # Build all types"
    @echo ""
    @echo "3️⃣  Create bootable media:"
    @echo "   just create-bootable-usb nixos-minimal-installer.iso /dev/sdX"
    @echo ""
    @echo "4️⃣  Boot and install:"
    @echo "   • Boot from USB/DVD"
    @echo "   • Follow installer prompts"
    @echo "   • Preconfigured ISO includes template selection"
    @echo ""
    @echo "💡 Pro tips:"
    @echo "   • Test ISOs in VM first: just build-vm-image"
    @echo "   • Minimal ISO perfect for servers"
    @echo "   • Desktop ISO great for newcomers"
    @echo "   • Preconfigured ISO has ready-to-use configs"

# Legacy build-iso command (defaults to minimal for compatibility)
build-iso:
    @echo "ℹ️  Using minimal installer (for compatibility)"
    @echo "   Use specific commands for other types:"
    @echo "   • just build-iso-minimal"
    @echo "   • just build-iso-desktop"
    @echo "   • just build-iso-preconfigured"
    @echo ""
    just build-iso-minimal

# Create QEMU VM with specific configuration
create-vm host="qemu-vm" memory="2048" disk="10G":
    #!/usr/bin/env bash
    echo "Creating VM: {{host}}"
    echo "Memory: {{memory}}MB, Disk: {{disk}}"

    # Create disk image
    qemu-img create -f qcow2 {{host}}.qcow2 {{disk}}

    echo "VM disk created: {{host}}.qcow2"
    echo "To start VM:"
    echo "  qemu-system-x86_64 \\"
    echo "    -enable-kvm \\"
    echo "    -m {{memory}} \\"
    echo "    -drive file={{host}}.qcow2,format=qcow2 \\"
    echo "    -cdrom nixos.iso \\"
    echo "    -boot d"

# Test MicroVM configuration (dry run)
test-microvm:
    just build microvm
    @echo "MicroVM configuration validated"
    @nix path-info .#nixosConfigurations.microvm.config.system.build.toplevel

# Show VM configurations available
list-vms:
    @echo "Available VM configurations:"
    @echo "  🖥️  qemu-vm    - Full-featured QEMU/KVM VM"
    @echo "  🔬  microvm    - Minimal MicroVM"
    @echo "  🖱️  example-desktop - Desktop environment example"
    @echo "  🖧  example-server  - Server configuration example"

# VM deployment helper
deploy-vm host ip user="root":
    @echo "Deploying {{host}} to {{ip}}"
    nixos-rebuild switch --flake .#{{host}} --target-host {{user}}@{{ip}} --use-remote-sudo

# Desktop Environment commands

# Show available desktop environments
list-desktops:
    @echo "Available desktop environments:"
    @echo "  🖥️  gnome     - GNOME desktop with Wayland support"
    @echo "  🎨  kde       - KDE Plasma desktop (Plasma 6)"
    @echo "  🪟  hyprland  - Hyprland tiling window manager with Waybar"
    @echo "  🌊  niri      - Niri scrollable tiling window manager"
    @echo ""
    @echo "Configure in your host configuration:"
    @echo "  modules.desktop.gnome.enable = true;"
    @echo "  modules.desktop.kde.enable = true;"
    @echo "  modules.desktop.hyprland.enable = true;"
    @echo "  modules.desktop.niri.enable = true;"

# Test desktop environment configuration
test-desktop desktop host=hostname:
    #!/usr/bin/env bash
    echo "Testing {{desktop}} desktop configuration for {{host}}"

    case "{{desktop}}" in
        gnome)
            echo "Testing GNOME configuration..."
            nix build .#nixosConfigurations.{{host}}.config.services.xserver.desktopManager.gnome.enable --no-link
            ;;
        kde)
            echo "Testing KDE configuration..."
            nix build .#nixosConfigurations.{{host}}.config.services.desktopManager.plasma6.enable --no-link
            ;;
        hyprland)
            echo "Testing Hyprland configuration..."
            nix build .#nixosConfigurations.{{host}}.config.programs.hyprland.enable --no-link
            ;;
        niri)
            echo "Testing Niri configuration..."
            nix build .#nixosConfigurations.{{host}}.config.modules.desktop.niri.enable --no-link
            ;;
        *)
            echo "Unknown desktop: {{desktop}}"
            echo "Available: gnome, kde, hyprland, niri"
            exit 1
            ;;
    esac

    echo "✅ {{desktop}} configuration is valid"

# Apply desktop-specific home manager configuration
apply-home-desktop desktop user="user" host=hostname:
    home-manager switch --flake .#{{user}}@{{host}} --extra-experimental-features nix-command --extra-experimental-features flakes

# Niri-specific commands

# Test Niri configuration without switching
test-niri host=hostname:
    @echo "Testing Niri configuration for {{host}}"
    just test-desktop niri {{host}}
    @echo "Checking niri configuration files..."
    nix build .#nixosConfigurations.{{host}}.config.environment.etc.\"niri/config.kdl\".text --no-link
    @echo "✅ Niri configuration is valid"

# Reload Niri configuration (if currently running)
niri-reload:
    @echo "Reloading Niri configuration..."
    @if command -v niri >/dev/null 2>&1; then \
        niri msg action reload-config && echo "✅ Niri config reloaded"; \
    else \
        echo "❌ Niri is not running or not installed"; \
    fi

# Show Niri keybindings reference
niri-keys:
    @echo "Niri Keybindings Reference:"
    @echo ""
    @echo "Window Management:"
    @echo "  Super + T                 Open terminal"
    @echo "  Super + D                 Open application launcher"
    @echo "  Super + Q                 Close window"
    @echo "  Super + F                 Maximize column"
    @echo "  Super + Shift + F         Fullscreen window"
    @echo ""
    @echo "Navigation:"
    @echo "  Super + Left/H            Focus column left"
    @echo "  Super + Right/L           Focus column right"
    @echo "  Super + Up/K              Focus window up"
    @echo "  Super + Down/J            Focus window down"
    @echo ""
    @echo "Workspaces (Scrollable):"
    @echo "  Super + Page_Up/I         Focus workspace up"
    @echo "  Super + Page_Down/U       Focus workspace down"
    @echo "  Super + Scroll Up/Down    Focus workspace up/down"
    @echo "  Super + 1-9               Focus workspace 1-9"
    @echo ""
    @echo "Column Management:"
    @echo "  Super + R                 Switch preset column width"
    @echo "  Super + Minus/Equal       Decrease/Increase column width"
    @echo "  Super + Comma/Period      Consume/Expel window"
    @echo ""
    @echo "System:"
    @echo "  Super + Ctrl + L          Lock screen"
    @echo "  Print                     Screenshot"
    @echo "  Super + Print             Screenshot to clipboard"

# Debug Niri with visual tinting
niri-debug:
    @echo "Toggling Niri debug tinting..."
    @if command -v niri >/dev/null 2>&1; then \
        niri msg action toggle-debug-tint && echo "✅ Debug tinting toggled"; \
    else \
        echo "❌ Niri is not running or not installed"; \
    fi

# Show Niri configuration paths
niri-config-info:
    @echo "Niri Configuration Information:"
    @echo ""
    @echo "System config:     /etc/niri/config.kdl"
    @echo "User config:       ~/.config/niri/config.kdl"
    @echo "Socket:            \$XDG_RUNTIME_DIR/niri/niri.sock"
    @echo ""
    @echo "Useful commands:"
    @echo "  niri msg --help           Show all available commands"
    @echo "  niri msg workspaces       List current workspaces"
    @echo "  niri msg windows          List current windows"
    @echo "  niri msg version          Show Niri version"

# User Template Management

# Show available user templates
list-users:
    @echo "Available user templates:"
    @echo ""
    @echo "  user        - Basic general-purpose user configuration"
    @echo "  developer   - Software development focused setup"
    @echo "  gamer       - Gaming and entertainment configuration"
    @echo "  minimal     - Lightweight setup for resource-constrained systems"
    @echo "  server      - System administration and server management"
    @echo ""
    @echo "Usage: just init-user HOSTNAME TEMPLATE"
    @echo "Example: just init-user myhost developer"

# Show details about a specific user template
show-user template:
    @echo "User template: {{template}}"
    @echo ""
    @if [ -f "home/users/{{template}}.nix" ]; then \
        echo "Template found: home/users/{{template}}.nix"; \
        echo ""; \
        echo "Description:"; \
        head -20 "home/users/{{template}}.nix" | grep -E '^\s*#' | sed 's/^\s*# //'; \
    else \
        echo "Template not found!"; \
        echo "Available templates:"; \
        ls home/users/*.nix | xargs -n 1 basename | sed 's/\.nix$//' | grep -v default | sed 's/^/  /'; \
    fi

# Initialize user configuration from template
init-user host template:
    #!/usr/bin/env bash
    echo "Initializing user configuration for {{host}} using {{template}} template"

    # Check if template exists
    if [ ! -f "home/users/{{template}}.nix" ]; then
        echo "Error: Template '{{template}}' not found"
        echo "Available templates:"
        ls home/users/*.nix | xargs -n 1 basename | sed 's/\.nix$//' | grep -v default | sed 's/^/  /'
        exit 1
    fi

    # Create host directory if it doesn't exist
    mkdir -p "hosts/{{host}}"

    # Copy template to host home.nix (backup if exists)
    if [ -f "hosts/{{host}}/home.nix" ]; then
        echo "Backing up existing home.nix to home.nix.backup"
        cp "hosts/{{host}}/home.nix" "hosts/{{host}}/home.nix.backup"
    fi

    # Copy template and customize
    cp "home/users/{{template}}.nix" "hosts/{{host}}/home.nix"

    # Basic customization (replace template username with host)
    if command -v sed >/dev/null 2>&1; then
        sed -i "s/username = \"{{template}}\";/username = \"user\";/g" "hosts/{{host}}/home.nix"
        sed -i "s/homeDirectory = \"\/home\/{{template}}\";/homeDirectory = \"\/home\/user\";/g" "hosts/{{host}}/home.nix"
    fi

    echo "User configuration created: hosts/{{host}}/home.nix"
    echo ""

# New Preset-Based Host Generation

# Generate a new host using the preset system (modern approach)
new-host host preset:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "🚀 Creating new host: {{host}} with {{preset}} preset"

    # Validate preset
    case "{{preset}}" in
        "workstation"|"laptop"|"server"|"gaming"|"vm-guest")
            ;;
        *)
            echo "❌ Invalid preset: {{preset}}"
            echo "Available presets:"
            echo "  workstation - High-performance desktop for productivity"
            echo "  laptop      - Mobile computing with battery optimization"
            echo "  server      - Headless server with security focus"
            echo "  gaming      - Maximum performance gaming configuration"
            echo "  vm-guest    - Optimized for virtual machine guests"
            exit 1
            ;;
    esac

    # Create host directory
    mkdir -p "hosts/{{host}}"

    # Generate configuration files from templates
    cp templates/preset-host-config.nix "hosts/{{host}}/configuration.nix"
    cp templates/preset-home-config.nix "hosts/{{host}}/home.nix"

    # Create hardware config if it doesn't exist
    if [ ! -f "hosts/{{host}}/hardware-configuration.nix" ]; then
        cp templates/preset-hardware-config.nix "hosts/{{host}}/hardware-configuration.nix"
    fi

    # Replace placeholders in the files
    sed -i "s/HOSTNAME/{{host}}/g" "hosts/{{host}}/configuration.nix"
    sed -i "s/PRESET/{{preset}}/g" "hosts/{{host}}/configuration.nix"
    sed -i "s/HOSTNAME/{{host}}/g" "hosts/{{host}}/home.nix"
    sed -i "s/PRESET/{{preset}}/g" "hosts/{{host}}/home.nix"
    sed -i "s/HOSTNAME/{{host}}/g" "hosts/{{host}}/hardware-configuration.nix"

    echo "✅ Host {{host}} created successfully!"
    echo ""
    echo "📁 Generated files:"
    echo "  • hosts/{{host}}/configuration.nix ({{preset}} preset)"
    echo "  • hosts/{{host}}/home.nix (basic home config)"
    echo "  • hosts/{{host}}/hardware-configuration.nix (placeholder)"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Replace hardware-configuration.nix with actual hardware config"
    echo "  2. Add {{host}} to flake.nix nixosConfigurations"
    echo "  3. Customize the configuration in customizations = {}"
    echo ""
    echo "🔧 Add to flake.nix:"
    echo "    {{host}} = nixpkgs.lib.nixosSystem {"
    echo "      system = \"x86_64-linux\";"
    echo "      specialArgs = { inherit inputs outputs; };"
    echo "      modules = [ ./hosts/{{host}}/configuration.nix ];"
    echo "    };"

# Show available presets with descriptions
list-presets:
    @echo "Available NixOS Presets:"
    @echo ""
    @echo "🖥️  workstation  - High-performance desktop for productivity and development"
    @echo "                  • Full desktop environment (GNOME)"
    @echo "                  • Development tools and IDEs"
    @echo "                  • Performance optimizations"
    @echo "                  • Gaming peripherals support"
    @echo ""
    @echo "💻 laptop       - Mobile computing with battery optimization"
    @echo "                  • Power management and TLP"
    @echo "                  • WiFi and mobile connectivity"
    @echo "                  • Suspend/resume optimization"
    @echo "                  • VPN support for remote work"
    @echo ""
    @echo "🖧  server       - Headless server with security focus"
    @echo "                  • No desktop environment"
    @echo "                  • SSH and remote management"
    @echo "                  • Container support (Podman)"
    @echo "                  • Security hardening"
    @echo ""
    @echo "🎮 gaming       - Maximum performance gaming configuration"
    @echo "                  • Steam, GameMode, MangoHUD"
    @echo "                  • Performance kernel and optimizations"
    @echo "                  • Gaming peripherals and RGB"
    @echo "                  • Streaming tools (OBS)"
    @echo ""
    @echo "💾 vm-guest     - Optimized for virtual machine guests"
    @echo "                  • VM guest tools and drivers"
    @echo "                  • Lightweight desktop"
    @echo "                  • Optimized for virtualized hardware"
    @echo "                  • Fast boot and minimal services"
    @echo ""
    @echo "Usage: just new-host <hostname> <preset>"
    @echo "Example: just new-host my-desktop workstation"

# Copy user template to current directory for customization
copy-user-template template:
    #!/usr/bin/env bash
    echo "Copying {{template}} template for customization"

    if [ ! -f "home/users/{{template}}.nix" ]; then
        echo "Error: Template '{{template}}' not found"
        just list-users
        exit 1
    fi

    cp "home/users/{{template}}.nix" "./{{template}}-custom.nix"
    echo "Template copied to: ./{{template}}-custom.nix"
    echo "Edit this file to customize, then move to your hosts directory"

# Compare two user templates
compare-users template1 template2:
    @echo "Comparing user templates: {{template1}} vs {{template2}}"
    @echo ""
    @if [ -f "home/users/{{template1}}.nix" ] && [ -f "home/users/{{template2}}.nix" ]; then \
        echo "=== {{template1}}.nix ==="; \
        wc -l "home/users/{{template1}}.nix"; \
        echo ""; \
        echo "=== {{template2}}.nix ==="; \
        wc -l "home/users/{{template2}}.nix"; \
        echo ""; \
        echo "Use 'diff home/users/{{template1}}.nix home/users/{{template2}}.nix' for detailed comparison"; \
    else \
        echo "One or both templates not found"; \
        just list-users; \
    fi

# Validate user template
validate-user template:
    @echo "Validating user template: {{template}}"
    @if [ -f "home/users/{{template}}.nix" ]; then \
        echo "Checking syntax..."; \
        nixpkgs-fmt --check "home/users/{{template}}.nix" && echo "✅ Formatting OK" || echo "❌ Needs formatting"; \
        if command -v statix >/dev/null 2>&1; then \
            statix check "home/users/{{template}}.nix" && echo "✅ Linting OK" || echo "❌ Linting issues found"; \
        fi; \
        if command -v deadnix >/dev/null 2>&1; then \
            deadnix --fail "home/users/{{template}}.nix" && echo "✅ No dead code" || echo "❌ Dead code found"; \
        fi; \
    else \
        echo "Template not found: {{template}}"; \
        just list-users; \
    fi

# macOS Commands - NixOS VMs and ISOs for Mac users

# Show available macOS configurations
list-macos:
    @echo "📱 NixOS Configurations for macOS Users:"
    @echo ""
    @echo "🖥️  VMs (UTM/QEMU on Mac):"
    @echo "   • desktop-macos        - GNOME desktop VM (Apple Silicon)"
    @echo "   • laptop-macos         - Laptop simulation VM (Apple Silicon)"
    @echo "   • server-macos         - Headless server VM (Apple Silicon)"
    @echo "   • *-macos-intel        - Intel Mac variants (x86_64)"
    @echo ""
    @echo "💿 ISOs (Bootable installers):"
    @echo "   • installer-desktop-macos      - Desktop installer ISO"
    @echo "   • installer-minimal-macos      - Minimal server ISO"
    @echo "   • *-macos-aarch64              - Apple Silicon ISOs"
    @echo ""
    @echo "🏗️  Build Commands:"
    @echo "   just build-macos-vm desktop    # Build desktop VM"
    @echo "   just build-macos-iso minimal   # Build minimal ISO"
    @echo "   just build-all-macos           # Build everything"
    @echo ""
    @echo "📚 See: just macos-help for detailed instructions"

# Build macOS VM configurations
build-macos-vm type="desktop" arch="aarch64":
    #!/usr/bin/env bash
    echo "🍎 Building NixOS {{type}} VM for macOS ({{arch}})"

    case "{{arch}}" in
        aarch64|arm64)
            arch_suffix=""
            ;;
        x86_64|intel)
            arch_suffix="-intel"
            ;;
        *)
            echo "❌ Invalid architecture: {{arch}}"
            echo "Available: aarch64, arm64, x86_64, intel"
            exit 1
            ;;
    esac

    case "{{type}}" in
        desktop)
            nix build ".#nixosConfigurations.desktop-macos${arch_suffix}.config.system.build.vm"
            echo "✅ Desktop VM built for macOS!"
            echo "📍 VM runner: result/bin/run-desktop-macos-vm"
            ;;
        laptop)
            nix build ".#nixosConfigurations.laptop-macos${arch_suffix}.config.system.build.vm"
            echo "✅ Laptop VM built for macOS!"
            echo "📍 VM runner: result/bin/run-laptop-macos-vm"
            ;;
        server)
            nix build ".#nixosConfigurations.server-macos${arch_suffix}.config.system.build.vm"
            echo "✅ Server VM built for macOS!"
            echo "📍 VM runner: result/bin/run-server-macos-vm"
            ;;
        *)
            echo "❌ Invalid VM type: {{type}}"
            echo "Available: desktop, laptop, server"
            exit 1
            ;;
    esac

    echo ""
    echo "🚀 To run the VM:"
    echo "   ./result/bin/run-*-vm"
    echo ""
    echo "💡 For UTM import, create a new VM and use the generated QEMU command"
    echo "💡 Login: nixos/nixos (or laptop-user/server-admin depending on type)"

# Build macOS ISO configurations
build-macos-iso type="minimal" arch="x86_64":
    #!/usr/bin/env bash
    echo "🍎 Building NixOS {{type}} installer ISO for macOS ({{arch}})"

    case "{{arch}}" in
        x86_64|intel)
            arch_suffix=""
            ;;
        aarch64|arm64)
            arch_suffix="-aarch64"
            ;;
        *)
            echo "❌ Invalid architecture: {{arch}}"
            echo "Available: x86_64, intel, aarch64, arm64"
            exit 1
            ;;
    esac

    case "{{type}}" in
        minimal)
            nix build ".#nixosConfigurations.installer-minimal-macos${arch_suffix}.config.system.build.isoImage"
            echo "✅ Minimal installer ISO built for macOS!"
            echo "📍 Location: result/iso/nixos-minimal-macos-installer.iso"
            ;;
        desktop)
            nix build ".#nixosConfigurations.installer-desktop-macos${arch_suffix}.config.system.build.isoImage"
            echo "✅ Desktop installer ISO built for macOS!"
            echo "📍 Location: result/iso/nixos-desktop-macos-installer.iso"
            ;;
        *)
            echo "❌ Invalid ISO type: {{type}}"
            echo "Available: minimal, desktop"
            exit 1
            ;;
    esac

    echo "💾 Size: $(du -h result/iso/*.iso | cut -f1)"
    echo ""
    echo "🚀 Usage:"
    echo "   • Import into UTM as CD/DVD"
    echo "   • Boot from ISO in QEMU VM"
    echo "   • Create bootable USB: just create-bootable-usb <iso> <device>"

# Test macOS configurations
test-macos type="desktop" arch="aarch64":
    #!/usr/bin/env bash
    echo "🧪 Testing {{type}} macOS configuration ({{arch}})"

    case "{{arch}}" in
        aarch64|arm64)
            arch_suffix=""
            ;;
        x86_64|intel)
            arch_suffix="-intel"
            ;;
        *)
            echo "❌ Invalid architecture: {{arch}}"
            exit 1
            ;;
    esac

    case "{{type}}" in
        desktop)
            nix build ".#nixosConfigurations.desktop-macos${arch_suffix}.config.system.build.toplevel" --no-link
            ;;
        laptop)
            nix build ".#nixosConfigurations.laptop-macos${arch_suffix}.config.system.build.toplevel" --no-link
            ;;
        server)
            nix build ".#nixosConfigurations.server-macos${arch_suffix}.config.system.build.toplevel" --no-link
            ;;
        *)
            echo "❌ Invalid type: {{type}}"
            exit 1
            ;;
    esac

    echo "✅ {{type}} configuration builds successfully for {{arch}}"

# Build all macOS configurations
build-all-macos:
    @echo "🍎 Building all NixOS configurations for macOS..."

    @echo "📱 Building VMs for Apple Silicon..."
    just build-macos-vm desktop aarch64
    just build-macos-vm laptop aarch64
    just build-macos-vm server aarch64

    @echo "📱 Building VMs for Intel Macs..."
    just build-macos-vm desktop x86_64
    just build-macos-vm laptop x86_64
    just build-macos-vm server x86_64

    @echo "💿 Building ISOs..."
    just build-macos-iso minimal x86_64
    just build-macos-iso desktop x86_64
    just build-macos-iso minimal aarch64
    just build-macos-iso desktop aarch64

    @echo ""
    @echo "✅ All macOS configurations built!"
    @echo "📦 Check result/ directory for built artifacts"

# Show macOS installation help
macos-help:
    @echo "🍎 NixOS on macOS - Complete Guide"
    @echo "=================================="
    @echo ""
    @echo "🎯 Purpose:"
    @echo "   Run and test NixOS configurations on Mac using UTM/QEMU"
    @echo ""
    @echo "📋 Available Configurations:"
    @echo "   VM Types:  desktop, laptop, server"
    @echo "   Archs:     aarch64 (Apple Silicon), x86_64 (Intel Mac)"
    @echo "   ISOs:      minimal (CLI), desktop (GNOME)"
    @echo ""
    @echo "🚀 Quick Start:"
    @echo "   1. just build-macos-vm desktop       # Build desktop VM"
    @echo "   2. ./result/bin/run-desktop-macos-vm # Run the VM"
    @echo "   3. Login: nixos/nixos                # Default credentials"
    @echo ""
    @echo "💿 ISO Installation:"
    @echo "   1. just build-macos-iso desktop      # Build installer ISO"
    @echo "   2. Import ISO into UTM as CD/DVD     # Create new VM in UTM"
    @echo "   3. Boot from ISO and install         # Follow installation guide"
    @echo ""
    @echo "🖥️  UTM Setup (Recommended):"
    @echo "   • Download UTM from Mac App Store or GitHub"
    @echo "   • Create new VM with 'Virtualize' (Apple Silicon) or 'Emulate' (Intel)"
    @echo "   • Architecture: ARM64 (M1/M2/M3) or x86_64 (Intel)"
    @echo "   • RAM: 4GB+ for desktop, 2GB for server"
    @echo "   • Storage: 20GB+ for full installation"
    @echo ""
    @echo "⚡ Performance Tips:"
    @echo "   • Apple Silicon: Use aarch64 VMs for native speed"
    @echo "   • Intel Mac: Use x86_64 VMs for best compatibility"
    @echo "   • Enable hardware acceleration in UTM"
    @echo "   • Use 'Virtualize' mode for better performance"
    @echo ""
    @echo "🔧 Advanced Usage:"
    @echo "   • Import VM disk images into UTM"
    @echo "   • Use serial console for headless server access"
    @echo "   • Network bridging for server VMs"
    @echo "   • Shared folders between macOS and NixOS"
    @echo ""
    @echo "📚 Documentation:"
    @echo "   • Configuration files: hosts/macos-vms/"
    @echo "   • ISO configurations: hosts/macos-isos/"
    @echo "   • Template examples available for customization"
    @echo ""
    @echo "🆘 Troubleshooting:"
    @echo "   • VM won't boot: Check architecture match (ARM64 vs x86_64)"
    @echo "   • Slow performance: Enable hardware acceleration"
    @echo "   • Network issues: Use bridged networking"
    @echo "   • No display: Try VNC or serial console"

# Test all macOS configurations
test-all-macos:
    @echo "🧪 Testing all macOS configurations..."

    @echo "Testing Apple Silicon (aarch64) VMs..."
    just test-macos desktop aarch64
    just test-macos laptop aarch64
    just test-macos server aarch64

    @echo "Testing Intel Mac (x86_64) VMs..."
    just test-macos desktop x86_64
    just test-macos laptop x86_64
    just test-macos server x86_64

    @echo "Testing ISOs..."
    just test installer-minimal-macos
    just test installer-desktop-macos

    @echo ""
    @echo "✅ All macOS configurations test successfully!"

# Create macOS installation script (disabled due to parser issues)
create-macos-installer:
    @echo "⚠️  This command is temporarily disabled due to justfile parser issues"
    @echo "📝 You can create a macOS installer script manually using the build-macos-* commands"
