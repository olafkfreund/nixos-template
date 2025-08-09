# Desktop Template for VM Builder
# Full desktop environment optimized for VMs
{ config, pkgs, lib, ... }:

{
  imports = [
    # Enable VM optimizations
    <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
    <nixpkgs/nixos/modules/virtualisation/qemu-guest-agent.nix>
  ];

  # System configuration
  system.stateVersion = "24.05";

  # Boot configuration for VMs
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # VM-optimized kernel
  boot.kernelParams = [
    "elevator=noop"
    "quiet"
    "splash"
  ];

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # System tools
    git
    curl
    wget
    vim
    nano
    htop
    tree
    unzip

    # Desktop applications
    firefox
    thunderbird
    libreoffice
    vlc
    gimp

    # Development tools
    vscode
    docker

    # VM integration
    spice-vdagent
  ];

  # Desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # VM optimizations
    videoDrivers = [ "vmware" "virtualbox" "qxl" ];
  };

  # Enable sound
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Networking
  networking = {
    hostName = "nixos-desktop";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Users
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    password = "nixos"; # Change this in production
  };

  # Enable sudo without password for initial setup
  security.sudo.wheelNeedsPassword = false;

  # VM guest services
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;

    # Auto-login for VM convenience
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  # Disable services not needed in VMs
  services.smartd.enable = false;
  powerManagement.enable = false;

  # VM-specific optimizations
  virtualisation = {
    diskSize = lib.mkDefault 30720; # 30GB - increased for desktop apps
    memorySize = lib.mkDefault 6144; # 6GB - increased for desktop environment
    cores = lib.mkDefault 4; # More cores for better desktop performance

    # Graphics optimizations
    qemu.options = [
      "-vga qxl"
      "-spice port=5930,disable-ticketing"
    ];
  };

  # Enable flakes and new nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
