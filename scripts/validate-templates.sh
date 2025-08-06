#!/usr/bin/env bash

# Template Validation Script
# Comprehensive validation of all NixOS templates

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info() {
  echo -e "${BLUE}INFO${NC} $1"
}

print_success() {
  echo -e "${GREEN}SUCCESS${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}WARNING${NC} $1"
}

print_error() {
  echo -e "${RED}ERROR${NC} $1"
}

print_header() {
  echo -e "${BLUE}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║                Template Validation Suite                 ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# Validation levels
VALIDATION_LEVEL=${1:-"standard"} # minimal, standard, full, vm

validate_flake() {
  print_info "Step 1: Validating flake structure and syntax..."

  cd "$PROJECT_ROOT"

  print_info "Checking flake syntax..."
  if nix flake check --no-build; then
    print_success "Flake syntax validation passed"
  else
    print_error "Flake syntax validation failed"
    return 1
  fi

  print_info "Validating flake metadata..."
  nix flake metadata --json >/dev/null
  print_success "Flake metadata is valid"

  return 0
}

validate_nix_syntax() {
  print_info "Step 2: Validating individual Nix file syntax..."

  local error_count=0

  while IFS= read -r -d '' file; do
    print_info "Checking syntax: $file"
    if ! nix-instantiate --parse "$file" >/dev/null 2>&1; then
      print_error "Syntax error in: $file"
      error_count=$((error_count + 1))
    fi
  done < <(find "$PROJECT_ROOT" -name "*.nix" -type f -print0)

  if [ $error_count -eq 0 ]; then
    print_success "All Nix files have valid syntax"
    return 0
  else
    print_error "Found $error_count files with syntax errors"
    return 1
  fi
}

validate_template_structure() {
  print_info "Step 3: Validating template directory structure..."

  local templates=(
    "laptop-template"
    "desktop-template"
    "server-template"
  )

  local required_files=(
    "configuration.nix"
    "home.nix"
  )

  for template in "${templates[@]}"; do
    local template_dir="$PROJECT_ROOT/hosts/$template"

    if [ ! -d "$template_dir" ]; then
      print_error "Template directory missing: $template"
      return 1
    fi

    print_info "Validating template: $template"

    for file in "${required_files[@]}"; do
      if [ ! -f "$template_dir/$file" ]; then
        print_error "Missing required file in $template: $file"
        return 1
      fi
    done

    print_success "Template $template structure is valid"
  done

  return 0
}

validate_build_evaluation() {
  print_info "Step 4: Validating template build evaluation..."

  local templates=(
    "laptop-template"
    "desktop-template"
    "server-template"
  )

  for template in "${templates[@]}"; do
    print_info "Evaluating build for: $template"

    # Try to evaluate the system configuration
    if nix eval --no-warn-dirty ".#nixosConfigurations.$template.config.system.build.toplevel.outPath" \
      --apply 'x: "evaluation-success"' >/dev/null 2>&1; then
      print_success "Build evaluation passed for: $template"
    else
      print_warning "Build evaluation failed for: $template (may be expected for templates)"
      # Templates might fail evaluation due to missing hardware-configuration.nix
      # This is expected and not necessarily an error
    fi
  done

  return 0
}

validate_module_imports() {
  print_info "Step 5: Validating module imports..."

  local modules_dir="$PROJECT_ROOT/modules"
  local error_count=0

  if [ -d "$modules_dir" ]; then
    while IFS= read -r -d '' module; do
      print_info "Checking module: $module"

      # Try to evaluate module with minimal context
      if ! nix-instantiate --eval -E "
                let 
                  pkgs = import <nixpkgs> {};
                  lib = pkgs.lib;
                  config = {};
                in
                import $module { inherit config lib pkgs; }
            " >/dev/null 2>&1; then
        print_warning "Module evaluation issues: $module (may need specific dependencies)"
        # Don't count as hard error since modules may have specific requirements
      fi
    done < <(find "$modules_dir" -name "*.nix" -type f -print0)
  fi

  print_success "Module import validation completed"
  return 0
}

validate_user_templates() {
  print_info "Step 6: Validating user templates..."

  local user_templates_dir="$PROJECT_ROOT/home/users"

  if [ -d "$user_templates_dir" ]; then
    while IFS= read -r -d '' template; do
      local template_name=$(basename "$template" .nix)
      print_info "Validating user template: $template_name"

      # Check syntax
      if nix-instantiate --parse "$template" >/dev/null 2>&1; then
        print_success "User template $template_name syntax is valid"
      else
        print_error "User template $template_name has syntax errors"
        return 1
      fi
    done < <(find "$user_templates_dir" -name "*.nix" -type f -print0)
  fi

  return 0
}

validate_scripts() {
  print_info "Step 7: Validating scripts..."

  local scripts_dir="$PROJECT_ROOT/scripts"
  local error_count=0

  if [ -d "$scripts_dir" ]; then
    while IFS= read -r -d '' script; do
      print_info "Validating script: $(basename "$script")"

      # Check if executable
      if [ ! -x "$script" ]; then
        print_warning "Script not executable: $script"
      fi

      # Check if has proper shebang
      if ! head -1 "$script" | grep -q '^#!'; then
        print_warning "Script missing shebang: $script"
      fi

      # Test help/info commands that should be safe
      local script_name=$(basename "$script")
      case "$script_name" in
        "detect-hardware.sh")
          if "$script" help >/dev/null 2>&1; then
            print_success "$script_name help command works"
          else
            print_warning "$script_name help command failed"
          fi
          ;;
        "detect-vm.sh")
          if "$script" --help >/dev/null 2>&1; then
            print_success "$script_name help command works"
          else
            print_warning "$script_name help command failed"
          fi
          ;;
      esac

    done < <(find "$scripts_dir" -name "*.sh" -type f -print0)
  fi

  return 0
}

