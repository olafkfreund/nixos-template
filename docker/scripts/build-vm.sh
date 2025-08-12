#!/usr/bin/env bash
# NixOS VM Builder Script
# Builds NixOS VM images for multiple virtualization platforms

set -euo pipefail

# Default configuration
DEFAULT_FORMAT="virtualbox"
DEFAULT_CONFIG="/templates/desktop-template.nix"
DEFAULT_OUTPUT_DIR="/workspace/output"
DEFAULT_DISK_SIZE="20480"  # 20GB in MB
DEFAULT_MEMORY_SIZE="4096" # 4GB in MB

# Color output
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

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
  cat <<EOF
NixOS VM Builder - Build NixOS VMs for Windows users

USAGE:
    build-vm.sh [FORMAT] [OPTIONS]

FORMATS:
    virtualbox      Build VirtualBox OVA image (default)
    hyperv          Build Hyper-V VHDX image
    vmware          Build VMware VMDK image
    qemu            Build QEMU QCOW2 image
    proxmox         Build Proxmox VMA image
    all             Build all supported formats

OPTIONS:
    -c, --config FILE       Path to NixOS configuration file
    -o, --output DIR        Output directory (default: /workspace/output)
    -s, --disk-size SIZE    Disk size in MB (default: 20480)
    -m, --memory SIZE       Memory size in MB (default: 4096)
    -n, --vm-name NAME      VM name (default: nixos-TIMESTAMP)
    -t, --template NAME     Use predefined template (desktop, server, gaming, minimal)
    -h, --help              Show this help message
    --list-templates        List available templates
    --validate-only         Only validate configuration, don't build

EXAMPLES:
    # Build VirtualBox VM with default configuration
    build-vm.sh virtualbox

    # Build Hyper-V VM with custom config
    build-vm.sh hyperv -c /workspace/my-config.nix

    # Build all formats with custom disk size
    build-vm.sh all -s 40960

    # Use predefined gaming template for VMware
    build-vm.sh vmware -t gaming

TEMPLATES:
    desktop         Full desktop environment with GUI apps
    server          Headless server configuration
    gaming          Gaming-optimized system with Steam
    minimal         Minimal system with basic tools
    development     Development environment with tools

For Windows users:
    docker run -v "\${PWD}:/workspace" nixos-vm-builder:latest [FORMAT] [OPTIONS]
EOF
}

# List available templates
list_templates() {
  log_info "Available templates:"
  echo "  desktop     - Full desktop environment (KDE/GNOME)"
  echo "  server      - Headless server configuration"
  echo "  gaming      - Gaming system with Steam and drivers"
  echo "  minimal     - Minimal NixOS installation"
  echo "  development - Development environment with programming tools"
  echo ""
  echo "Template files are located in /templates/"
}

# Validate format
validate_format() {
  local format="$1"
  case "$format" in
  virtualbox | hyperv | vmware | qemu | proxmox | all)
    return 0
    ;;
  *)
    log_error "Unsupported format: $format"
    log_info "Supported formats: virtualbox, hyperv, vmware, qemu, proxmox, all"
    return 1
    ;;
  esac
}

# Get template path
get_template_path() {
  local template="$1"
  case "$template" in
  desktop)
    echo "/templates/desktop-template.nix"
    ;;
  server)
    echo "/templates/server-template.nix"
    ;;
  gaming)
    echo "/templates/gaming-template.nix"
    ;;
  minimal)
    echo "/templates/minimal-template.nix"
    ;;
  development)
    echo "/templates/development-template.nix"
    ;;
  *)
    log_error "Unknown template: $template"
    list_templates
    return 1
    ;;
  esac
}

# Validate configuration file
validate_config() {
  local config_file="$1"

  if [[ ! -f $config_file ]]; then
    log_error "Configuration file not found: $config_file"
    return 1
  fi

  log_info "Validating configuration: $config_file"

  # Use nix-instantiate to validate the configuration
  if ! nix-instantiate --parse "$config_file" >/dev/null 2>&1; then
    log_error "Invalid NixOS configuration syntax"
    return 1
  fi

  log_success "Configuration validated successfully"
  return 0
}

# Build VM image
build_vm() {
  local format="$1"
  local config="$2"
  local output_dir="$3"
  local disk_size="$4"
  local memory_size="$5"
  local vm_name="$6"

  log_info "Building NixOS VM:"
  log_info "  Format: $format"
  log_info "  Config: $config"
  log_info "  Output: $output_dir"
  log_info "  Disk Size: ${disk_size}MB"
  log_info "  Memory: ${memory_size}MB"
  log_info "  VM Name: $vm_name"

  # Create output directory
  mkdir -p "$output_dir"

  # Build the VM image
  log_info "Starting nixos-generate build..."

  local build_start
  build_start=$(date +%s)

  if ! nixos-generate \
    --format "$format" \
    --configuration "$config" \
    --out-link "$output_dir/nixos-$vm_name-$format" \
    --option diskSize "$disk_size" \
    --option memorySize "$memory_size" \
    --show-trace; then
    log_error "Failed to build $format VM"
    return 1
  fi

  local build_end
  build_end=$(date +%s)
  local build_time=$((build_end - build_start))

  log_success "VM build completed in ${build_time} seconds"

  # Create info file
  create_vm_info "$format" "$output_dir" "$vm_name" "$disk_size" "$memory_size" "$build_time"

  return 0
}

