# Desktop installer ISO configuration for macOS users
# Creates bootable NixOS ISO optimized for UTM/QEMU on Mac

{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/installer/desktop-installer.nix
  ];

  # ISO-specific configuration for macOS users
  isoImage = {
    # ISO metadata
    isoName = lib.mkForce "nixos-desktop-macos-installer";
    volumeID = "NIXOS_DESKTOP_MACOS";

    # Boot configuration optimized for macOS VMs
    makeEfiBootable = true;
    makeUsbBootable = true;

# Note: includeSystemd option was deprecated - systemd is included by default

    # Compression for smaller ISO size
    squashfsCompression = "zstd";
  };

  # Kernel configuration for macOS VM compatibility
  boot = {
    # Kernel parameters for better VM compatibility
    kernelParams = [
      "console=tty1"
      "console=ttyS0,115200"
      "systemd.unified_cgroup_hierarchy=1"
      "quiet"
      "splash"
    ];

    # Include virtio modules for UTM/QEMU
    kernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "virtio_balloon" ];
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];

    # Support both BIOS and UEFI boot
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false; # For ISO compatibility
    };
  };

  # Hardware support for macOS VMs
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Include firmware for better compatibility
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  # Services for installer environment
  services = {
    # Desktop environment
    xserver = {
      enable = true;
      videoDrivers = [ "modesetting" "virtio" "qxl" ];

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };

      desktopManager.gnome = {
        enable = true;
      };
    };

    # Network configuration already set in networking section below

    # SSH for remote installation
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      settings.PasswordAuthentication = true;
    };

    # Automatic login for installer convenience
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  # Networking
  networking = {
    hostName = "nixos-installer";
    networkmanager.enable = true;
    useDHCP = true;
    firewall.enable = false; # Open for installer
  };

  # Users for installer environment
  users = {
    users.nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      password = "nixos"; # Default password for installer
      shell = pkgs.zsh;
    };
    users.root.password = "root";
  };

  # Security - relaxed for installer
  security = {
    sudo.wheelNeedsPassword = false;
  };

  # Environment packages for installer
  environment.systemPackages = with pkgs; [
    # System utilities
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    ntfs3g

    # Network tools
    networkmanager
    curl
    wget

    # Text editors
    vim
    nano

    # File managers
    gnome.nautilus

    # Terminal
    gnome.gnome-terminal

    # Web browser for documentation
    firefox

    # Development tools
    git
    just

    # Hardware tools
    lshw
    pciutils
    usbutils
    hdparm

    # Disk management
    gnome.gnome-disks
    gparted

    # Archive tools
    unzip
    p7zip

    # Template and installer tools
    (writeShellScriptBin "install-nixos-macos" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "🍎 NixOS Desktop Installer for macOS VMs"
      echo "======================================="
      echo ""
      echo "This installer is optimized for UTM/QEMU on macOS."
      echo ""
      
      # Check if running in VM
      if [ -e /sys/class/dmi/id/product_name ]; then
        PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
        echo "Detected system: $PRODUCT"
      fi
      
      echo ""
      echo "Available templates at /etc/nixos-template:"
      ls -la /etc/nixos-template/hosts/ | grep -E "desktop|laptop" | head -5
      echo ""
      
      echo "Quick installation steps:"
      echo "1. Partition disk: sudo fdisk /dev/vda"
      echo "2. Format partitions:"
      echo "   mkfs.fat -F 32 -n boot /dev/vda1"
      echo "   mkfs.ext4 -L nixos /dev/vda2"
      echo "3. Mount filesystems:"
      echo "   mount /dev/disk/by-label/nixos /mnt"
      echo "   mkdir -p /mnt/boot"
      echo "   mount /dev/disk/by-label/boot /mnt/boot"
      echo "4. Generate config:"
      echo "   nixos-generate-config --root /mnt"
      echo "5. Customize config using templates"
      echo "6. Install: nixos-install"
      echo ""
      echo "For automated installation, run: nixos-macos-auto-install"
    '')

    (writeShellScriptBin "nixos-macos-auto-install" ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      echo "🚀 Automated NixOS Installation for macOS VMs"
      echo "============================================="
      
      # Check if running as root
      if [ "$EUID" -ne 0 ]; then
        echo "Please run as root: sudo nixos-macos-auto-install"
        exit 1
      fi
      
      # Detect disk
      if [ -b /dev/vda ]; then
        DISK="/dev/vda"
      elif [ -b /dev/sda ]; then
        DISK="/dev/sda"
      else
        echo "No suitable disk found. Please partition manually."
        exit 1
      fi
      
      echo "Installing to disk: $DISK"
      echo "WARNING: This will erase all data on $DISK!"
      echo -n "Continue? (yes/no): "
      read -r confirm
      
      if [ "$confirm" != "yes" ]; then
        echo "Installation cancelled."
        exit 1
      fi
      
      # Partition disk
      echo "Partitioning disk..."
      parted "$DISK" --script mklabel gpt
      parted "$DISK" --script mkpart ESP fat32 1MiB 512MiB
      parted "$DISK" --script set 1 esp on
      parted "$DISK" --script mkpart primary linux-swap 512MiB 2GiB
      parted "$DISK" --script mkpart primary ext4 2GiB 100%
      
      # Format partitions
      echo "Formatting partitions..."
      mkfs.fat -F 32 -n boot "''${DISK}1"
      mkswap -L swap "''${DISK}2"
      mkfs.ext4 -L nixos "''${DISK}3"
      
      # Mount filesystems
      echo "Mounting filesystems..."
      mount /dev/disk/by-label/nixos /mnt
      mkdir -p /mnt/boot
      mount /dev/disk/by-label/boot /mnt/boot
      swapon /dev/disk/by-label/swap
      
      # Generate hardware config
      echo "Generating hardware configuration..."
      nixos-generate-config --root /mnt
      
      # Copy desktop template
      echo "Installing desktop template..."
      cp -r /etc/nixos-template/hosts/desktop-template/* /mnt/etc/nixos/
      
      # Install NixOS
      echo "Installing NixOS..."
      nixos-install --no-root-passwd
      
      echo ""
      echo "✅ Installation complete!"
      echo "Default user: nixos (password: nixos)"
      echo "Please change passwords after first boot."
      echo ""
      echo "Reboot to start your new NixOS system."
    '')

    # macOS VM optimization script
    (writeShellScriptBin "optimize-for-macos-vm" ''
      echo "🔧 Optimizing NixOS for macOS VM environment..."
      
      # Enable VM-specific kernel modules
      modprobe virtio_net || true
      modprobe virtio_blk || true
      modprobe virtio_scsi || true
      
      # Network optimization
      if command -v nmcli >/dev/null; then
        echo "Configuring NetworkManager for VM..."
        nmcli connection modify "Wired connection 1" connection.autoconnect yes 2>/dev/null || true
      fi
      
      # Display optimization
      if [ -n "$DISPLAY" ]; then
        echo "Optimizing display settings for VM..."
        # Set optimal resolution for VM
        xrandr --output Virtual-1 --mode 1920x1080 2>/dev/null || true
      fi
      
      echo "✅ VM optimization complete!"
    '')
  ];

  # Include template files for reference
  environment.etc = {
    "nixos-template" = {
      source = ../..; # Root of template repository
      mode = "0755";
    };

    # macOS-specific installation guide
    "nixos-macos-guide.md" = {
      text = ''
        # NixOS Installation Guide for macOS VMs
        
        This ISO is optimized for UTM/QEMU on macOS systems.
        
        ## Quick Start
        
        1. **Automatic Installation** (Recommended):
           ```bash
           sudo nixos-macos-auto-install
           ```
        
        2. **Manual Installation**:
           - Run `install-nixos-macos` for guided installation
           - Or follow standard NixOS installation process
        
        ## VM Optimization
        
        After installation, run:
        ```bash
        optimize-for-macos-vm
        ```
        
        ## Available Templates
        
        - Desktop: Full GNOME desktop environment
        - Laptop: Laptop-optimized configuration  
        - Server: Headless server configuration
        
        Templates are located at `/etc/nixos-template/hosts/`
        
        ## Networking
        
        - DHCP is enabled by default
        - NetworkManager is pre-configured
        - SSH access: `ssh nixos@<vm-ip>` (password: nixos)
        
        ## First Boot
        
        1. Change default passwords
        2. Update system: `sudo nixos-rebuild switch --upgrade`
        3. Configure user settings
        
        For more information, visit: https://nixos.org/manual/nixos/stable/
      '';
      mode = "0644";
    };
  };

  # Enable flakes for template usage
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "nixos" ];
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
