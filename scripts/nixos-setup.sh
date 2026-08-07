#!/usr/bin/env bash

# NixOS Template Setup Script
# Complete setup wizard for new NixOS users
# Handles prerequisites, configuration, and deployment

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"
SETUP_STATE_FILE="$TEMPLATE_ROOT/.setup-state"
LOG_FILE="$TEMPLATE_ROOT/setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
# PURPLE='\033[0;35m' # Unused
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✓"
CROSS="✗"
ARROW="→"
# STAR="★" # Unused
INFO="ℹ"
WARN="⚠"

# Global variables for user configuration
HOSTNAME=""
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""
TIMEZONE=""
LOCALE=""
KEYBOARD_LAYOUT=""
DESKTOP_ENVIRONMENT=""
VM_TYPE=""
ENABLE_SSH=""
ENABLE_SECRETS=""
ENABLE_GAMING=""
ENABLE_VIRTUALIZATION=""
ENABLE_DEVELOPMENT=""
USER_TEMPLATE=""

# Logging functions
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

print_header() {
  clear
  echo -e "${BLUE}${BOLD}"
  echo "╔═══════════════════════════════════════════════════════════════════════╗"
  echo "║                        NixOS Template Setup                          ║"
  echo "║                   Complete Configuration Wizard                      ║"
  echo "╚═══════════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo
}

print_step() {
  echo -e "${GREEN}${BOLD}[STEP]${NC} $1"
  log "STEP: $1"
}

print_info() {
  echo -e "${BLUE}${INFO}${NC} $1"
  log "INFO: $1"
}

print_success() {
  echo -e "${GREEN}${CHECK}${NC} $1"
  log "SUCCESS: $1"
}

print_warning() {
  echo -e "${YELLOW}${WARN}${NC} $1"
  log "WARNING: $1"
}

print_error() {
  echo -e "${RED}${CROSS}${NC} $1"
  log "ERROR: $1"
}

print_progress() {
  echo -e "${CYAN}${ARROW}${NC} $1"
}

# Save/restore setup state
save_state() {
  cat >"$SETUP_STATE_FILE" <<EOF
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
KEYBOARD_LAYOUT="$KEYBOARD_LAYOUT"
DESKTOP_ENVIRONMENT="$DESKTOP_ENVIRONMENT"
VM_TYPE="$VM_TYPE"
ENABLE_SSH="$ENABLE_SSH"
ENABLE_SECRETS="$ENABLE_SECRETS"
ENABLE_GAMING="$ENABLE_GAMING"
ENABLE_VIRTUALIZATION="$ENABLE_VIRTUALIZATION"
ENABLE_DEVELOPMENT="$ENABLE_DEVELOPMENT"
USER_TEMPLATE="$USER_TEMPLATE"
EOF
  log "State saved to $SETUP_STATE_FILE"
}

load_state() {
  if [ -f "$SETUP_STATE_FILE" ]; then
    # shellcheck source=/dev/null
    source "$SETUP_STATE_FILE"
    print_info "Loaded previous setup state"
    return 0
  fi
  return 1
}

# Interactive prompts with validation
prompt_input() {
  local prompt="$1"
  local default="${2:-}"
  local validator="${3:-}"
  local value=""

  while true; do
    if [ -n "$default" ]; then
      echo -ne "${WHITE}$prompt${NC} [${YELLOW}$default${NC}]: "
    else
      echo -ne "${WHITE}$prompt${NC}: "
    fi

    read -r value

    # Use default if empty
    if [ -z "$value" ] && [ -n "$default" ]; then
      value="$default"
    fi

    # Validate input if validator provided
    if [ -n "$validator" ]; then
      # Security: Ensure validator is a declared function and not user input
      if declare -F "$validator" >/dev/null 2>&1; then
        if "$validator" "$value"; then
          echo "$value"
          return 0
        else
          print_error "Invalid input. Please try again."
          continue
        fi
      else
        print_warning "Validator function '$validator' not found, accepting input without validation."
        echo "$value"
        return 0
      fi
    else
      echo "$value"
      return 0
    fi
  done
}

# Validation functions defined later in the script