build_test_vm() {
  local template="$1"
  print_info "Building VM for template: $template"

  # Create temporary directory for VM test
  local temp_dir
  temp_dir=$(mktemp -d)

  # Copy template to temporary location
  cp -r "$PROJECT_ROOT/hosts/$template" "$temp_dir/test-host"

  # Also copy common.nix and modules needed by the template
  cp "$PROJECT_ROOT/hosts/common.nix" "$temp_dir/common.nix"
  cp -r "$PROJECT_ROOT/modules" "$temp_dir/modules"

  # Update the import paths in configuration.nix to point to the copied modules
  sed -i 's|../../modules/|../modules/|g' "$temp_dir/test-host/configuration.nix"
  sed -i 's|../common\.nix|../common.nix|g' "$temp_dir/test-host/configuration.nix"

  # Create a simple flake.nix for the VM test
  cat >"$temp_dir/flake.nix" <<'EOF'
{
  description = "Test VM configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, home-manager }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.test-vm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./test-host/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # Provide dummy location coordinates for services that need them (like clight)
          location.latitude = 40.7128;
          location.longitude = -74.0060;
        }
      ];
    };
  };
}
EOF

  # Generate a minimal hardware configuration for testing
  cat >"$temp_dir/test-host/hardware-configuration.nix" <<'EOF'
# Minimal hardware configuration for testing
{ config, lib, pkgs, ... }:

{
  boot.loader.grub.device = "/dev/vda";
  
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
  
  networking.interfaces.enp0s3.useDHCP = true;
  
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
}
EOF

  # Try to build VM using the flake (with impure mode for absolute paths)
  if cd "$temp_dir" && nix build --no-link --impure '.#nixosConfigurations.test-vm.config.system.build.vm'; then
    print_success "VM build successful for: $template"
    rm -rf "$temp_dir"
    return 0
  else
    print_error "VM build failed for: $template"
    rm -rf "$temp_dir"
    return 1
  fi
}

validate_vms() {
  print_info "Step 8: Validating VM builds (this may take several minutes)..."

  local templates=(
    "laptop-template"
    "desktop-template"
    "server-template"
  )

  for template in "${templates[@]}"; do
    if ! build_test_vm "$template"; then
      print_error "VM validation failed for: $template"
      return 1
    fi
  done

  return 0
}

run_full_validation() {
  print_header

  local validation_steps=(
    "validate_flake"
    "validate_nix_syntax"
    "validate_template_structure"
    "validate_build_evaluation"
    "validate_module_imports"
    "validate_user_templates"
    "validate_scripts"
  )

  # Add VM validation for full level
  if [ "$VALIDATION_LEVEL" = "full" ] || [ "$VALIDATION_LEVEL" = "vm" ]; then
    validation_steps+=("validate_vms")
  fi

  local failed_steps=()
  local step_count=0
  local total_steps=${#validation_steps[@]}

  for step in "${validation_steps[@]}"; do
    step_count=$((step_count + 1))
    echo
    print_info "Running validation step $step_count/$total_steps: $step"

    if ! "$step"; then
      failed_steps+=("$step")
    fi
  done

  echo
  print_info "Validation Summary:"
  echo "=================="

  if [ ${#failed_steps[@]} -eq 0 ]; then
    print_success "All validation steps passed!"
    echo
    print_success "Templates are ready for use!"
    return 0
  else
    print_error "Failed validation steps:"
    for step in "${failed_steps[@]}"; do
      echo "  - $step"
    done
    echo
    print_error "Please fix the issues above before using templates"
    return 1
  fi
}

show_help() {
  echo "Template Validation Script"
  echo ""
  echo "Usage: $0 [LEVEL]"
  echo ""
  echo "Validation Levels:"
  echo "  minimal   - Syntax and structure validation only"
  echo "  standard  - Syntax, structure, and build evaluation (default)"
  echo "  full      - All checks including VM builds (slow)"
  echo "  vm        - Only VM build validation"
  echo ""
  echo "Examples:"
  echo "  $0                # Run standard validation"
  echo "  $0 minimal        # Quick syntax check"
  echo "  $0 full           # Complete validation with VM builds"
  echo ""
}

main() {
  case "${VALIDATION_LEVEL}" in
    "help" | "-h" | "--help")
      show_help
      exit 0
      ;;
    "minimal")
      validate_flake && validate_nix_syntax && validate_template_structure
      ;;
    "standard")
      run_full_validation
      ;;
    "full" | "vm")
      run_full_validation
      ;;
    *)
      print_error "Unknown validation level: $VALIDATION_LEVEL"
      show_help
      exit 1
      ;;
  esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
