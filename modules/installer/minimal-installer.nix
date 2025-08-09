# Minimal installer configuration
# This creates a lightweight ISO for command-line installation

{ lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  # ISO metadata
  image.fileName = "nixos-minimal-installer.iso";
  isoImage = {
    volumeID = "NIXOS_MINIMAL";

    # Smaller ISO for minimal installer
    squashfsCompression = lib.mkForce "gzip -Xcompression-level 6";
  };

  # Keep it minimal - no desktop environment
  services.xserver.enable = lib.mkForce false;


  # Enhanced console experience
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";

    # Enable early console
    earlySetup = true;
  };

  # Improved shell experience
  programs.bash = {
    completion.enable = true;

    # Helpful aliases for installation
    shellAliases = {
      l = "ls -alh";
      ll = "ls -l";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Installation shortcuts
      "mount-boot" = "mkdir -p /mnt/boot && mount /dev/disk/by-label/BOOT /mnt/boot";
      "mount-root" = "mount /dev/disk/by-label/nixos /mnt";
      "gen-config" = "nixos-generate-config --root /mnt";
      "install-nixos" = "nixos-install";

      # Hardware detection
      "hw-info" = "lshw -short";
      "disk-info" = "fdisk -l";
      "part-info" = "lsblk -f";
    };

    # Helpful prompt
    promptInit = ''
      PS1='\[\e[1;32m\][\u@nixos-installer:\[\e[1;34m\]\w\[\e[1;32m\]]\$\[\e[0m\] '
    '';
  };

  # Installation helper script
  environment.etc."installer/install-guide.sh" = {
    text = ''
      #!/usr/bin/env bash

      cat << 'EOF'
      ╔══════════════════════════════════════════════════════════════╗
      ║                    NixOS Minimal Installer                   ║
      ╚══════════════════════════════════════════════════════════════╝

      Quick Installation Guide:
      ========================

      1. Partition your disk:
         fdisk /dev/sdX
         # Create EFI partition (512MB) and root partition

      2. Format partitions:
         mkfs.fat -F 32 -n BOOT /dev/sdX1    # EFI partition
         mkfs.ext4 -L nixos /dev/sdX2         # Root partition

      3. Mount filesystems:
         mount /dev/disk/by-label/nixos /mnt
         mkdir -p /mnt/boot
         mount /dev/disk/by-label/BOOT /mnt/boot

      4. Generate configuration:
         nixos-generate-config --root /mnt

      5. Edit configuration:
         nano /mnt/etc/nixos/configuration.nix

      6. Install NixOS:
         nixos-install

      7. Reboot:
         reboot

      Available commands:
      ==================
      hw-info      - Show hardware information
      disk-info    - Show disk information
      part-info    - Show partition information
      mount-root   - Quick mount root partition
      mount-boot   - Quick mount boot partition
      gen-config   - Generate NixOS configuration
      install-nixos - Install NixOS

      Network Setup:
      =============
      # WiFi connection:
      systemctl start wpa_supplicant
      wpa_cli
      > add_network
      > set_network 0 ssid "YourWiFiName"
      > set_network 0 psk "YourWiFiPassword"
      > enable_network 0
      > quit

      # Or use NetworkManager:
      nmcli dev wifi connect "YourWiFiName" password "YourWiFiPassword"

      For detailed documentation: https://nixos.org/manual/nixos/stable/

      EOF

      read -p "Press Enter to continue..."
    '';
    mode = "0755";
  };

  # Show install guide on login
  programs.bash.interactiveShellInit = ''
    if [ "$XDG_SESSION_TYPE" = "tty" ] && [ -z "$INSTALL_GUIDE_SHOWN" ]; then
      export INSTALL_GUIDE_SHOWN=1
      echo
      echo "Welcome to NixOS Minimal Installer!"
      echo "Type 'install-guide' to see the installation guide."
      echo
    fi
  '';

  # Add install-guide command to existing systemPackages
  environment.systemPackages = with pkgs; [
    # Keep base packages from base.nix
    # Add minimal-specific tools

    # Text-based utilities
    lynx # Text web browser for docs
    tmux # Terminal multiplexer
    screen # Alternative terminal multiplexer

    # Network diagnostics
    iftop
    nethogs

    # Minimal text editors (nano/vim already in base)

    # Installation helpers
    nixos-install-tools

    # Install guide command
    (writeScriptBin "install-guide" ''
      #!/usr/bin/env bash
      /etc/installer/install-guide.sh
    '')
  ];
}