prompt_password() {
  local prompt="$1"
  local confirm="${2:-true}"
  local password=""
  local confirm_password=""

  while true; do
    echo -ne "${WHITE}$prompt${NC}: "
    read -rs password
    echo

    if [ -z "$password" ]; then
      print_error "Password cannot be empty"
      continue
    fi

    if [ "$confirm" = "true" ]; then
      echo -ne "${WHITE}Confirm password${NC}: "
      read -rs confirm_password
      echo

      if [ "$password" != "$confirm_password" ]; then
        print_error "Passwords do not match"
        continue
      fi
    fi

    echo "$password"
    return 0
  done
}

prompt_choice() {
  local prompt="$1"
  shift
  local choices=("$@")
  local choice=""

  echo -e "${WHITE}$prompt${NC}"
  for i in "${!choices[@]}"; do
    echo "  $((i + 1)). ${choices[$i]}"
  done
  echo

  while true; do
    echo -ne "${WHITE}Enter choice (1-${#choices[@]})${NC}: "
    read -r choice

    if [[ $choice =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#choices[@]}" ]; then
      echo "${choices[$((choice - 1))]}"
      return 0
    else
      print_error "Please enter a number between 1 and ${#choices[@]}"
    fi
  done
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local choice=""

  while true; do
    if [ "$default" = "y" ]; then
      echo -ne "${WHITE}$prompt${NC} [${GREEN}Y${NC}/${RED}n${NC}]: "
    else
      echo -ne "${WHITE}$prompt${NC} [${RED}y${NC}/${GREEN}N${NC}]: "
    fi

    read -r choice
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    if [ -z "$choice" ]; then
      choice="$default"
    fi

    case "$choice" in
    y | yes)
      echo "yes"
      return 0
      ;;
    n | no)
      echo "no"
      return 0
      ;;
    *) print_error "Please answer yes (y) or no (n)" ;;
    esac
  done
}