# Create VM info file
create_vm_info() {
  local format="$1"
  local output_dir="$2"
  local vm_name="$3"
  local disk_size="$4"
  local memory_size="$5"
  local build_time="$6"

  local info_file="$output_dir/nixos-$vm_name-$format.json"

  cat >"$info_file" <<EOF
{
  "vm_name": "$vm_name",
  "format": "$format",
  "disk_size_mb": $disk_size,
  "memory_size_mb": $memory_size,
  "build_time_seconds": $build_time,
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "nixos_version": "$(nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version' | tr -d '\"')",
  "builder_version": "1.0.0",
  "instructions": {
    "virtualbox": "Import the .ova file using File -> Import Appliance in VirtualBox",
    "hyperv": "Create new VM in Hyper-V Manager and use the .vhdx file as the virtual hard disk",
    "vmware": "Create new VM in VMware and use the .vmdk file as the virtual disk",
    "qemu": "Run with: qemu-system-x86_64 -m ${memory_size} -hda nixos-$vm_name-$format.qcow2",
    "proxmox": "Upload and restore the .vma file in Proxmox VE"
  }
}
EOF

  log_success "VM info saved to: $info_file"
}

# Build all formats
build_all_formats() {
  local config="$1"
  local output_dir="$2"
  local disk_size="$3"
  local memory_size="$4"
  local vm_name="$5"

  local formats=("virtualbox" "hyperv" "vmware" "qemu")
  local failed_builds=()

  log_info "Building all VM formats..."

  for format in "${formats[@]}"; do
    log_info "Building $format format..."
    if ! build_vm "$format" "$config" "$output_dir" "$disk_size" "$memory_size" "$vm_name"; then
      log_warn "Failed to build $format format"
      failed_builds+=("$format")
    fi
  done

  if [[ ${#failed_builds[@]} -eq 0 ]]; then
    log_success "All VM formats built successfully!"
  else
    log_warn "Some builds failed: ${failed_builds[*]}"
    return 1
  fi
}

# Main function
main() {
  # Parse command line arguments
  local format="$DEFAULT_FORMAT"
  local config="$DEFAULT_CONFIG"
  local output_dir="$DEFAULT_OUTPUT_DIR"
  local disk_size="$DEFAULT_DISK_SIZE"
  local memory_size="$DEFAULT_MEMORY_SIZE"
  local vm_name
  vm_name="nixos-$(date +%Y%m%d-%H%M%S)"
  local template=""
  local validate_only=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      show_help
      exit 0
      ;;
    --list-templates)
      list_templates
      exit 0
      ;;
    -c | --config)
      config="$2"
      shift 2
      ;;
    -o | --output)
      output_dir="$2"
      shift 2
      ;;
    -s | --disk-size)
      disk_size="$2"
      shift 2
      ;;
    -m | --memory)
      memory_size="$2"
      shift 2
      ;;
    -n | --vm-name)
      vm_name="$2"
      shift 2
      ;;
    -t | --template)
      template="$2"
      shift 2
      ;;
    --validate-only)
      validate_only=true
      shift
      ;;
    virtualbox | hyperv | vmware | qemu | proxmox | all)
      format="$1"
      shift
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done

  # Use template if specified
  if [[ -n $template ]]; then
    if ! config=$(get_template_path "$template"); then
      exit 1
    fi
  fi

  # Validate inputs
  if [[ $format != "all" ]] && ! validate_format "$format"; then
    exit 1
  fi

  if ! validate_config "$config"; then
    exit 1
  fi

  if [[ $validate_only == true ]]; then
    log_success "Configuration validation completed"
    exit 0
  fi

  # Build VM(s)
  log_info "Starting NixOS VM build process..."

  if [[ $format == "all" ]]; then
    build_all_formats "$config" "$output_dir" "$disk_size" "$memory_size" "$vm_name"
  else
    build_vm "$format" "$config" "$output_dir" "$disk_size" "$memory_size" "$vm_name"
  fi

  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_success "Build process completed successfully!"
    log_info "Output files are available in: $output_dir"

    # List generated files
    log_info "Generated files:"
    find "$output_dir" -name "nixos-$vm_name-*" -type f -o -type l | while read -r file; do
      echo "  - $(basename "$file")"
    done
  else
    log_error "Build process failed!"
  fi

  exit $exit_code
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
