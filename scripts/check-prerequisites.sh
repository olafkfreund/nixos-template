#!/usr/bin/env bash

# Prerequisites checking script for NixOS Template Setup
# Comprehensive system validation before setup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"
INFO="ℹ"

print_info() {
  echo -e "${BLUE}${INFO}${NC} $1"
}

print_success() {
  echo -e "${GREEN}${CHECK}${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}${WARN}${NC} $1"
}

print_error() {
  echo -e "${RED}${CROSS}${NC} $1"
}

check_nixos() {
  echo "Checking NixOS environment..."

  # Check if we're on NixOS
  if [ ! -f /etc/NIXOS ]; then
    print_error "This script must be run on NixOS"
    return 1
  fi
  print_success "Running on NixOS"

  # Check NixOS version
  if [ -f /etc/os-release ]; then
    local nixos_version
    nixos_version=$(grep '^VERSION=' /etc/os-release | cut -d'"' -f2 || echo "Unknown")
    print_info "NixOS version: $nixos_version"

    # Parse version number for compatibility check
    local version_number
    version_number=$(echo "$nixos_version" | grep -o '[0-9][0-9]\.[0-9][0-9]' | head -1 || echo "")
    if [ -n "$version_number" ]; then
      local major minor
      major=$(echo "$version_number" | cut -d'.' -f1)
      minor=$(echo "$version_number" | cut -d'.' -f2)

      if [ "$major" -gt 23 ] || { [ "$major" -eq 23 ] && [ "$minor" -ge 11 ]; }; then
        print_success "NixOS version is compatible"
      else
        print_warning "NixOS version might be too old (23.11+ recommended)"
      fi
    fi
  fi

  return 0
}

check_privileges() {
  echo "Checking user privileges..."

  # Check if running as root
  if [ "$EUID" -eq 0 ]; then
    print_success "Running as root"
    return 0
  fi

  # Check sudo access
  if sudo -n true 2>/dev/null; then
    print_success "Sudo access available (passwordless)"
  elif sudo -v 2>/dev/null; then
    print_success "Sudo access available"
  else
    print_error "Root or sudo access required"
    print_info "Please run: sudo $0"
    return 1
  fi

  return 0
}

check_nix_tools() {
  echo "Checking Nix tools..."

  local missing_tools=()
  local optional_tools=()

  # Essential Nix tools
  local required_tools=("nix" "nixos-rebuild" "nixos-generate-config" "nix-instantiate")
  for tool in "${required_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      print_success "$tool found"
    else
      missing_tools+=("$tool")
      print_error "$tool not found"
    fi
  done

  # Check Nix version
  if command -v nix >/dev/null 2>&1; then
    local nix_version
    nix_version=$(nix --version 2>/dev/null | head -1 || echo "Unknown")
    print_info "Nix version: $nix_version"

    # Check for flakes support
    if nix flake --help >/dev/null 2>&1; then
      print_success "Nix flakes support available"
    else
      print_error "Nix flakes not available - please enable experimental features"
      missing_tools+=("flakes-support")
    fi
  fi

  # Check Home Manager
  if command -v home-manager >/dev/null 2>&1; then
    print_success "Home Manager found"
    local hm_version
    hm_version=$(home-manager --version 2>/dev/null || echo "Unknown")
    print_info "Home Manager version: $hm_version"
  else
    print_warning "Home Manager not found (will be installed by template)"
  fi

  # Optional but useful tools
  local optional_tools_list=("git" "curl" "wget" "jq" "fd" "ripgrep")
  for tool in "${optional_tools_list[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      print_success "$tool found (optional)"
    else
      optional_tools+=("$tool")
      print_warning "$tool not found (optional but recommended)"
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    return 1
  fi

  return 0
}