# Validation functions
validate_hostname() {
  local hostname="$1"
  if [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
    return 0
  fi
  return 1
}

validate_username() {
  local username="$1"
  if [[ $username =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
    return 0
  fi
  return 1
}

validate_timezone() {
  local timezone="$1"
  if [ -f "/usr/share/zoneinfo/$timezone" ] || [ -f "/etc/zoneinfo/$timezone" ]; then
    return 0
  fi
  return 1
}

# Prerequisites checking
check_prerequisites() {
  print_step "Checking system prerequisites"

  local missing_deps=()
  local warnings=()

  # Check if we're on NixOS
  if [ ! -f /etc/NIXOS ]; then
    print_error "This script must be run on NixOS"
    exit 1
  fi
  print_success "Running on NixOS"

  # Check for root/sudo access
  if [ "$EUID" -eq 0 ]; then
    print_success "Running as root"
  elif sudo -n true 2>/dev/null; then
    print_success "Sudo access available"
  else
    print_error "Root or sudo access required"
    exit 1
  fi

  # Check required commands
  local required_commands=("nix" "git" "nixos-rebuild" "nixos-generate-config")
  for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      print_success "$cmd found"
    else
      missing_deps+=("$cmd")
    fi
  done

  # Check optional but recommended commands
  local optional_commands=("dialog" "whiptail" "curl" "wget")
  for cmd in "${optional_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      warnings+=("$cmd not found (optional)")
    fi
  done

  # Check network connectivity
  if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    print_success "Network connectivity OK"
  else
    warnings+=("Network connectivity issues detected")
  fi

  # Check disk space
  local available_space
  available_space=$(df / | awk 'NR==2 {print $4}')
  if [ "$available_space" -gt 5000000 ]; then # 5GB in KB
    print_success "Sufficient disk space available"
  else
    warnings+=("Low disk space: less than 5GB available")
  fi

  # Check memory
  local available_memory
  available_memory=$(free -m | awk 'NR==2{print $7}')
  if [ "$available_memory" -gt 1000 ]; then # 1GB
    print_success "Sufficient memory available"
  else
    warnings+=("Low memory: less than 1GB available")
  fi

  # Report missing dependencies
  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_error "Missing required dependencies: ${missing_deps[*]}"
    print_info "Please install missing dependencies and run this script again"
    exit 1
  fi

  # Report warnings
  if [ ${#warnings[@]} -gt 0 ]; then
    for warning in "${warnings[@]}"; do
      print_warning "$warning"
    done
    echo
    if [ "$(prompt_yes_no "Continue despite warnings?" "y")" = "no" ]; then
      print_info "Setup cancelled by user"
      exit 0
    fi
  fi

  print_success "All prerequisites satisfied"
  echo
}

# Hardware detection
detect_hardware() {
  print_step "Detecting hardware configuration"

  # Detect VM environment
  if command -v "$SCRIPT_DIR/detect-vm.sh" >/dev/null 2>&1; then
    local vm_result
    vm_result=$("$SCRIPT_DIR/detect-vm.sh" | grep "VM_TYPE=" | cut -d= -f2)
    if [ -n "$vm_result" ] && [ "$vm_result" != "none" ]; then
      VM_TYPE="$vm_result"
      print_success "Virtual machine detected: $VM_TYPE"
    else
      VM_TYPE="physical"
      print_success "Physical hardware detected"
    fi
  else
    print_warning "VM detection script not found, assuming physical hardware"
    VM_TYPE="physical"
  fi

  # Detect CPU architecture
  local cpu_arch
  cpu_arch=$(uname -m)
  case "$cpu_arch" in
  x86_64) print_success "Architecture: x86_64 (64-bit)" ;;
  aarch64) print_success "Architecture: ARM64" ;;
  *) print_warning "Unsupported architecture: $cpu_arch" ;;
  esac

  # Detect available memory
  local memory_gb
  memory_gb=$(free -g | awk 'NR==2{printf "%.1f", $2}')
  print_info "Available memory: ${memory_gb}GB"

  # Detect storage devices
  print_info "Storage devices:"
  if command -v lsblk >/dev/null 2>&1; then
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk | while read -r line; do
      print_info "  $line"
    done
  fi

  # Detect network interfaces
  print_info "Network interfaces:"
  ip -o link show | awk '{print "  " $2 " (" $17 ")"}' | sed 's/@[^:]*://' | head -5

  # Detect graphics
  if command -v lspci >/dev/null 2>&1; then
    local gpu_info
    gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -1)
    if [ -n "$gpu_info" ]; then
      print_info "Graphics: $gpu_info"
    fi
  fi

  echo
}

# User configuration collection
collect_user_config() {
  print_step "Collecting user configuration"

  echo -e "${BLUE}Please provide the following information for your NixOS system:${NC}"
  echo

  # Hostname
  local default_hostname="nixos"
  if [ "$VM_TYPE" != "physical" ]; then
    default_hostname="nixos-$VM_TYPE"
  fi
  HOSTNAME=$(prompt_input "Hostname" "$default_hostname" "validate_hostname")

  # Username
  USERNAME=$(prompt_input "Primary username" "nixos" "validate_username")

  # Passwords
  print_info "Setting up user password"
  USER_PASSWORD=$(prompt_password "Password for $USERNAME")

  print_info "Setting up root password"
  ROOT_PASSWORD=$(prompt_password "Root password")

  # Timezone
  print_info "Configure timezone (examples: America/New_York, Europe/London, Asia/Tokyo)"
  local detected_timezone=""
  if command -v timedatectl >/dev/null 2>&1; then
    detected_timezone=$(timedatectl show -p Timezone --value 2>/dev/null || echo "")
  fi
  TIMEZONE=$(prompt_input "Timezone" "${detected_timezone:-UTC}" "validate_timezone")

  # Locale
  local available_locales=("en_US.UTF-8" "en_GB.UTF-8" "de_DE.UTF-8" "fr_FR.UTF-8" "es_ES.UTF-8" "Other")
  LOCALE=$(prompt_choice "Select locale:" "${available_locales[@]}")
  if [ "$LOCALE" = "Other" ]; then
    LOCALE=$(prompt_input "Enter locale" "en_US.UTF-8")
  fi

  # Keyboard layout
  local keyboard_layouts=("us" "uk" "de" "fr" "es" "dvorak" "colemak" "Other")
  KEYBOARD_LAYOUT=$(prompt_choice "Select keyboard layout:" "${keyboard_layouts[@]}")
  if [ "$KEYBOARD_LAYOUT" = "Other" ]; then
    KEYBOARD_LAYOUT=$(prompt_input "Enter keyboard layout" "us")
  fi

  save_state
  print_success "User configuration collected"
  echo
}

# Feature selection
select_features() {
  print_step "Selecting system features"

  echo -e "${BLUE}Choose the features you want to enable:${NC}"
  echo

  # Desktop environment
  if [ "$VM_TYPE" = "physical" ] || [ "$(prompt_yes_no "Install desktop environment?")" = "yes" ]; then
    local desktop_options=("GNOME" "KDE Plasma" "XFCE" "Hyprland" "Niri" "None (Server)")
    DESKTOP_ENVIRONMENT=$(prompt_choice "Select desktop environment:" "${desktop_options[@]}")
  else
    DESKTOP_ENVIRONMENT="None (Server)"
  fi

  # SSH access
  ENABLE_SSH=$(prompt_yes_no "Enable SSH server?" "y")

  # Development tools
  ENABLE_DEVELOPMENT=$(prompt_yes_no "Install development tools?" "y")
  if [ "$ENABLE_DEVELOPMENT" = "yes" ]; then
    local dev_options=("Basic (Git, editors)" "Full (Multiple languages, LSPs)" "Custom")
    local dev_level
    dev_level=$(prompt_choice "Development tools level:" "${dev_options[@]}")
    ENABLE_DEVELOPMENT="$dev_level"
  fi

  # Gaming support
  if [ "$VM_TYPE" = "physical" ] && [ "$DESKTOP_ENVIRONMENT" != "None (Server)" ]; then
    ENABLE_GAMING=$(prompt_yes_no "Enable gaming support (Steam, drivers)?" "n")
  else
    ENABLE_GAMING="no"
  fi

  # Virtualization
  if [ "$VM_TYPE" = "physical" ]; then
    ENABLE_VIRTUALIZATION=$(prompt_yes_no "Enable virtualization support (VMs, containers)?" "n")
  else
    ENABLE_VIRTUALIZATION="no"
  fi

  # Secrets management
  ENABLE_SECRETS=$(prompt_yes_no "Set up secrets management (agenix)?" "n")

  # User template selection
  local template_options=("Basic user" "Developer" "Gamer" "Minimal" "Server admin")
  USER_TEMPLATE=$(prompt_choice "Select user template:" "${template_options[@]}")

  save_state
  print_success "Features selected"
  echo
}

# Configuration generation
generate_configuration() {
  print_step "Generating NixOS configuration"

  local host_dir="$TEMPLATE_ROOT/hosts/$HOSTNAME"
  mkdir -p "$host_dir"

  print_progress "Creating host configuration directory: $host_dir"

  # Generate hardware configuration
  print_progress "Generating hardware configuration"
  if ! nixos-generate-config --show-hardware-config >"$host_dir/hardware-configuration.nix"; then
    print_error "Failed to generate hardware configuration"
    return 1
  fi
  print_success "Hardware configuration generated"

  # Determine base template
  local base_template="example-desktop"
  case "$VM_TYPE" in
  qemu | kvm) base_template="qemu-vm" ;;
  virtualbox) base_template="virtualbox-vm" ;;
  *)
    if [ "$DESKTOP_ENVIRONMENT" = "None (Server)" ]; then
      base_template="example-server"
    fi
    ;;
  esac

  print_progress "Using base template: $base_template"

  # Generate main configuration
  cat >"$host_dir/configuration.nix" <<EOF
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix

    # Common configuration
    ../common.nix

    # Core modules
    ../../modules/core

    # Desktop environment
