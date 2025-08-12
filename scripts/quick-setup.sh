#!/usr/bin/env bash

# Quick Setup Script for NixOS Template
# Minimal interaction setup with sensible defaults

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default configuration
DEFAULT_USERNAME="nixos"
DEFAULT_HOSTNAME="nixos-system"
DEFAULT_TIMEZONE="UTC"
DEFAULT_LOCALE="en_US.UTF-8"
DEFAULT_KEYBOARD="us"

print_header() {
  clear
  echo -e "${BLUE}"
  echo "╔══════════════════════════════════════╗"
  echo "║        NixOS Template Quick Setup    ║"
  echo "║     Fast setup with smart defaults   ║"
  echo "╚══════════════════════════════════════╝"
  echo -e "${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Quick detection of system type and preferences
detect_system() {
  local vm_type="physical"
  local desktop_recommended="GNOME"
  local development_recommended="yes"
  local hardware_type="desktop"

  # Detect if we're in a VM
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    local virt_type
    virt_type=$(systemd-detect-virt 2>/dev/null || echo "none")
    if [ "$virt_type" != "none" ]; then
      vm_type="$virt_type"
      desktop_recommended="XFCE" # Lighter for VMs
    fi
  fi

  # Detect hardware type using hardware detection script
  if [ -f "./scripts/detect-hardware.sh" ]; then
    hardware_type=$(./scripts/detect-hardware.sh type 2>/dev/null || echo "desktop")
  fi

  # Adjust recommendations based on hardware type
  case "$hardware_type" in
  laptop)
    desktop_recommended="GNOME" # Good power management
    development_recommended="yes"
    ;;
  desktop)
    desktop_recommended="GNOME"
    development_recommended="yes"
    ;;
  workstation)
    desktop_recommended="KDE" # More features for professionals
    development_recommended="yes"
    ;;
  server)
    desktop_recommended="none" # Headless
    development_recommended="minimal"
    ;;
  esac

  # Detect memory for desktop recommendation override
  if [ -f /proc/meminfo ]; then
    local memory_gb
    memory_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    if [ "$memory_gb" -lt 4 ]; then
      desktop_recommended="XFCE"
    elif [ "$memory_gb" -gt 16 ] && [ "$hardware_type" != "server" ]; then
      desktop_recommended="KDE" # Can handle heavier DE
    fi
  fi

  echo "$vm_type:$desktop_recommended:$development_recommended:$hardware_type"
}