check_system_resources() {
  echo "Checking system resources..."

  # Check available memory
  if [ -f /proc/meminfo ]; then
    local total_mem available_mem
    total_mem=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
    available_mem=$(awk '/MemAvailable/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0")

    print_info "Total memory: ${total_mem}GB"
    if [ -n "$available_mem" ] && [ "$available_mem" != "0" ]; then
      print_info "Available memory: ${available_mem}GB"

      if (($(echo "$available_mem > 1.0" | bc -l 2>/dev/null || echo 0))); then
        print_success "Sufficient memory available"
      else
        print_warning "Low available memory: ${available_mem}GB (2GB+ recommended)"
      fi
    else
      if (($(echo "$total_mem > 2.0" | bc -l 2>/dev/null || echo 0))); then
        print_success "Sufficient total memory"
      else
        print_warning "Low total memory: ${total_mem}GB (4GB+ recommended)"
      fi
    fi
  fi

  # Check disk space
  local root_available
  root_available=$(df / | awk 'NR==2 {printf "%.1f", $4/1024/1024}')
  print_info "Available disk space: ${root_available}GB"

  if (($(echo "$root_available > 10.0" | bc -l 2>/dev/null || echo 0))); then
    print_success "Sufficient disk space"
  elif (($(echo "$root_available > 5.0" | bc -l 2>/dev/null || echo 0))); then
    print_warning "Limited disk space: ${root_available}GB (10GB+ recommended)"
  else
    print_error "Insufficient disk space: ${root_available}GB (minimum 5GB required)"
    return 1
  fi

  # Check CPU cores
  local cpu_cores
  cpu_cores=$(nproc 2>/dev/null || echo "1")
  print_info "CPU cores: $cpu_cores"

  if [ "$cpu_cores" -ge 2 ]; then
    print_success "Multi-core CPU available"
  else
    print_warning "Single-core CPU (builds may be slow)"
  fi

  return 0
}

check_network() {
  echo "Checking network connectivity..."

  # Check basic connectivity
  if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    print_success "Basic network connectivity OK"
  else
    print_error "No network connectivity"
    return 1
  fi

  # Check DNS resolution
  if nslookup github.com >/dev/null 2>&1; then
    print_success "DNS resolution working"
  else
    print_warning "DNS resolution issues detected"
  fi

  # Check HTTPS connectivity
  if curl -s --connect-timeout 10 https://github.com >/dev/null 2>&1; then
    print_success "HTTPS connectivity OK"
  else
    print_warning "HTTPS connectivity issues"
  fi

  # Check nixpkgs channels
  if curl -s --connect-timeout 10 https://channels.nixos.org >/dev/null 2>&1; then
    print_success "NixOS channels accessible"
  else
    print_warning "NixOS channels not accessible"
  fi

  return 0
}

check_nix_config() {
  echo "Checking Nix configuration..."

  # Check if flakes are enabled
  local nix_conf="/etc/nix/nix.conf"
  if [ -f "$nix_conf" ]; then
    if grep -q "experimental-features.*flakes" "$nix_conf"; then
      print_success "Nix flakes enabled in system configuration"
    else
      print_warning "Nix flakes not enabled in $nix_conf"
      print_info "The setup script can enable flakes temporarily"
    fi
  else
    print_warning "Nix configuration file not found"
  fi

  # Check user Nix configuration
  local user_nix_conf="$HOME/.config/nix/nix.conf"
  if [ -f "$user_nix_conf" ]; then
    if grep -q "experimental-features.*flakes" "$user_nix_conf"; then
      print_success "Nix flakes enabled in user configuration"
    else
      print_info "User Nix configuration exists but flakes not enabled"
    fi
  fi

  # Check Nix store permissions
  if [ -w /nix/store ]; then
    print_success "Nix store is writable"
  else
    if [ -d /nix/store ]; then
      print_success "Nix store exists (read-only is normal)"
    else
      print_error "Nix store not found"
      return 1
    fi
  fi

  return 0
}

check_hardware_support() {
  echo "Checking hardware support..."

  # Check CPU architecture
  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64)
    print_success "x86_64 architecture (fully supported)"
    ;;
  aarch64)
    print_success "ARM64 architecture (supported)"
    ;;
  i686)
    print_warning "32-bit x86 architecture (limited support)"
    ;;
  *)
    print_warning "Unsupported architecture: $arch"
    ;;
  esac

  # Check for virtualization capabilities
  if [ -f /proc/cpuinfo ]; then
    if grep -q "vmx\|svm" /proc/cpuinfo; then
      print_success "Hardware virtualization supported"
    else
      print_info "Hardware virtualization not detected"
    fi
  fi

  # Check graphics capabilities
  if command -v lspci >/dev/null 2>&1; then
    local gpu_count
    gpu_count=$(lspci | grep -c "VGA\|3D\|Display" || echo "0")
    if [ "$gpu_count" -gt 0 ]; then
      print_success "Graphics hardware detected"
      lspci | grep "VGA\|3D\|Display" | while read -r line; do
        print_info "  $line"
      done
    else
      print_warning "No graphics hardware detected"
    fi
  fi

  # Check storage devices
  if command -v lsblk >/dev/null 2>&1; then
    local disk_count
    disk_count=$(lsblk -d | grep -c disk || echo "0")
    if [ "$disk_count" -gt 0 ]; then
      print_success "Storage devices detected"
      lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk | head -3 | while read -r line; do
        print_info "  $line"
      done
    else
      print_warning "No storage devices detected via lsblk"
    fi
  fi

  return 0
}

