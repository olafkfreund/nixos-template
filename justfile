# NixOS Configuration Justfile
# Provides convenient commands for managing the configuration

# Default hostname (can be overridden)
hostname := `hostname`

# Default recipe
default:
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

# Remove old system generations (keep last 3)
clean-old:
    sudo nix-collect-garbage --delete-older-than 7d
    sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system

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
    echo "Next steps:"
    echo "1. Edit hosts/{{host}}/home.nix to customize:"
    echo "   - Username and email in git configuration"
    echo "   - Desktop environment (import different profile)"
    echo "   - Application selection"
    echo "   - Personal preferences"
    echo "2. Test configuration: just test {{host}}"
    echo "3. Apply configuration: just switch {{host}}"

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