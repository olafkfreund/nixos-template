#!/usr/bin/env bash
# NixOS on macOS - Try NixOS Script
# Helps Mac users easily try NixOS using UTM/QEMU

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Main header
echo -e "${BLUE}🍎 Try NixOS on macOS${NC}"
echo "===================="
echo ""

# Check if we're on macOS
if [[ $OSTYPE != "darwin"* ]]; then
  log_error "This script is designed for macOS only."
  echo "For other systems, use: ./scripts/try-nixos.sh"
  exit 1
fi

# Detect Mac architecture
if [[ $(uname -m) == "arm64" ]]; then
  ARCH="aarch64"
  ARCH_DESC="Apple Silicon (M1/M2/M3)"
else
  ARCH="x86_64"
  ARCH_DESC="Intel Mac"
fi

log_info "Detected: $ARCH_DESC"
echo ""

# Check for Nix installation
if ! command -v nix >/dev/null 2>&1; then
  log_error "Nix is not installed. Installing Nix first..."
  echo ""
  echo "Run this command to install Nix:"
  echo "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  echo ""
  echo "After installation, restart your terminal and run this script again."
  exit 1
fi

# Check if flakes are enabled
if ! nix --version | grep -q "flakes" 2>/dev/null; then
  log_warning "Experimental features may not be enabled."
  echo "If builds fail, enable flakes with:"
  echo "echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf"
  echo ""
fi

# Show available options
echo "🎯 What would you like to try?"
echo ""
echo "VM OPTIONS (Run directly on macOS):"
echo "  1. 🖥️  Desktop VM      - Full GNOME desktop (4GB RAM recommended)"
echo "  2. 💻 Laptop VM       - Laptop simulation with power management"
echo "  3. 🖧  Server VM       - Headless server for development"
echo ""
echo "ISO OPTIONS (For UTM installation):"
echo "  4. 💿 Desktop ISO     - Bootable installer with GNOME"
echo "  5. 🔧 Minimal ISO     - Lightweight CLI installer"
echo ""
echo "QUICK OPTIONS:"
echo "  6. 🚀 Quick Desktop   - Build and run desktop VM immediately"
echo "  7. ℹ️  Help & Info     - Show detailed information"
echo ""

read -r -p "Choose an option (1-7): " choice

case $choice in
1)
  VM_TYPE="desktop"
  ACTION="vm"
  ;;
2)
  VM_TYPE="laptop"
  ACTION="vm"
  ;;
3)
  VM_TYPE="server"
  ACTION="vm"
  ;;
4)
  ISO_TYPE="desktop"
  ACTION="iso"
  ;;
5)
  ISO_TYPE="minimal"
  ACTION="iso"
  ;;
6)
  VM_TYPE="desktop"
  ACTION="quick"
  ;;
7)
  ACTION="help"
  ;;
*)
  log_error "Invalid choice: $choice"
  exit 1
  ;;
esac

if [[ $ACTION == "help" ]]; then
  echo ""
  echo "🍎 NixOS on macOS - Detailed Information"
  echo "======================================="
  echo ""
  echo "ARCHITECTURE SUPPORT:"
  echo "• Apple Silicon (M1/M2/M3): Native aarch64 Linux VMs"
  echo "• Intel Macs: x86_64 Linux VMs with good performance"
  echo ""
  echo "VIRTUALIZATION OPTIONS:"
  echo "• UTM (Recommended): GUI virtualization app from Mac App Store"
  echo "• QEMU: Command-line virtualization (what this script uses)"
  echo "• Parallels/VMware: Can import QEMU images"
  echo ""
  echo "VM TYPES EXPLAINED:"
  echo "• Desktop: Full GNOME desktop environment with development tools"
  echo "• Laptop: Optimized for laptop features (battery, WiFi, etc.)"
  echo "• Server: Headless with SSH, containers, development servers"
  echo ""
  echo "ISO TYPES EXPLAINED:"
  echo "• Desktop ISO: Graphical installer with GNOME desktop"
  echo "• Minimal ISO: Command-line installer for servers"
  echo ""
  echo "RESOURCE REQUIREMENTS:"
  echo "• Desktop VM: 4GB RAM, 20GB storage"
  echo "• Laptop VM: 3GB RAM, 15GB storage"
  echo "• Server VM: 2GB RAM, 10GB storage"
  echo ""
  echo "AFTER BUILDING:"
  echo "• VMs: Run with ./result/bin/run-*-vm"
  echo "• ISOs: Import into UTM or use with QEMU"
  echo "• Default login: nixos/nixos"
  echo ""
  echo "PERFORMANCE TIPS:"
  echo "• Enable hardware acceleration in UTM"
  echo "• Use 'Virtualize' mode for Apple Silicon"
  echo "• Allocate sufficient RAM for smooth operation"
  echo ""
  echo "NEXT STEPS:"
  echo "• Customize configurations in hosts/macos-vms/"
  echo "• Build your own NixOS system"
  echo "• Deploy to real hardware when ready"
  echo ""
  echo "For more help: just macos-help"
  exit 0
fi

echo ""