check_existing_config() {
  echo "Checking existing system configuration..."

  # Check current NixOS configuration
  if [ -f /etc/nixos/configuration.nix ]; then
    print_info "Existing NixOS configuration found at /etc/nixos/"

    # Check if it's a flake-based system
    if [ -f /etc/nixos/flake.nix ]; then
      print_success "System is already flake-based"
    else
      print_info "System uses traditional configuration.nix"
    fi
  else
    print_warning "No existing NixOS configuration found"
  fi

  # Check for Home Manager
  if [ -d "$HOME/.config/home-manager" ]; then
    print_info "Existing Home Manager configuration found"
  fi

  # Check current system generation
  if command -v nixos-version >/dev/null 2>&1; then
    local nixos_gen
    nixos_gen=$(nixos-version 2>/dev/null || echo "Unknown")
    print_info "Current system generation: $nixos_gen"
  fi

  return 0
}

check_hardware_type() {
  echo "Detecting hardware type and power requirements..."

  local hardware_script="./scripts/detect-hardware.sh"

  # Check if hardware detection script exists
  if [ ! -f "$hardware_script" ]; then
    print_warning "Hardware detection script not found at $hardware_script"
    print_info "Manual hardware type selection will be required during setup"
    return 0
  fi

  # Make script executable if needed
  if [ ! -x "$hardware_script" ]; then
    chmod +x "$hardware_script" 2>/dev/null || true
  fi

  # Run hardware detection
  if [ -x "$hardware_script" ]; then
    print_info "Running hardware detection..."

    # Capture hardware detection output
    local detection_output
    detection_output=$("$hardware_script" detect 2>/dev/null || echo "")

    if [ -n "$detection_output" ]; then
      # Extract key information
      local hardware_type
      local confidence_level
      local has_battery
      local has_wireless

      hardware_type=$(echo "$detection_output" | grep "HARDWARE_TYPE=" | cut -d= -f2 || echo "unknown")
      confidence_level=$(echo "$detection_output" | grep "CONFIDENCE_LEVEL=" | cut -d= -f2 || echo "low")
      has_battery=$(echo "$detection_output" | grep "HAS_BATTERY=" | cut -d= -f2 || echo "false")
      has_wireless=$(echo "$detection_output" | grep "HAS_WIRELESS=" | cut -d= -f2 || echo "false")

      # Report findings
      if [ "$hardware_type" != "unknown" ]; then
        print_success "Hardware type detected: $hardware_type"
        print_info "Detection confidence: $confidence_level"

        # Additional hardware features
        if [ "$has_battery" = "true" ]; then
          print_success "Battery detected - power management will be optimized"
        fi

        if [ "$has_wireless" = "true" ]; then
          print_success "Wireless interface detected - WiFi power saving available"
        fi

        # Provide template recommendations
        case "$hardware_type" in
        laptop)
          print_info "Recommended template: laptop-template"
          print_info "Power profile: Battery optimization with TLP"
          print_info "Desktop environment: GNOME (good power management)"
          ;;
        desktop)
          print_info "Recommended template: desktop-template"
          print_info "Power profile: Performance optimization"
          print_info "Desktop environment: GNOME or KDE"
          ;;
        workstation)
          print_info "Recommended template: desktop-template (workstation variant)"
          print_info "Power profile: Balanced performance"
          print_info "Desktop environment: KDE (professional features)"
          ;;
        server)
          print_info "Recommended template: server-template"
          print_info "Power profile: Reliability and consistent performance"
          print_info "Desktop environment: None (headless)"
          ;;
        *)
          print_info "Recommended template: desktop-template (default)"
          print_info "Power profile: Balanced"
          ;;
        esac
      else
        print_warning "Unable to determine hardware type"
        print_info "Default template (desktop) will be recommended during setup"
      fi
    else
      print_warning "Hardware detection script produced no output"
      print_info "Manual hardware type selection will be required"
    fi
  else
    print_warning "Hardware detection script is not executable"
    print_info "Please check script permissions: $hardware_script"
    return 1
  fi

  return 0
}

