# Gaming Template for VM Builder
# High-performance gaming environment optimized for VMs
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

  # Performance-optimized kernel for gaming
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "elevator=mq-deadline"
    "quiet"
    "splash"
    "mitigations=off" # Gaming performance
  ];

  # Gaming and system packages
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

    # Gaming platforms
    steam
    lutris
    heroic
    bottles

    # Gaming utilities
    gamemode
    gamescope
    mangohud
    goverlay

    # Media and productivity
    firefox
    discord
    obs-studio
    vlc
    gimp

    # Development (for modding)
    vscode

    # VM integration
    spice-vdagent
  ];

  # Desktop environment optimized for gaming
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Gaming-optimized video drivers
    videoDrivers = [ "vmware" "virtualbox" "qxl" "nvidia" ];
  };

  # Enable hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Gaming-optimized audio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Networking with gaming optimizations
  networking = {
    hostName = "nixos-gaming";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 27015 27036 ]; # Steam
      allowedUDPPorts = [ 27015 27031 27032 27033 27034 27035 27036 ]; # Steam
    };
  };

  # Users with gaming groups
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Gaming User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "input" "gamemode" ];
    password = "nixos"; # Change this in production
  };

  # Gaming-friendly sudo settings
  security.sudo.wheelNeedsPassword = false;

  # VM guest services
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;

    # Auto-login for gaming convenience
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    # Flatpak for additional gaming apps
    flatpak.enable = true;
  };

  # Gaming-specific services
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
      };
    };

    gamescope.enable = true;
  };

  # Disable services that can impact gaming performance
  services.smartd.enable = false;
  powerManagement.enable = false;

  # VM-specific optimizations for gaming
  virtualisation = {
    diskSize = lib.mkDefault 81920; # 80GB for games
    memorySize = lib.mkDefault 12288; # 12GB RAM - increased for gaming performance
    cores = lib.mkDefault 6; # More cores for better gaming performance

    # Graphics optimizations for gaming
    qemu.options = [
      "-vga qxl"
      "-spice port=5930,disable-ticketing"
      "-device virtio-vga-gl"
      "-display spice-app,gl=on"
    ];
  };

  # Gaming performance optimizations
  boot.kernel.sysctl = {
    # Memory management for games
    "vm.max_map_count" = 2147483642; # For some games
    "vm.swappiness" = 1; # Minimize swapping during gaming

    # Network optimizations for online gaming
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 12582912 16777216";
    "net.ipv4.tcp_wmem" = "4096 12582912 16777216";
    "net.core.netdev_max_backlog" = 5000;
  };

  # Enable flakes and optimize for gaming builds
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # High-performance build settings
    max-jobs = "auto";
    cores = 0;
    # Use all available resources for faster game installations
    sandbox = false;
  };

  # Automatic garbage collection (less frequent for gaming)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # XDG directories for games
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Fonts for gaming
  fonts.packages = with pkgs; [
    liberation_ttf
    dejavu_fonts
    source-code-pro
    noto-fonts
    noto-fonts-emoji
  ];
}
