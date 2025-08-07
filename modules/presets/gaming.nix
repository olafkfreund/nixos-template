# Gaming Preset
# High-performance configuration optimized for gaming
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isGaming = cfg.enable && cfg.preset == "gaming";
in

{
  imports = lib.mkIf isGaming [
    ../core
    ../desktop
    ../hardware/power-management.nix
    ../gaming
    ../development
  ];

  config = lib.mkIf isGaming {

    # Maximum performance hardware configuration
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "gaming";
      cpuGovernor = "performance";
      enableThermalManagement = true;
      
      gaming = {
        enableGameMode = true;
        optimizeForLatency = true;
        disablePowerSaving = true;
      };
    };

    # Gaming-optimized desktop
    modules.desktop = lib.mkDefault {
      audio.enable = true;
      gnome.enable = true;
    };

    # Full gaming suite
    modules.gaming = lib.mkDefault {
      steam = {
        enable = true;
        performance.gamemode = true;
        performance.mangohud = true;
      };
    };

    # Development tools for modding/streaming
    modules.development = lib.mkDefault {
      enable = true;
      git.enable = true;
    };

    # Gaming-specific services
    services = {
      # Disable PulseAudio for lowest latency
      pulseaudio.enable = lib.mkForce false;
      
      # Gaming optimizations
      gamemode.enable = lib.mkDefault true;
      
      # Streaming support
      obs-studio.plugins = lib.mkDefault [ pkgs.obs-studio-plugins.wlrobs ];
    };

    # Network optimized for gaming
    networking = {
      networkmanager.enable = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
        # Gaming and streaming ports
        allowedTCPPorts = lib.mkDefault [ 
          27015 # Steam
          3478 3479 # Steam Voice
          1935 # OBS Streaming
        ];
        allowedUDPPorts = lib.mkDefault [
          27015 27031 27032 27033 27034 27035 27036 # Steam
          3478 4379 4380 # Steam Voice
        ];
      };
    };

    # Maximum performance boot configuration
    boot = {
      kernelParams = lib.mkDefault [
        # Gaming performance optimizations
        "transparent_hugepage=always"
        "vm.swappiness=1"
        "elevator=noop"
        # GPU optimizations
        "nvidia-drm.modeset=1"
        # Disable mitigations for maximum performance (less secure)
        "mitigations=off"
        # Low latency
        "preempt=full"
      ];
      
      # Gaming kernel for lower latency
      kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
      
      # Load gaming-related modules
      kernelModules = lib.mkDefault [ "uinput" "kvm-intel" "kvm-amd" ];
    };

    # Hardware optimizations for gaming
    hardware = {
      # Full graphics stack
      opengl = {
        enable = lib.mkDefault true;
        driSupport = lib.mkDefault true;
        driSupport32Bit = lib.mkDefault true;
      };
      
      # Gaming peripherals
      steam-hardware.enable = lib.mkDefault true;
      
      # Audio for gaming
      pulseaudio.enable = lib.mkForce false;
      
      # Enable all firmware for gaming hardware
      enableAllFirmware = lib.mkDefault true;
    };

    # Gaming-focused packages
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Games and gaming platforms
      steam
      lutris
      heroic
      
      # Game development
      godot_4
      blender
      
      # Streaming and content creation
      obs-studio
      kdenlive
      audacity
      
      # Gaming utilities
      mangohud
      goverlay
      gamemode
      
      # Performance monitoring
      htop
      btop
      nvidia-system-monitor-qt
      
      # Communication
      discord
      teamspeak_client
      
      # Browsers optimized for gaming
      firefox
      chromium
      
      # Emulation
      retroarch
      
      # System utilities for gamers
      corectrl
      
      # RGB and peripheral control
      openrgb
      ratbagd
    ];

    # Gaming-specific system configuration
    # Note: rtkit auto-enabled by desktop audio modules
    
    # Optimizations
    systemd.extraConfig = lib.mkDefault ''
      DefaultTimeoutStopSec=10s
      DefaultLimitNOFILE=1048576
    '';

    # Gaming group and permissions
    users.groups.gamemode = {};
    security.wrappers.gamemode = {
      owner = "root";
      group = "gamemode";
      source = "${pkgs.gamemode}/bin/gamemoderun";
      setuid = true;
    };

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}