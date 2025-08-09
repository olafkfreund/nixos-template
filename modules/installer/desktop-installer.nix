# Desktop installer configuration
# This creates an ISO with GNOME desktop for easier graphical installation

{ lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  # ISO metadata
  image.fileName = "nixos-desktop-installer.iso";
  isoImage = {
    volumeID = "NIXOS_DESKTOP";
  };

  # Enable GNOME desktop
  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false; # Don't suspend during installation
  };
  services.desktopManager.gnome.enable = true;

  # GNOME configuration for installer
  services.gnome = {
    core-apps.enable = true;

    # Disable some services we don't need in installer
    games.enable = lib.mkForce false;
  };

  # Audio support (rtkit auto-enabled by PipeWire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Additional desktop packages
  environment.systemPackages = with pkgs; [
    # Browsers for documentation
    firefox

    # Terminal emulator
    gnome-terminal

    # File manager
    nautilus

    # Text editors with GUI
    gedit

    # System monitoring
    gnome-system-monitor

    # Disk management
    gnome-disk-utility

    # Archive manager
    file-roller

    # Additional useful tools
    gparted

    # Development
    vscode
  ];

  # Auto-login to desktop (installer convenience)
  services.displayManager.autoLogin = {
    enable = true;
    user = "installer";
  };

  # Create installer user
  users.users.installer = {
    isNormalUser = true;
    description = "NixOS Installer User";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "installer";
  };

  # Allow installer user to use sudo
  security.sudo.wheelNeedsPassword = false;

  # Desktop-specific installer script
  environment.etc."installer/desktop-install.sh" = {
    text = ''
      #!/usr/bin/env bash

      echo "NixOS Desktop Installer"
      echo "======================"
      echo
      echo "This ISO includes a full GNOME desktop environment."
      echo "You can use the graphical tools or command line to install NixOS."
      echo
      echo "Available tools:"
      echo "  - GParted: Partition your disks"
      echo "  - Firefox: Access documentation online"
      echo "  - Terminal: Use nixos-install command"
      echo "  - File Manager: Browse files and configurations"
      echo
      echo "Installation steps:"
      echo "1. Partition your disk (use GParted or fdisk/parted)"
      echo "2. Mount your partitions to /mnt"
      echo "3. Generate configuration: nixos-generate-config --root /mnt"
      echo "4. Edit /mnt/etc/nixos/configuration.nix"
      echo "5. Install: nixos-install"
      echo "6. Reboot and enjoy NixOS!"
      echo

      read -p "Press Enter to continue..."
    '';
    mode = "0755";
  };

  # Auto-run installer info on desktop login
  environment.etc."xdg/autostart/installer-info.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=NixOS Installer Information
      Exec=gnome-terminal -- /etc/installer/desktop-install.sh
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
    '';
  };
}
