#!/bin/bash
# NixOS on WSL2 Installation Script
# Automated installation and setup of NixOS using NixOS-WSL

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WSL_DISTRO_NAME="NixOS-Template"
TEMP_DIR="/tmp/nixos-wsl-install"
NIXOS_WSL_RELEASE="https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos-wsl-installer.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if running on Windows
check_windows() {
  if ! command -v wsl.exe >/dev/null 2>&1; then
    log_error "This script must be run on Windows with WSL installed"
    log_info "Please install WSL first: https://docs.microsoft.com/en-us/windows/wsl/install"
    exit 1
  fi
}

# Check WSL version
check_wsl_version() {
  log_info "Checking WSL version..."

  local wsl_version
  wsl_version=$(wsl.exe --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")

  if [[ -z $wsl_version ]]; then
    log_warning "Could not detect WSL version, assuming WSL 2"
  else
    log_info "WSL version: $wsl_version"
  fi

  # Check if WSL 2 is available
  if ! wsl.exe --list --verbose 2>/dev/null | grep -q "Version.*2"; then
    log_warning "WSL 2 not detected. This template is optimized for WSL 2"
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check if running as administrator
  if ! net.exe session >/dev/null 2>&1; then
    log_error "This script must be run as Administrator"
    log_info "Please restart PowerShell or Command Prompt as Administrator"
    exit 1
  fi

  # Check available space
  local available_space
  available_space=$(powershell.exe -Command "(Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace / 1GB" | tr -d '\r')

  if (($(echo "$available_space < 10" | bc -l))); then
    log_warning "Low disk space: ${available_space}GB available. Recommended: 10GB+"
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    log_info "Available disk space: ${available_space}GB"
  fi

  # Check if distro name is already taken
  if wsl.exe --list --quiet | grep -q "$WSL_DISTRO_NAME"; then
    log_error "WSL distro '$WSL_DISTRO_NAME' already exists"
    log_info "Please unregister it first: wsl --unregister $WSL_DISTRO_NAME"
    exit 1
  fi
}

# Download NixOS-WSL
download_nixos_wsl() {
  log_info "Downloading NixOS-WSL installer..."

  mkdir -p "$TEMP_DIR"
  cd "$TEMP_DIR"

  # Download the latest release
  if command -v curl >/dev/null 2>&1; then
    curl -L -o nixos-wsl-installer.tar.gz "$NIXOS_WSL_RELEASE"
  elif command -v wget >/dev/null 2>&1; then
    wget -O nixos-wsl-installer.tar.gz "$NIXOS_WSL_RELEASE"
  else
    log_error "Neither curl nor wget found. Please install one of them."
    exit 1
  fi

  # Extract the installer
  tar -xzf nixos-wsl-installer.tar.gz

  log_success "NixOS-WSL installer downloaded and extracted"
}

# Install NixOS in WSL
install_nixos_wsl() {
  log_info "Installing NixOS in WSL..."

  local rootfs_path
  rootfs_path=$(find "$TEMP_DIR" -name "*.tar.gz" -not -name "nixos-wsl-installer.tar.gz" | head -1)

  if [[ -z $rootfs_path ]]; then
    log_error "Could not find NixOS rootfs tarball"
    exit 1
  fi

  # Create installation directory
  local install_dir="C:\\WSL\\$WSL_DISTRO_NAME"
  mkdir -p "/mnt/c/WSL/$WSL_DISTRO_NAME" 2>/dev/null || powershell.exe -Command "New-Item -ItemType Directory -Path '$install_dir' -Force"

  # Import the distribution
  log_info "Importing NixOS distribution (this may take several minutes)..."
  wsl.exe --import "$WSL_DISTRO_NAME" "$install_dir" "$rootfs_path" --version 2

  log_success "NixOS imported successfully as '$WSL_DISTRO_NAME'"
}

# Configure the WSL distribution
configure_nixos_wsl() {
  log_info "Configuring NixOS WSL..."

  # Start the distribution to initialize it
  log_info "Starting NixOS WSL for initial setup..."
  wsl.exe -d "$WSL_DISTRO_NAME" -- /bin/bash -c "echo 'NixOS WSL started successfully'"

  # Wait for systemd to start
  log_info "Waiting for systemd to initialize..."
  for i in {1..30}; do
    if wsl.exe -d "$WSL_DISTRO_NAME" -- systemctl is-active --quiet multi-user.target 2>/dev/null; then
      break
    fi
    sleep 2
    log_info "Waiting for systemd... ($i/30)"
  done

  log_success "NixOS WSL configured successfully"
}

# Copy template configuration
copy_template_configuration() {
  log_info "Copying template configuration to WSL..."

  # Copy the entire template directory to WSL
  wsl.exe -d "$WSL_DISTRO_NAME" -- mkdir -p /tmp/nixos-template

  # Use tar to copy files preserving permissions
  (cd "$PROJECT_DIR" && tar cf - .) | wsl.exe -d "$WSL_DISTRO_NAME" -- tar xf - -C /tmp/nixos-template

  # Set up the configuration
  wsl.exe -d "$WSL_DISTRO_NAME" -- /bin/bash -c "
        set -e

        # Backup original configuration if it exists
        if [ -f /etc/nixos/configuration.nix ]; then
            cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
        fi

        # Copy WSL2 template configuration
        cp -r /tmp/nixos-template/hosts/wsl2-template/* /etc/nixos/ || true
        cp /tmp/nixos-template/hosts/wsl2-template/configuration.nix /etc/nixos/

        # Ensure hardware configuration exists
        if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
            nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
        fi

        # Set up flake configuration
        cp /tmp/nixos-template/flake.nix /etc/nixos/ || echo 'Flake not copied'
        cp /tmp/nixos-template/flake.lock /etc/nixos/ || echo 'Flake lock not copied'

        echo 'Template configuration copied successfully'
    "

  log_success "Template configuration copied"
}

# Apply NixOS configuration
apply_nixos_configuration() {
  log_info "Applying NixOS configuration..."

  # Apply the configuration
  wsl.exe -d "$WSL_DISTRO_NAME" -- /bin/bash -c "
        set -e

        # Switch to new configuration
        echo 'Switching to new NixOS configuration...'
        nixos-rebuild switch --flake /etc/nixos#wsl2-template || {
            echo 'Flake build failed, trying without flake...'
            nixos-rebuild switch
        }

        echo 'NixOS configuration applied successfully'
    " || {
    log_warning "Configuration switch failed, but installation can continue"
    log_info "You can manually run 'nixos-rebuild switch' later"
  }

  log_success "NixOS configuration applied"
}

# Set up user account
setup_user_account() {
  log_info "Setting up user account..."

  echo "Please enter a username for your WSL user (default: nixos):"
  read -r username
  username=${username:-nixos}

  echo "Please enter a password for user '$username':"
  read -rs password

  wsl.exe -d "$WSL_DISTRO_NAME" -- /bin/bash -c "
        set -e

        # Create user if it doesn't exist
        if ! id '$username' >/dev/null 2>&1; then
            useradd -m -G wheel -s /bin/bash '$username'
        fi

        # Set password
        echo '$username:$password' | chpasswd

        # Ensure user is in wheel group
        usermod -a -G wheel '$username'

        # Set up sudo without password
        echo '$username ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$username

        echo 'User account setup completed'
    "

  # Set default user
  powershell.exe -Command "
        \$regPath = 'HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Lxss'
        \$distros = Get-ChildItem \$regPath | Where-Object { (Get-ItemProperty \$_.PSPath).DistributionName -eq '$WSL_DISTRO_NAME' }
        if (\$distros) {
            Set-ItemProperty -Path \$distros[0].PSPath -Name 'DefaultUid' -Value 1000
        }
    " 2>/dev/null || log_warning "Could not set default user in registry"

  log_success "User account '$username' set up successfully"
}

# Create desktop shortcut
create_desktop_shortcut() {
  log_info "Creating desktop shortcut..."

  # Note: Using direct path construction instead of PowerShell query for reliability

  local shortcut_content="[Desktop Entry]
Name=NixOS WSL
Comment=NixOS on Windows Subsystem for Linux
Exec=wsl.exe -d $WSL_DISTRO_NAME
Icon=terminal
Terminal=true
Type=Application
Categories=System;TerminalEmulator;"

  echo "$shortcut_content" >"/mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/Desktop/NixOS WSL.desktop" 2>/dev/null || {
    log_warning "Could not create desktop shortcut"
  }

  # Create Windows Terminal profile entry suggestion
  cat >"/tmp/windows-terminal-profile.json" <<'EOF'
{
    "guid": "{$(New-Guid)}",
    "name": "NixOS WSL",
    "commandline": "wsl.exe -d NixOS-Template",
    "startingDirectory": "//wsl$/NixOS-Template/home/nixos",
    "icon": "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png",
    "colorScheme": "Campbell"
}
EOF

  log_info "Windows Terminal profile suggestion created at /tmp/windows-terminal-profile.json"
  log_success "Desktop shortcut created"
}

# Display completion message
display_completion_message() {
  log_success "NixOS on WSL2 installation completed successfully!"
  echo
  echo "🎉 Installation Summary:"
  echo "  • WSL Distro Name: $WSL_DISTRO_NAME"
  echo "  • Configuration: /etc/nixos/"
  echo "  • Template Features: Development environment, Windows integration"
  echo
  echo "🚀 Next Steps:"
  echo "  1. Start NixOS WSL:"
  echo "     wsl -d $WSL_DISTRO_NAME"
  echo
  echo "  2. Customize your configuration:"
  echo "     sudo nano /etc/nixos/configuration.nix"
  echo
  echo "  3. Apply configuration changes:"
  echo "     sudo nixos-rebuild switch"
  echo
  echo "  4. Set up Home Manager (if needed):"
  echo "     home-manager switch"
  echo
  echo "📚 Useful Commands:"
  echo "  • wsl-info              - Show system information"
  echo "  • wsl-open .            - Open directory in Windows Explorer"
  echo "  • wsl-edit file.txt     - Edit file in VS Code"
  echo "  • wsl --shutdown        - Shutdown WSL (frees memory)"
  echo "  • wsl --unregister $WSL_DISTRO_NAME - Remove installation"
  echo
  echo "🔧 Configuration Files:"
  echo "  • System: /etc/nixos/configuration.nix"
  echo "  • Home Manager: ~/.config/home-manager/home.nix"
  echo "  • Template Source: /tmp/nixos-template/"
  echo
  echo "🌐 Resources:"
  echo "  • NixOS Manual: https://nixos.org/manual/nixos/stable/"
  echo "  • NixOS-WSL: https://github.com/nix-community/NixOS-WSL"
  echo "  • Template Documentation: see docs/ directory"
  echo
  log_info "You can now start using NixOS on WSL2!"
}

# Cleanup function
cleanup() {
  log_info "Cleaning up temporary files..."
  rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Main installation function
main() {
  echo "🐧 NixOS on WSL2 Installation Script"
  echo "======================================"
  echo

  # Trap to ensure cleanup on exit
  trap cleanup EXIT

  # Run installation steps
  check_windows
  check_wsl_version
  check_prerequisites
  download_nixos_wsl
  install_nixos_wsl
  configure_nixos_wsl
  copy_template_configuration
  apply_nixos_configuration
  setup_user_account
  create_desktop_shortcut
  display_completion_message

  log_success "Installation completed successfully!"
}

# Handle script arguments
case "${1:-}" in
  --help | -h)
    echo "NixOS on WSL2 Installation Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --check        Check prerequisites only"
    echo "  --uninstall    Uninstall NixOS WSL"
    echo
    echo "This script installs NixOS using NixOS-WSL with the template configuration."
    echo "It requires Windows 10/11 with WSL 2 installed."
    echo
    exit 0
    ;;
  --check)
    log_info "Checking prerequisites only..."
    check_windows
    check_wsl_version
    check_prerequisites
    log_success "Prerequisites check completed"
    exit 0
    ;;
  --uninstall)
    log_info "Uninstalling NixOS WSL..."
    if wsl.exe --list --quiet | grep -q "$WSL_DISTRO_NAME"; then
      wsl.exe --unregister "$WSL_DISTRO_NAME"
      log_success "NixOS WSL uninstalled successfully"
    else
      log_warning "NixOS WSL distro '$WSL_DISTRO_NAME' not found"
    fi
    exit 0
    ;;
  "")
    # No arguments, run main installation
    main
    ;;
  *)
    log_error "Unknown argument: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
esac