generate_quick_config() {
  local hostname="$1"
  local username="$2"
  local vm_type="$3"
  local desktop="$4"
  local enable_dev="$5"
  local hardware_type="$6"

  local host_dir="./hosts/$hostname"
  mkdir -p "$host_dir"

  # Choose base template based on hardware type
  local template_dir=""
  case "$hardware_type" in
  laptop)
    template_dir="laptop-template"
    ;;
  server)
    template_dir="server-template"
    ;;
  workstation)
    template_dir="desktop-template" # Use desktop template for workstations
    ;;
  *)
    template_dir="desktop-template"
    ;;
  esac

  # Copy base template if it exists
  if [ -d "hosts/$template_dir" ]; then
    print_info "Using $hardware_type template as base..."
    cp -r "hosts/$template_dir"/* "$host_dir/" 2>/dev/null || true
  fi

  # Generate hardware config
  print_info "Generating hardware configuration..."
  nixos-generate-config --show-hardware-config >"$host_dir/hardware-configuration.nix"

  # Generate main configuration
  cat >"$host_dir/configuration.nix" <<EOF
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/desktop
$([ "$enable_dev" = "yes" ] && echo "    ../../modules/development")
$([ "$vm_type" != "physical" ] && echo "    ../../modules/virtualization/vm-guest.nix")
  ];

  # System identification
  networking.hostName = "$hostname";
  time.timeZone = "$DEFAULT_TIMEZONE";
  i18n.defaultLocale = "$DEFAULT_LOCALE";
  console.keyMap = "$DEFAULT_KEYBOARD";

  # User configuration
  users.users.$username = {
    isNormalUser = true;
    description = "Primary User";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    initialPassword = "changeme";  # Change on first login
  };

$(
    [ "$vm_type" != "physical" ] && cat <<VMCONFIG
  # VM optimizations
  modules.virtualization.vm-guest = {
    enable = true;
    type = "$vm_type";
    optimizations.performance = true;
    guestTools.enable = true;
  };
VMCONFIG
  )

  # Desktop environment
  modules.desktop = {
    enable = true;
    environment = "$(echo "$desktop" | tr '[:upper:]' '[:lower:]')";
    audio.enable = true;
    printing.enable = $([ "$vm_type" = "physical" ] && echo "true" || echo "false");
  };

$(
    [ "$enable_dev" = "yes" ] && cat <<DEV
  # Development tools
  modules.development = {
    enable = true;
    languages = [ "nix" ];
    git = {
      enable = true;
      userName = "Change Me";
      userEmail = "change@example.com";
    };
  };
DEV
  )

  # SSH server
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Home Manager
  home-manager.users.$username = import ./home.nix;

  # System state version
  system.stateVersion = "25.05";
}
EOF

  # Generate basic home config
  cat >"$host_dir/home.nix" <<EOF
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    firefox
    vim
    git
    htop
    file
    unzip
    wget
    curl
  ];

  programs.git = {
    enable = true;
    userName = lib.mkDefault "Change Me";
    userEmail = lib.mkDefault "change@example.com";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      l = "ls -l";
      ".." = "cd ..";
    };
  };

  home.stateVersion = "25.05";
}
EOF

  print_success "Configuration generated for $hostname"
}

main() {
  print_header

  echo -e "${BLUE}This script will set up NixOS with sensible defaults.${NC}"
  echo -e "${BLUE}For advanced customization, use ./scripts/nixos-setup.sh instead.${NC}"
  echo

  # Basic system info
  print_info "Detecting system configuration..."
  local detection_result
  detection_result=$(detect_system)
  IFS=':' read -r vm_type desktop_rec dev_rec hardware_type <<<"$detection_result"

  print_success "Detected hardware: $hardware_type"
  print_success "Detected environment: $vm_type"
  print_success "Recommended desktop: $desktop_rec"
  echo

  # Minimal user input
  echo -e "${BLUE}Please provide basic system information:${NC}"
  echo

  read -rp "Hostname [$DEFAULT_HOSTNAME]: " hostname
  hostname=${hostname:-$DEFAULT_HOSTNAME}

  read -rp "Username [$DEFAULT_USERNAME]: " username
  username=${username:-$DEFAULT_USERNAME}

  read -rp "Desktop Environment [$desktop_rec]: " desktop
  desktop=${desktop:-$desktop_rec}

  echo
  print_info "Configuration Summary:"
  echo "  Hardware Type: $hardware_type"
  echo "  Hostname: $hostname"
  echo "  Username: $username"
  echo "  Desktop: $desktop"
  echo "  VM Type: $vm_type"
  echo "  Development tools: $dev_rec"
  echo

  read -rp "Proceed with setup? [Y/n]: " confirm
  if [[ $confirm =~ ^[Nn] ]]; then
    print_info "Setup cancelled"
    exit 0
  fi

  # Generate configuration
  print_info "Generating NixOS configuration..."
  generate_quick_config "$hostname" "$username" "$vm_type" "$desktop" "$dev_rec" "$hardware_type"

  # Build and test
  print_info "Testing configuration..."
  if nixos-rebuild dry-run --flake ".#$hostname" >/dev/null 2>&1; then
    print_success "Configuration test passed"
  else
    print_error "Configuration test failed"
    echo "Run 'nixos-rebuild dry-run --flake \".#$hostname\"' for details"
    exit 1
  fi

  # Deploy
  echo
  echo -e "${YELLOW}Ready to deploy the new configuration.${NC}"
  echo -e "${YELLOW}This will modify your system!${NC}"
  echo

  read -rp "Apply configuration now? [y/N]: " apply
  if [[ $apply =~ ^[Yy] ]]; then
    print_info "Applying configuration..."
    if sudo nixos-rebuild switch --flake ".#$hostname"; then
      print_success "System configuration applied successfully!"
      echo
      echo -e "${GREEN}Setup complete!${NC}"
      echo
      echo "Next steps:"
      echo "1. Set password for $username: sudo passwd $username"
      echo "2. Set root password: sudo passwd root"
      echo "3. Reboot to ensure all changes take effect"
      echo "4. Customize your configuration in hosts/$hostname/"
      echo
      echo "Useful commands:"
      echo "  just switch $hostname    - Apply future changes"
      echo "  just test $hostname     - Test changes without applying"
      echo "  just update             - Update packages"
    else
      print_error "Failed to apply configuration"
      exit 1
    fi
  else
    print_info "Configuration ready but not applied"
    echo "To apply later: sudo nixos-rebuild switch --flake \".#$hostname\""
  fi
}

# Check if script is being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
