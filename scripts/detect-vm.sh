#!/usr/bin/env bash

# VM Detection Script
# Detects if we're running in a virtual machine and which type

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect virtualization
detect_virtualization() {
  local vm_type="none"
  local confidence="low"
  local details=""

  # Method 1: systemd-detect-virt (most reliable)
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    local systemd_result
    systemd_result=$(systemd-detect-virt 2>/dev/null || echo "none")

    if [ "$systemd_result" != "none" ]; then
      vm_type="$systemd_result"
      confidence="high"
      details="Detected via systemd-detect-virt"
    fi
  fi

  # Method 2: DMI/SMBIOS information
  if [ "$vm_type" = "none" ] && [ -r /sys/class/dmi/id/product_name ]; then
    local product_name
    product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")

    case "$product_name" in
      *"VirtualBox"*)
        vm_type="virtualbox"
        confidence="high"
        details="DMI Product Name: $product_name"
        ;;
      *"VMware"*)
        vm_type="vmware"
        confidence="high"
        details="DMI Product Name: $product_name"
        ;;
      *"QEMU"*)
        vm_type="qemu"
        confidence="high"
        details="DMI Product Name: $product_name"
        ;;
      *"Microsoft Corporation"*)
        vm_type="hyperv"
        confidence="medium"
        details="DMI Product Name: $product_name"
        ;;
      *"Xen"*)
        vm_type="xen"
        confidence="high"
        details="DMI Product Name: $product_name"
        ;;
    esac
  fi

  # Method 3: Check DMI system vendor
  if [ "$vm_type" = "none" ] && [ -r /sys/class/dmi/id/sys_vendor ]; then
    local sys_vendor
    sys_vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")

    case "$sys_vendor" in
      *"innotek"* | *"Oracle"*)
        vm_type="virtualbox"
        confidence="high"
        details="DMI System Vendor: $sys_vendor"
        ;;
      *"VMware"*)
        vm_type="vmware"
        confidence="high"
        details="DMI System Vendor: $sys_vendor"
        ;;
      *"QEMU"*)
        vm_type="qemu"
        confidence="high"
        details="DMI System Vendor: $sys_vendor"
        ;;
      *"Microsoft"*)
        vm_type="hyperv"
        confidence="medium"
        details="DMI System Vendor: $sys_vendor"
        ;;
      *"Xen"*)
        vm_type="xen"
        confidence="high"
        details="DMI System Vendor: $sys_vendor"
        ;;
    esac
  fi

  # Method 4: Check for hypervisor CPUID bit
  if [ "$vm_type" = "none" ] && [ -r /proc/cpuinfo ]; then
    if grep -q "^flags.*hypervisor" /proc/cpuinfo; then
      vm_type="unknown"
      confidence="medium"
      details="Hypervisor flag detected in /proc/cpuinfo"
    fi
  fi

  # Method 5: Check for VM-specific devices
  if [ "$vm_type" = "none" ]; then
    # VirtualBox
    if lspci 2>/dev/null | grep -qi "virtualbox"; then
      vm_type="virtualbox"
      confidence="high"
      details="VirtualBox PCI devices detected"
    # VMware
    elif lspci 2>/dev/null | grep -qi "vmware"; then
      vm_type="vmware"
      confidence="high"
      details="VMware PCI devices detected"
    # QEMU/KVM
    elif lspci 2>/dev/null | grep -qi "virtio\|qemu\|red hat"; then
      vm_type="qemu"
      confidence="high"
      details="VirtIO/QEMU devices detected"
    fi
  fi

  # Method 6: Check kernel modules
  if [ "$vm_type" = "none" ] && [ -r /proc/modules ]; then
    if grep -q "vboxguest\|vboxvideo\|vboxsf" /proc/modules 2>/dev/null; then
      vm_type="virtualbox"
      confidence="medium"
      details="VirtualBox kernel modules loaded"
    elif grep -q "vmw_\|vmware" /proc/modules 2>/dev/null; then
      vm_type="vmware"
      confidence="medium"
      details="VMware kernel modules loaded"
    elif grep -q "virtio\|kvm" /proc/modules 2>/dev/null; then
      vm_type="qemu"
      confidence="medium"
      details="VirtIO/KVM kernel modules loaded"
    fi
  fi

  echo "$vm_type:$confidence:$details"
}

# Function to get VM-specific recommendations
get_vm_recommendations() {
  local vm_type="$1"

  case "$vm_type" in
    qemu)
      cat <<EOF
QEMU/KVM VM detected. Recommended configuration:
- Use VirtIO drivers for best performance
- Enable SPICE guest agent for clipboard sharing
- Consider virtio-gpu for graphics acceleration
- Use virtio-blk or virtio-scsi for storage
EOF
      ;;
    virtualbox)
      cat <<EOF
VirtualBox VM detected. Recommended configuration:
- Install VirtualBox Guest Additions
- Enable bidirectional clipboard sharing
- Configure shared folders if needed
- Use VMSVGA or VBoxVGA graphics adapter
EOF
      ;;
    vmware)
      cat <<EOF
VMware VM detected. Recommended configuration:
- Install VMware Tools (open-vm-tools)
- Enable shared folders and clipboard
- Use VMXNET3 network adapter for best performance
- Consider enabling 3D acceleration
EOF
      ;;
    hyperv)
      cat <<EOF