if [[ $ACTION == "vm" ]]; then
  log_info "Building $VM_TYPE VM for $ARCH_DESC..."
  echo "This may take 5-15 minutes depending on your internet connection."
  echo ""

  # Determine configuration name
  if [[ $ARCH == "aarch64" ]]; then
    CONFIG_NAME="${VM_TYPE}-macos"
  else
    CONFIG_NAME="${VM_TYPE}-macos-intel"
  fi

  # Build the VM
  log_info "Running: nix build .#nixosConfigurations.${CONFIG_NAME}.config.system.build.vm"
  if nix build ".#nixosConfigurations.${CONFIG_NAME}.config.system.build.vm"; then
    log_success "$VM_TYPE VM built successfully!"
    echo ""
    echo "🚀 To start the VM:"
    echo "   ./result/bin/run-*-vm"
    echo ""
    echo "🔑 Default login credentials:"
    case $VM_TYPE in
    desktop)
      echo "   Username: nixos"
      echo "   Password: nixos"
      ;;
    laptop)
      echo "   Username: laptop-user"
      echo "   Password: nixos"
      ;;
    server)
      echo "   Username: server-admin"
      echo "   Password: nixos"
      echo "   SSH: ssh server-admin@<vm-ip>"
      ;;
    esac
    echo ""
    echo "💡 VM Features:"
    case $VM_TYPE in
    desktop)
      echo "   • Full GNOME desktop environment"
      echo "   • Firefox, VS Code, development tools"
      echo "   • Guest integration with clipboard sharing"
      ;;
    laptop)
      echo "   • Laptop-optimized with power management"
      echo "   • NetworkManager for WiFi simulation"
      echo "   • Redshift for eye care"
      ;;
    server)
      echo "   • Headless server (no GUI)"
      echo "   • SSH server enabled"
      echo "   • Podman containers, development servers"
      echo "   • Access via terminal or SSH"
      ;;
    esac
  else
    log_error "Failed to build $VM_TYPE VM"
    echo ""
    echo "Common issues and solutions:"
    echo "• Check internet connection"
    echo "• Ensure sufficient disk space (5GB+)"
    echo "• Try: nix-collect-garbage -d to free space"
    echo "• Enable experimental features if not done"
    exit 1
  fi

elif [[ $ACTION == "iso" ]]; then
  log_info "Building $ISO_TYPE installer ISO for $ARCH_DESC..."
  echo "This may take 10-20 minutes depending on your internet connection."
  echo ""

  # Determine configuration name
  if [[ $ARCH == "aarch64" ]]; then
    CONFIG_NAME="installer-${ISO_TYPE}-macos-aarch64"
  else
    CONFIG_NAME="installer-${ISO_TYPE}-macos"
  fi

  # Build the ISO
  log_info "Running: nix build .#nixosConfigurations.${CONFIG_NAME}.config.system.build.isoImage"
  if nix build ".#nixosConfigurations.${CONFIG_NAME}.config.system.build.isoImage"; then
    log_success "$ISO_TYPE installer ISO built successfully!"
    echo ""
    echo "📍 ISO Location:"
    find result/iso/ -name "*.iso" 2>/dev/null || echo "   result/iso/nixos-${ISO_TYPE}-macos-installer.iso"
    echo ""
    echo "💾 ISO Size:"
    du -h result/iso/*.iso 2>/dev/null | head -1 || echo "   Check result/iso/ directory"
    echo ""
    echo "🚀 How to use the ISO:"
    echo "   1. Download UTM from Mac App Store"
    echo "   2. Create new VM in UTM"
    echo "   3. Choose 'Virtualize' for Apple Silicon or 'Emulate' for Intel"
    echo "   4. Set architecture: ARM64 (Apple Silicon) or x86_64 (Intel)"
    echo "   5. Attach ISO as CD/DVD drive"
    echo "   6. Allocate 4GB+ RAM and 20GB+ storage"
    echo "   7. Boot from ISO and follow installer"
    echo ""
    echo "🔑 Default installer login:"
    echo "   Username: nixos"
    echo "   Password: nixos"
  else
    log_error "Failed to build $ISO_TYPE ISO"
    exit 1
  fi

elif [[ $ACTION == "quick" ]]; then
  log_info "Quick setup: Building and starting desktop VM..."
  echo ""

  # Determine configuration name
  if [[ $ARCH == "aarch64" ]]; then
    CONFIG_NAME="desktop-macos"
  else
    CONFIG_NAME="desktop-macos-intel"
  fi

  # Build the VM
  log_info "Building desktop VM..."
  if nix build ".#nixosConfigurations.${CONFIG_NAME}.config.system.build.vm"; then
    log_success "Desktop VM built successfully!"
    echo ""
    log_info "Starting desktop VM..."
    echo "🖥️  NixOS desktop is starting..."
    echo "🔑 Login: nixos/nixos"
    echo "⌨️  Press Ctrl+Alt+G to release mouse/keyboard from VM"
    echo ""

    # Start the VM
    # Find and execute the VM runner script
    vm_runner=$(find ./result/bin/ -name "run-*-vm" -type f | head -1)
    if [[ -n $vm_runner && -x $vm_runner ]]; then
      "$vm_runner"
    else
      log_error "VM runner script not found in ./result/bin/"
      echo "Try running manually: ./result/bin/run-desktop-macos-vm"
    fi
  else
    log_error "Failed to build desktop VM"
    exit 1
  fi
fi

echo ""
log_success "Done! Enjoy exploring NixOS on your Mac! 🎉"
echo ""
echo "📚 Next steps:"
echo "   • Customize configurations in hosts/macos-vms/"
echo "   • Learn NixOS: https://nixos.org/learn.html"
echo "   • Join community: https://discourse.nixos.org"
echo ""
echo "❓ Need help? Run: just macos-help"