$([ "$DESKTOP_ENVIRONMENT" != "None (Server)" ] && echo "    ../../modules/desktop")

    # Development tools
$([ "$ENABLE_DEVELOPMENT" != "no" ] && echo "    ../../modules/development")

    # Gaming support
$([ "$ENABLE_GAMING" = "yes" ] && echo "    ../../modules/gaming")

    # Virtualization support
$([ "$ENABLE_VIRTUALIZATION" = "yes" ] && echo "    ../../modules/virtualization")

    # VM guest optimizations
$([ "$VM_TYPE" != "physical" ] && echo "    ../../modules/virtualization/vm-guest.nix")

    # Secrets management
$([ "$ENABLE_SECRETS" = "yes" ] && echo "    ../../modules/security/agenix.nix")

    # Host-specific secrets
$([ "$ENABLE_SECRETS" = "yes" ] && echo "    ./secrets.nix")
  ];

  # System identification
  networking.hostName = "$HOSTNAME";
  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "$LOCALE";
  console.keyMap = "$KEYBOARD_LAYOUT";

  # User configuration
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "Primary user";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
$([ "$ENABLE_SECRETS" = "yes" ] && echo '    hashedPasswordFile = config.age.secrets."user-password".path;')
$([ "$ENABLE_SECRETS" != "yes" ] && echo "    # Set password with: passwd $USERNAME")
  };