Hyper-V VM detected. Recommended configuration:
- Use synthetic devices for best performance
- Enable integration services
- Consider Generation 2 VMs for UEFI support
- Use Hyper-V specific network adapters
EOF
      ;;
    xen)
      cat <<EOF
Xen VM detected. Recommended configuration:
- Use paravirtualized drivers where possible
- Enable Xen guest utilities
- Consider both PV and HVM modes
EOF
      ;;
    unknown)
      cat <<EOF
Unknown virtualization detected. Generic recommendations:
- Check for guest additions/tools for your hypervisor
- Use paravirtualized drivers when available
- Enable clipboard and folder sharing if supported
EOF
      ;;
    none)
      echo "Physical hardware detected. VM optimizations not needed."
      ;;
  esac
}

# Function to check VM-specific hardware
check_vm_hardware() {
  local vm_type="$1"

  echo
  print_info "Hardware analysis for $vm_type environment:"

  # CPU information
  if [ -r /proc/cpuinfo ]; then
    local cpu_count
    cpu_count=$(nproc 2>/dev/null || echo "unknown")
    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs 2>/dev/null || echo "unknown")

    echo "  CPU: $cpu_count cores ($cpu_model)"
  fi

  # Memory information
  if [ -r /proc/meminfo ]; then
    local mem_total
    mem_total=$(grep "MemTotal" /proc/meminfo | awk '{printf "%.1f GB", $2/1024/1024}' 2>/dev/null || echo "unknown")
    echo "  Memory: $mem_total"
  fi

  # Storage information
  echo "  Storage devices:"
  if command -v lsblk >/dev/null 2>&1; then
    lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null | grep -E "(disk|rom)" | while read -r line; do
      echo "    $line"
    done
  else
    find /dev -maxdepth 1 -name '[sv]d*' -o -name 'nvme*' 2>/dev/null | head -5 | while read -r dev; do ls -la "$dev"; done || echo "    Unable to detect storage devices"
  fi

  # Network information
  echo "  Network interfaces:"
  ip -o link show 2>/dev/null | awk '{print "    " $2 " (" $17 ")"}' | sed 's/@[^:]*://' || echo "    Unable to detect network interfaces"

  # Graphics information
  if command -v lspci >/dev/null 2>&1; then
    local gpu_info
    gpu_info=$(lspci | grep -i "vga\|3d\|display" 2>/dev/null || echo "No GPU detected")
    echo "  Graphics: $gpu_info"
  fi
}

# Function to suggest NixOS configuration
suggest_nixos_config() {
  local vm_type="$1"

  echo
  print_info "Suggested NixOS configuration additions:"

  cat <<EOF

# Add to your configuration.nix:
modules.virtualization.vm-guest = {
  enable = true;
  type = "$vm_type";  # or "auto" for auto-detection
  
  optimizations = {
    performance = true;
    graphics = true;
    networking = true;
    storage = true;
  };
  
  guestTools = {
    enable = true;
    clipboard = true;
    folderSharing = true;
    timeSync = true;
  };
  
  serial = {
    enable = true;  # Useful for headless VMs
  };
};
EOF

  case "$vm_type" in
    qemu)
      cat <<EOF

# QEMU/KVM specific additions:
services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;

# For better graphics performance:
hardware.graphics.extraPackages = with pkgs; [
  virglrenderer
  mesa
];
EOF
      ;;
    virtualbox)
      cat <<EOF

# VirtualBox specific additions:
virtualisation.virtualbox.guest.enable = true;
virtualisation.virtualbox.guest.x11 = true;

# For shared folders:
users.users.yourusername.extraGroups = [ "vboxsf" ];
EOF
      ;;
    vmware)
      cat <<EOF

# VMware specific additions:
virtualisation.vmware.guest.enable = true;

# For shared folders and better integration:
services.vmwareGuest.enable = true;
EOF
      ;;
  esac
}

# Main function
main() {
  echo -e "${BLUE}=================================="
  echo "     VM Detection & Analysis"
  echo -e "==================================${NC}"
  echo

  print_info "Detecting virtualization environment..."

  local detection_result
  detection_result=$(detect_virtualization)

  IFS=':' read -r vm_type confidence details <<<"$detection_result"

  if [ "$vm_type" = "none" ]; then
    print_success "Physical hardware detected - no virtualization"
    print_info "This system appears to be running on physical hardware."
    print_info "VM-specific optimizations are not needed."
    exit 0
  else
    case "$confidence" in
      high)
        print_success "Virtual machine detected: $vm_type (high confidence)"
        ;;
      medium)
        print_warning "Virtual machine possibly detected: $vm_type (medium confidence)"
        ;;
      low)
        print_warning "Virtualization suspected: $vm_type (low confidence)"
        ;;
    esac

    if [ -n "$details" ]; then
      print_info "Detection method: $details"
    fi
  fi

  check_vm_hardware "$vm_type"

  echo
  get_vm_recommendations "$vm_type"

  suggest_nixos_config "$vm_type"

  echo
  print_info "Next steps:"
  echo "1. Add the suggested configuration to your NixOS config"
  echo "2. Run 'sudo nixos-rebuild switch' to apply changes"
  echo "3. Reboot to ensure all VM optimizations are active"
  echo "4. Test guest tools functionality (clipboard, shared folders, etc.)"

  # Return VM type for scripting
  echo
  echo "VM_TYPE=$vm_type"
  echo "CONFIDENCE=$confidence"
}

# Check if script is being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
