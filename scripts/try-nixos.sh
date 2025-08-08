#!/usr/bin/env bash
# Try NixOS script for non-NixOS users
# This script helps users on other Linux distributions test NixOS in VMs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on NixOS (if so, redirect to regular setup)
check_if_nixos() {
  if [[ -f /etc/nixos/configuration.nix ]]; then
    log_info "You're running NixOS! Use the regular setup instead:"
    echo "  ./scripts/quick-setup.sh"
    echo "  ./scripts/nixos-setup.sh"
    exit 0
  fi
}

# Detect Linux distribution
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_NAME=$NAME
  else
    log_error "Cannot detect Linux distribution"
    exit 1
  fi

  log_info "Detected: $DISTRO_NAME"
}

# Check if Nix is installed
check_nix() {
  if command -v nix >/dev/null 2>&1; then
    log_success "Nix package manager is installed"
    NIX_VERSION=$(nix --version)
    log_info "Version: $NIX_VERSION"
    return 0
  else
    return 1
  fi
}

# Install Nix package manager
install_nix() {
  log_info "Installing Nix package manager..."
  log_info "This will install Nix with flakes support enabled"

  echo
  read -p "Install Nix package manager? [y/N] " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installing Nix using Determinate Systems installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source Nix environment
    if [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
      # shellcheck disable=SC1090
      . ~/.nix-profile/etc/profile.d/nix.sh
    fi

    log_success "Nix installed successfully!"
  else
    log_info "Skipping Nix installation"
    echo
    echo "To install Nix manually:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    echo
    exit 0
  fi
}

# Check virtualization support
check_virtualization() {
  log_info "Checking virtualization support..."

  # Check if KVM is available
  if [[ -e /dev/kvm ]]; then
    log_success "KVM acceleration available"
    return 0
  else
    log_warning "KVM acceleration not available"
    log_info "VMs will run slower using software emulation"
    return 1
  fi
}

# Show virtualization setup instructions
show_virtualization_setup() {
  log_info "To enable KVM virtualization on your system:"
  echo

  case $DISTRO in
  ubuntu | debian)
    echo "  sudo apt update"
    echo "  sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients"
    echo "  sudo usermod -a -G libvirt,kvm \$USER"
    ;;
  fedora | rhel | centos)
    echo "  sudo dnf install qemu-kvm libvirt"
    echo "  sudo usermod -a -G libvirt,kvm \$USER"
    echo "  sudo systemctl enable --now libvirtd"
    ;;
  arch)
    echo "  sudo pacman -S qemu-base libvirt"
    echo "  sudo usermod -a -G libvirt,kvm \$USER"
    echo "  sudo systemctl enable --now libvirtd"
    ;;
  opensuse*)
    echo "  sudo zypper install qemu-kvm libvirt"
    echo "  sudo usermod -a -G libvirt,kvm \$USER"
    echo "  sudo systemctl enable --now libvirtd"
    ;;
  *)
    echo "  Install qemu-kvm and libvirt packages for your distribution"
    echo "  Add your user to kvm and libvirt groups"
    ;;
  esac

  echo
  echo "After installation, log out and log back in for group changes to take effect."
  echo
}

# List available VMs
list_vms() {
  log_info "Available NixOS VM configurations:"
  echo

  if [[ -d hosts ]]; then
    for vm_dir in hosts/*/; do
      vm_name=$(basename "$vm_dir")

      # Skip non-VM configurations
      case $vm_name in
      *-template | common.nix)
        continue
        ;;
      esac

      config_file="$vm_dir/configuration.nix"
      if [[ -f $config_file ]]; then
        # Try to extract description from configuration
        description=""
        if grep -q "desktop" "$config_file"; then
          description="Desktop environment"
        elif grep -q "server" "$config_file"; then
          description="Server configuration"
        elif grep -q "minimal" "$config_file"; then
          description="Minimal configuration"
        else
          description="NixOS configuration"
        fi

        echo "  $vm_name - $description"
      fi
    done
  fi

  echo
  echo "Recommended for first try: desktop-test"
}

# Build VM
build_vm() {
  local vm_name=${1:-desktop-test}

  log_info "Building NixOS VM: $vm_name"
  log_info "This may take several minutes on first build..."
  echo

  # Check if flake.nix exists
  if [[ ! -f flake.nix ]]; then
    log_error "flake.nix not found. Are you in the nixos-template directory?"
    exit 1
  fi

  # Build the VM
  if nix build ".#nixosConfigurations.$vm_name.config.system.build.vm"; then
    log_success "VM built successfully!"
    echo
    echo "To run the VM:"
    echo "  ./result/bin/run-$vm_name-vm"
    echo
    echo "Login credentials:"
    echo "  Username: vm-user"
    echo "  Password: nixos"
    echo

    # Ask if user wants to run now
    read -p "Run the VM now? [y/N] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Starting VM..."
      "./result/bin/run-$vm_name-vm"
    else
      log_info "VM ready to run with: ./result/bin/run-$vm_name-vm"
    fi
  else
    log_error "Failed to build VM"
    echo
    echo "Troubleshooting:"
    echo "  1. Check flake syntax: nix flake check"
    echo "  2. Update flake inputs: nix flake update"
    echo "  3. See full documentation: docs/NON-NIXOS-USAGE.md"
    exit 1
  fi
}

# Main function
main() {
  echo "============================================"
  echo "  Try NixOS - VM Testing for Non-NixOS Users"
  echo "============================================"
  echo

  # Check if already on NixOS
  check_if_nixos

  # Detect distribution
  detect_distro

  # Check Nix installation
  if ! check_nix; then
    install_nix
  fi

  # Check virtualization
  if ! check_virtualization; then
    echo
    read -p "Continue without KVM acceleration? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      show_virtualization_setup
      echo "Run this script again after setting up virtualization."
      exit 0
    fi
  fi

  # Show available VMs
  list_vms

  # Ask which VM to build
  echo "Which VM would you like to try?"
  read -r -p "VM name [desktop-test]: " vm_choice
  vm_choice=${vm_choice:-desktop-test}

  # Build and optionally run VM
  build_vm "$vm_choice"

  echo
  log_success "NixOS VM testing setup complete!"
  echo
  echo "Next steps:"
  echo "  1. Explore NixOS in the VM"
  echo "  2. Edit configurations in hosts/$vm_choice/"
  echo "  3. Rebuild with: nix build .#nixosConfigurations.$vm_choice.config.system.build.vm"
  echo "  4. Read full guide: docs/NON-NIXOS-USAGE.md"
  echo
  echo "Happy NixOS exploration!"
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