$(
    [ "$ENABLE_SECRETS" = "yes" ] && cat <<'SECRETS'
  users.users.root = {
    hashedPasswordFile = config.age.secrets."root-password".path;
  };
SECRETS
  )

$(
    [ "$VM_TYPE" != "physical" ] && cat <<VMCONFIG
  # VM guest optimizations
  modules.virtualization.vm-guest = {
    enable = true;
    type = "$VM_TYPE";

    optimizations = {
      performance = true;
      graphics = $([ "$DESKTOP_ENVIRONMENT" != "None (Server)" ] && echo "true" || echo "false");
      networking = true;
      storage = true;
    };

    guestTools = {
      enable = true;
      clipboard = $([ "$DESKTOP_ENVIRONMENT" != "None (Server)" ] && echo "true" || echo "false");
      folderSharing = true;
      timeSync = true;
    };
  };
VMCONFIG
  )

$(
    [ "$DESKTOP_ENVIRONMENT" != "None (Server)" ] && cat <<DESKTOP
  # Desktop environment
  modules.desktop = {
    enable = true;
    environment = "$(echo "$DESKTOP_ENVIRONMENT" | tr '[:upper:]' '[:lower:]')";

    audio.enable = true;
    printing.enable = $([ "$VM_TYPE" = "physical" ] && echo "true" || echo "false");
  };
DESKTOP
  )

$(
    [ "$ENABLE_SSH" = "yes" ] && cat <<SSH
  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = $([ "$ENABLE_SECRETS" = "yes" ] && echo "false" || echo "true");
      PermitRootLogin = "no";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
SSH
  )

$(
    [ "$ENABLE_DEVELOPMENT" != "no" ] && cat <<DEV
  # Development tools
  modules.development = {
    enable = true;
$(
      [ "$ENABLE_DEVELOPMENT" = "Full (Multiple languages, LSPs)" ] && cat <<'FULLDEV'
    languages = [ "nix" "rust" "go" "python" "javascript" "typescript" ];
    editors = {
      vscode.enable = true;
      vim.enable = true;
    };
    git = {
      enable = true;
      userName = "Change Me";
      userEmail = "change@example.com";
    };
FULLDEV
    )
$(
      [ "$ENABLE_DEVELOPMENT" = "Basic (Git, editors)" ] && cat <<'BASICDEV'
    languages = [ "nix" ];
    git = {
      enable = true;
      userName = "Change Me";
      userEmail = "change@example.com";
    };
BASICDEV
    )
  };
DEV
  )

$(
    [ "$ENABLE_GAMING" = "yes" ] && cat <<GAMING
  # Gaming support
  modules.gaming.steam = {
    enable = true;
    performance = {
      gamemode = true;
      mangohud = true;
      optimizations = true;
    };
    compattools.proton-ge = true;
  };
GAMING
  )

$(
    [ "$ENABLE_VIRTUALIZATION" = "yes" ] && cat <<VIRT
  # Virtualization support
  modules.virtualization = {
    libvirt.enable = true;
    podman.enable = true;
    virt-manager.enable = true;
  };
VIRT
  )