generate_summary() {
  echo
  echo "==============================================="
  echo "           Prerequisites Check Summary"
  echo "==============================================="
  echo

  # Count the different types of issues
  local error_count warning_count success_count
  error_count=$(grep -c "${RED}${CROSS}" <<<"$output" 2>/dev/null || echo "0")
  warning_count=$(grep -c "${YELLOW}${WARN}" <<<"$output" 2>/dev/null || echo "0")
  success_count=$(grep -c "${GREEN}${CHECK}" <<<"$output" 2>/dev/null || echo "0")

  echo -e "${GREEN}Successful checks: $success_count${NC}"
  echo -e "${YELLOW}Warnings: $warning_count${NC}"
  echo -e "${RED}Errors: $error_count${NC}"
  echo

  if [ "$error_count" -eq 0 ]; then
    echo -e "${GREEN}${CHECK} System is ready for NixOS template setup${NC}"
    if [ "$warning_count" -gt 0 ]; then
      echo -e "${YELLOW}${WARN} Some warnings were detected - review above${NC}"
    fi
    return 0
  else
    echo -e "${RED}${CROSS} System has critical issues that must be resolved${NC}"
    return 1
  fi
}

fix_common_issues() {
  echo "Attempting to fix common issues..."

  # Enable flakes if needed
  local nix_conf="/etc/nix/nix.conf"
  if ! grep -q "experimental-features.*flakes" "$nix_conf" 2>/dev/null; then
    print_info "Attempting to enable Nix flakes..."
    if [ -w "$nix_conf" ] || sudo test -w "$nix_conf"; then
      echo "experimental-features = nix-command flakes" | sudo tee -a "$nix_conf" >/dev/null
      print_success "Nix flakes enabled (restart nix-daemon for effect)"
    else
      print_warning "Cannot write to $nix_conf - manual intervention required"
    fi
  fi

  # Restart nix-daemon if we're on systemd
  if command -v systemctl >/dev/null 2>&1; then
    if sudo systemctl is-active nix-daemon >/dev/null 2>&1; then
      print_info "Restarting nix-daemon to apply configuration changes..."
      sudo systemctl restart nix-daemon
      print_success "nix-daemon restarted"
    fi
  fi
}

main() {
  echo "NixOS Template Prerequisites Checker"
  echo "===================================="
  echo

  # Capture all output for summary
  {
    local overall_result=0

    check_nixos || overall_result=1
    echo

    check_privileges || overall_result=1
    echo

    check_nix_tools || overall_result=1
    echo

    check_system_resources || overall_result=1
    echo

    check_network || overall_result=1
    echo

    check_nix_config || overall_result=1
    echo

    check_hardware_support || overall_result=1
    echo

    check_existing_config || overall_result=1
    echo

    check_hardware_type || overall_result=1
    echo

    # Attempt automatic fixes for some issues
    fix_common_issues
    echo

    return $overall_result

  } | tee /dev/fd/3 3>&1 | {
    output=$(cat)
    echo "$output"

    generate_summary
    summary_result=$?

    if [ $summary_result -eq 0 ]; then
      echo
      echo -e "${GREEN}Ready to run the NixOS template setup!${NC}"
      echo "Run: ./scripts/nixos-setup.sh"
    else
      echo
      echo -e "${RED}Please resolve the issues above before running setup.${NC}"
    fi

    exit $summary_result
  }
}

# Check if script is being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
