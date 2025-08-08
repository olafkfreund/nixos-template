# Minimal installer ISO configuration for macOS users
# Creates lightweight bootable NixOS ISO for server installations

{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/installer/minimal-installer.nix
  ];

  # ISO-specific configuration
  isoImage = {
    isoName = lib.mkForce "nixos-minimal-macos-installer";
    volumeID = "NIXOS_MIN_MACOS";

    # Boot configuration
    makeEfiBootable = true;
    makeUsbBootable = true;

    # Aggressive compression for minimal size
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  # Minimal kernel configuration
  boot = {
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
      "systemd.unified_cgroup_hierarchy=1"
    ];

    # VM-essential modules only
    kernelModules = [ "virtio_net" "virtio_blk" "virtio_scsi" ];
    initrd.availableKernelModules = [ "virtio_net" "virtio_blk" "virtio_scsi" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };
  };

  # Minimal hardware support
  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # Minimal services - no GUI
  services = {
    # SSH only
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    # Minimal getty on serial console
    getty.autologinUser = lib.mkDefault "nixos";
  };

  # Basic networking
  networking = {
    hostName = "nixos-minimal-installer";
    useDHCP = lib.mkDefault true;
    firewall.enable = false;
  };

  # Minimal users
  users = {
    users.nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = "nixos";
      shell = pkgs.bash; # Use bash instead of zsh for minimal
    };
    # Override root password for macOS ISO installer convenience
    users.root = {
      # Use initialPassword to override the locked password from core/users.nix
      initialPassword = lib.mkOverride 40 "root"; # Higher priority than base installer
      # Aggressively clear ALL other password options to prevent conflicts
      hashedPassword = lib.mkOverride 60 null;
      password = lib.mkOverride 60 null;
      # Force initialHashedPassword to null to override any system defaults
      initialHashedPassword = lib.mkOverride 60 null;
      hashedPasswordFile = lib.mkOverride 60 null;
    };
  };

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Minimal packages for server installation
  environment.systemPackages = with pkgs; [
    # Essential system tools
    parted
    dosfstools
    e2fsprogs

    # Network tools
    curl
    wget
    openssh

    # Text editors
    vim
    nano

    # Hardware detection
    lshw
    pciutils

    # Development essentials
    git

    # Minimal installer tools
    (writeShellScriptBin "install-nixos-server-macos" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🖥️  NixOS Minimal Server Installer for macOS VMs"
      echo "==============================================="
      echo ""
      echo "This minimal installer is optimized for:"
      echo "- UTM/QEMU on macOS"
      echo "- Headless server installations"
      echo "- Resource-constrained environments"
      echo ""

      # System info
      echo "System Information:"
      echo "- Architecture: $(uname -m)"
      echo "- Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
      echo "- CPUs: $(nproc)"
      echo ""

      echo "Available server templates:"
      ls -1 /etc/nixos-template/hosts/ | grep -E "server|minimal" || echo "- server-template (basic server)"
      echo ""

      echo "Quick server installation:"
      echo "1. sudo server-auto-install"
      echo ""
      echo "Manual installation:"
      echo "1. Partition disk: fdisk /dev/vda"
      echo "2. Format: mkfs.ext4 -L nixos /dev/vda1"
      echo "3. Mount: mount /dev/disk/by-label/nixos /mnt"
      echo "4. Generate config: nixos-generate-config --root /mnt"
      echo "5. Copy server template to /mnt/etc/nixos/"
      echo "6. Install: nixos-install"
      echo ""
      echo "SSH access: ssh nixos@<vm-ip> (password: nixos)"
    '')

    (writeShellScriptBin "server-auto-install" ''
            #!/usr/bin/env bash
            set -euo pipefail

            echo "🚀 Automated Server Installation for macOS VMs"
            echo "=============================================="

            # Check if running as root
            if [ "$EUID" -ne 0 ]; then
              echo "Please run as root: sudo server-auto-install"
              exit 1
            fi

            # Detect disk
            if [ -b /dev/vda ]; then
              DISK="/dev/vda"
            elif [ -b /dev/sda ]; then
              DISK="/dev/sda"
            else
              echo "No suitable disk found. Available disks:"
              lsblk -d -o NAME,SIZE,MODEL
              echo "Please partition manually or specify disk."
              exit 1
            fi

            echo "Installing server to: $DISK"
            echo "WARNING: This will erase all data on $DISK!"
            echo -n "Continue? (yes/no): "
            read -r confirm

            if [ "$confirm" != "yes" ]; then
              echo "Installation cancelled."
              exit 1
            fi

            # Simple single partition setup for server
            echo "Creating partition table..."
            parted "$DISK" --script mklabel gpt
            parted "$DISK" --script mkpart ESP fat32 1MiB 512MiB
            parted "$DISK" --script set 1 esp on
            parted "$DISK" --script mkpart primary linux-swap 512MiB 1.5GiB
            parted "$DISK" --script mkpart primary ext4 1.5GiB 100%

            # Format partitions
            echo "Formatting partitions..."
            mkfs.fat -F 32 -n boot "''${DISK}1"
            mkswap -L swap "''${DISK}2"
            mkfs.ext4 -L nixos "''${DISK}3"

            # Mount
            echo "Mounting filesystems..."
            mount /dev/disk/by-label/nixos /mnt
            mkdir -p /mnt/boot
            mount /dev/disk/by-label/boot /mnt/boot
            swapon /dev/disk/by-label/swap

            # Generate config
            echo "Generating hardware configuration..."
            nixos-generate-config --root /mnt

            # Copy server template
            if [ -d /etc/nixos-template/hosts/server-template ]; then
              echo "Installing server template..."
              cp -r /etc/nixos-template/hosts/server-template/* /mnt/etc/nixos/
            elif [ -d /etc/nixos-template/hosts/macos-vms/server-macos.nix ]; then
              echo "Installing macOS-optimized server template..."
              cp /etc/nixos-template/hosts/macos-vms/server-macos.nix /mnt/etc/nixos/configuration.nix
            else
              echo "Using generated configuration..."
              # Add basic server settings to generated config
              cat >> /mnt/etc/nixos/configuration.nix << 'EOF'

        # Basic server configuration
        services.openssh.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 80 443 ];
        users.users.server = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          initialPassword = "server";
        };
      EOF
            fi

            # Install
            echo "Installing NixOS server..."
            nixos-install --no-root-passwd

            echo ""
            echo "✅ Server installation complete!"
            echo ""
            echo "Default users:"
            echo "- nixos (password: nixos)"
            echo "- server (password: server) - if using template"
            echo ""
            echo "SSH access after reboot:"
            echo "ssh nixos@<server-ip>"
            echo ""
            echo "Next steps after reboot:"
            echo "1. Change default passwords"
            echo "2. Configure SSH keys"
            echo "3. Update system: sudo nixos-rebuild switch --upgrade"
            echo "4. Configure services as needed"
            echo ""
            echo "Reboot to start your NixOS server."
    '')

    # VM network diagnostic tool
    (writeShellScriptBin "vm-network-check" ''
      echo "🌐 VM Network Diagnostics for macOS"
      echo "=================================="
      echo ""
      echo "Network Interfaces:"
      ip addr show
      echo ""
      echo "Default Route:"
      ip route show default
      echo ""
      echo "DNS Configuration:"
      cat /etc/resolv.conf
      echo ""
      echo "Connectivity Test:"
      ping -c 3 8.8.8.8 || echo "❌ No internet connectivity"
      ping -c 1 google.com || echo "❌ No DNS resolution"
      echo ""
      echo "VM Network Info:"
      echo "- DHCP: Enabled"
      echo "- NAT: Automatic via UTM/QEMU"
      echo "- Port Forwarding: Configure in UTM/QEMU settings"
    '')
  ];

  # Template files
  environment.etc = {
    "nixos-template" = {
      source = ../..;
      mode = "0755";
    };

    "server-install-guide.txt" = {
      text = ''
        NixOS Minimal Server Installer for macOS VMs
        ==========================================

        This minimal installer provides:
        - Command-line interface only
        - Essential tools for server installation
        - Optimized for UTM/QEMU on macOS

        Quick Commands:
        - install-nixos-server-macos: Interactive installation guide
        - server-auto-install: Automated server installation
        - vm-network-check: Network diagnostics

        Default Login:
        - Username: nixos
        - Password: nixos
        - SSH: Enabled on port 22

        For GUI installer, use the desktop ISO instead.

        Documentation: /etc/nixos-template/
      '';
      mode = "0644";
    };
  };

  # Enable flakes
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "nixos" ];
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