$(
    [ "$ENABLE_SECRETS" = "yes" ] && cat <<SECRETS
  # Secrets management
  modules.security.agenix = {
    enable = true;
    secrets = {
      "user-password" = {
        file = ../../secrets/user-password.age;
      };
      "root-password" = {
        file = ../../secrets/root-password.age;
      };
    };
  };
SECRETS
  )

  # Home Manager integration
  home-manager.users.$USERNAME = import ./home.nix;

  # Firewall
  networking.firewall.enable = true;

  # System state version
  system.stateVersion = "25.05";
}
EOF

  # Generate home configuration based on user template
  generate_home_config "$host_dir/home.nix"

  # Generate secrets configuration if enabled
  if [ "$ENABLE_SECRETS" = "yes" ]; then
    generate_secrets_config "$host_dir/secrets.nix"
  fi

  print_success "Configuration files generated"
  echo
}

generate_home_config() {
  local home_file="$1"

  print_progress "Generating Home Manager configuration"

  # Map user template to actual template file
  local template_file
  case "$USER_TEMPLATE" in
  "Basic user") template_file="user.nix" ;;
  "Developer") template_file="developer.nix" ;;
  "Gamer") template_file="gamer.nix" ;;
  "Minimal") template_file="minimal.nix" ;;
  "Server admin") template_file="server.nix" ;;
  *) template_file="user.nix" ;;
  esac

  if [ -f "$TEMPLATE_ROOT/home/users/$template_file" ]; then
    cp "$TEMPLATE_ROOT/home/users/$template_file" "$home_file"
    print_success "Home configuration generated from template: $template_file"
  else
    # Generate basic home config if template not found
    cat >"$home_file" <<EOF
{ config, pkgs, lib, ... }:

{
  # Home packages
  home.packages = with pkgs; [
    firefox
    vim
    git
    htop
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Change Me";
    userEmail = "change@example.com";
  };

  # Shell configuration
  programs.bash.enable = true;

  # Home Manager state version
  home.stateVersion = "25.05";
}
EOF
    print_warning "Used fallback home configuration"
  fi
}

generate_secrets_config() {
  local secrets_file="$1"

  print_progress "Generating secrets configuration"

  cat >"$secrets_file" <<EOF
# Host-specific secrets configuration
{ config, ... }:

{
  # Enable agenix secrets management
  modules.security.agenix = {
    enable = true;

    secrets = {
      # User password
      "user-password" = {
        file = ../../secrets/user-password.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # Root password
      "root-password" = {
        file = ../../secrets/root-password.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
$(
    [ "$ENABLE_SSH" = "yes" ] && cat <<'SSHSECRETS'

      # SSH host key
      "ssh-host-key" = {
        file = ../../secrets/ssh-host-key.age;
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/etc/ssh/ssh_host_ed25519_key";
      };
SSHSECRETS
  )
    };
  };
}
EOF
}

# Configuration validation
validate_configuration() {
  print_step "Validating generated configuration"

  local host_dir="$TEMPLATE_ROOT/hosts/$HOSTNAME"
  local validation_errors=()

  # Check if configuration files exist
  local required_files=("configuration.nix" "hardware-configuration.nix" "home.nix")
  for file in "${required_files[@]}"; do
    if [ -f "$host_dir/$file" ]; then
      print_success "$file exists"
    else
      validation_errors+=("Missing file: $file")
    fi
  done

  # Validate Nix syntax
  print_progress "Checking Nix syntax"
  if cd "$TEMPLATE_ROOT" && nix-instantiate --parse "$host_dir/configuration.nix" >/dev/null 2>&1; then
    print_success "configuration.nix syntax valid"
  else
    validation_errors+=("configuration.nix has syntax errors")
  fi

  if nix-instantiate --parse "$host_dir/home.nix" >/dev/null 2>&1; then
    print_success "home.nix syntax valid"
  else
    validation_errors+=("home.nix has syntax errors")
  fi

  # Try to evaluate the flake
  print_progress "Testing flake evaluation"
  if nix flake check --no-build "$TEMPLATE_ROOT" 2>/dev/null; then
    print_success "Flake evaluation successful"
  else
    print_warning "Flake evaluation failed (this may be expected during setup)"
  fi

  # Report validation results
  if [ ${#validation_errors[@]} -gt 0 ]; then
    print_error "Configuration validation failed:"
    for error in "${validation_errors[@]}"; do
      print_error "  - $error"
    done
    return 1
  else
    print_success "Configuration validation passed"
    return 0
  fi
}

# Setup secrets if enabled
setup_secrets() {
  if [ "$ENABLE_SECRETS" != "yes" ]; then
    return 0
  fi

  print_step "Setting up secrets management"

  if [ -x "$SCRIPT_DIR/setup-agenix.sh" ]; then
    print_progress "Running agenix setup"
    "$SCRIPT_DIR/setup-agenix.sh"

    print_progress "Creating password secrets"
    # Hash passwords and create secrets
    local user_hash
    local root_hash
    user_hash=$(echo -n "$USER_PASSWORD" | mkpasswd -m sha-512 -s)
    root_hash=$(echo -n "$ROOT_PASSWORD" | mkpasswd -m sha-512 -s)

    # Store hashed passwords in temporary files
    echo "$user_hash" | agenix -e user-password.age 2>/dev/null || print_warning "Failed to create user password secret"
    echo "$root_hash" | agenix -e root-password.age 2>/dev/null || print_warning "Failed to create root password secret"

    print_success "Secrets management configured"
  else
    print_warning "Agenix setup script not found, skipping secrets setup"
  fi
}

# Main deployment function
deploy_system() {
  print_step "Deploying NixOS configuration"

  echo -e "${YELLOW}This will rebuild your NixOS system with the new configuration.${NC}"
  echo -e "${YELLOW}The process may take several minutes.${NC}"
  echo

  if [ "$(prompt_yes_no "Proceed with deployment?" "y")" = "no" ]; then
    print_info "Deployment cancelled by user"
    return 1
  fi

  # Dry run first
  print_progress "Performing dry run"
  if nixos-rebuild dry-run --flake "$TEMPLATE_ROOT#$HOSTNAME"; then
    print_success "Dry run completed successfully"
  else
    print_error "Dry run failed"
    if [ "$(prompt_yes_no "Continue anyway?" "n")" = "no" ]; then
      return 1
    fi
  fi

  # Test build
  print_progress "Testing configuration build"
  if sudo nixos-rebuild test --flake "$TEMPLATE_ROOT#$HOSTNAME"; then
    print_success "Test build successful"
  else
    print_error "Test build failed"
    return 1
  fi

  # Final deployment choice
  local deploy_choice
  deploy_choice=$(prompt_choice "Choose deployment method:" "Switch (activate immediately)" "Boot (activate on next boot)" "Cancel")

  case "$deploy_choice" in
  "Switch (activate immediately)")
    print_progress "Switching to new configuration"
    if sudo nixos-rebuild switch --flake "$TEMPLATE_ROOT#$HOSTNAME"; then
      print_success "System successfully switched to new configuration"
    else
      print_error "Failed to switch to new configuration"
      return 1
    fi
    ;;
  "Boot (activate on next boot)")
    print_progress "Setting up configuration for next boot"
    if sudo nixos-rebuild boot --flake "$TEMPLATE_ROOT#$HOSTNAME"; then
      print_success "Configuration will be active on next boot"
    else
      print_error "Failed to set boot configuration"
      return 1
    fi
    ;;
  "Cancel")
    print_info "Deployment cancelled"
    return 1
    ;;
  esac

  return 0
}

# Post-deployment tasks
post_deployment() {
  print_step "Post-deployment configuration"

  # Set passwords if secrets not enabled
  if [ "$ENABLE_SECRETS" != "yes" ]; then
    print_progress "Setting up user passwords"
    echo -e "${YELLOW}Please set the password for user '$USERNAME':${NC}"
    sudo passwd "$USERNAME"

    echo -e "${YELLOW}Please set the root password:${NC}"
    sudo passwd root
  fi

  # Enable and start services
  if [ "$ENABLE_SSH" = "yes" ]; then
    print_progress "Enabling SSH service"
    sudo systemctl enable --now sshd
  fi

  # Update Home Manager if needed
  if command -v home-manager >/dev/null 2>&1; then
    print_progress "Updating Home Manager configuration"
    sudo -u "$USERNAME" home-manager switch --flake "$TEMPLATE_ROOT#$USERNAME@$HOSTNAME" || print_warning "Home Manager update failed"
  fi

  print_success "Post-deployment tasks completed"
}

# Final setup summary
show_summary() {
  print_step "Setup Summary"

  echo -e "${GREEN}${BOLD}NixOS Template Setup Complete!${NC}"
  echo
  echo -e "${WHITE}System Configuration:${NC}"
  echo "  Hostname: $HOSTNAME"
  echo "  Username: $USERNAME"
  echo "  Timezone: $TIMEZONE"
  echo "  Locale: $LOCALE"
  echo "  Keyboard: $KEYBOARD_LAYOUT"
  echo "  VM Type: $VM_TYPE"
  echo
  echo -e "${WHITE}Enabled Features:${NC}"
  echo "  Desktop Environment: $DESKTOP_ENVIRONMENT"
  echo "  SSH Server: $ENABLE_SSH"
  echo "  Development Tools: $ENABLE_DEVELOPMENT"
  echo "  Gaming Support: $ENABLE_GAMING"
  echo "  Virtualization: $ENABLE_VIRTUALIZATION"
  echo "  Secrets Management: $ENABLE_SECRETS"
  echo "  User Template: $USER_TEMPLATE"
  echo
  echo -e "${WHITE}Next Steps:${NC}"
  echo "  1. Reboot to ensure all changes are active"
  echo "  2. Configure your applications and preferences"
  echo "  3. Set up additional users if needed"
  echo "  4. Review and customize the configuration files in hosts/$HOSTNAME/"
  echo
  echo -e "${WHITE}Useful Commands:${NC}"
  echo "  just switch $HOSTNAME          - Apply configuration changes"
  echo "  just test $HOSTNAME           - Test configuration changes"
  echo "  just update                   - Update system packages"
  echo "  just list-generations         - Show system generations"
  echo
  if [ "$ENABLE_SECRETS" = "yes" ]; then
    echo -e "${WHITE}Secrets Management:${NC}"
    echo "  just setup-secrets            - Re-run secrets setup"
    echo "  just edit-secret <name>       - Edit a secret"
    echo "  just list-secrets             - List available secrets"
    echo
  fi
  echo -e "${GREEN}Enjoy your new NixOS system!${NC}"
}

# Cleanup and error handling
cleanup() {
  # Remove temporary files
  if [ -f "$TEMPLATE_ROOT/.setup-temp" ]; then
    rm -f "$TEMPLATE_ROOT/.setup-temp"
  fi

  # Clear sensitive variables
  USER_PASSWORD=""
  ROOT_PASSWORD=""
}

error_handler() {
  local exit_code=$?
  print_error "Setup failed with exit code $exit_code"
  print_info "Check $LOG_FILE for detailed logs"
  cleanup
  exit $exit_code
}

# Main setup workflow
main() {
  # Initialize logging
  echo "NixOS Template Setup - $(date)" >"$LOG_FILE"

  # Set up error handling
  trap error_handler ERR
  trap cleanup EXIT

  # Welcome message
  print_header
  echo -e "${WHITE}Welcome to the NixOS Template Setup Wizard!${NC}"
  echo -e "${BLUE}This script will help you configure a complete NixOS system.${NC}"
  echo

  # Check for resume
  if load_state; then
    echo -e "${YELLOW}Previous setup state found.${NC}"
    if [ "$(prompt_yes_no "Resume previous setup?" "y")" = "yes" ]; then
      print_info "Resuming setup from saved state"
    else
      # Clear state and start fresh
      rm -f "$SETUP_STATE_FILE"
      print_info "Starting fresh setup"
    fi
  fi

  # Run setup phases
  check_prerequisites
  detect_hardware

  # Skip user input if resuming with complete state
  if [ -z "$HOSTNAME" ] || [ -z "$USERNAME" ]; then
    collect_user_config
  fi

  if [ -z "$DESKTOP_ENVIRONMENT" ]; then
    select_features
  fi

  generate_configuration

  if ! validate_configuration; then
    print_error "Configuration validation failed. Please check the errors above."
    exit 1
  fi

  setup_secrets

  if deploy_system; then
    post_deployment
    show_summary

    # Remove setup state file on successful completion
    rm -f "$SETUP_STATE_FILE"

    print_success "Setup completed successfully!"
  else
    print_error "Deployment failed. Configuration files have been created but not applied."
    print_info "You can manually apply the configuration later with:"
    print_info "  sudo nixos-rebuild switch --flake .#$HOSTNAME"
    exit 1
  fi
}

# Check if script is being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
