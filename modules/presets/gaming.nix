# Gaming Preset
# High-performance configuration optimized for gaming
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isGaming = cfg.enable && cfg.preset == "gaming";
in

{
  imports = [
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

    # Gaming-specific services (opinionated preset configuration)
    services = {
      # Disable PulseAudio for lowest latency
      pulseaudio.enable = lib.mkForce false;

      # Gaming optimizations (essential for gaming preset)
      gamemode.enable = true;

      # Streaming support (gaming preset includes content creation)
      obs-studio.plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };

    # Network optimized for gaming (opinionated preset configuration)
    networking = {
      networkmanager.enable = true;
      firewall = {
        enable = true;
        # Gaming and streaming ports (specific to gaming needs)
        allowedTCPPorts = [
          27015 # Steam
          3478
          3479 # Steam Voice
          1935 # OBS Streaming
        ];
        allowedUDPPorts = [
          27015
          27031
          27032
          27033
          27034
          27035
          27036 # Steam
          3478
          4379
          4380 # Steam Voice
        ];
      };
    };

    # Maximum performance boot configuration (gaming preset is opinionated)
    boot = {
      kernelParams = [
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

      # Gaming kernel for lower latency (opinionated choice for gaming)
      kernelPackages = pkgs.linuxPackages_zen;

      # Load gaming-related modules (required for gaming hardware)
      kernelModules = [ "uinput" "kvm-intel" "kvm-amd" ];
    };

    # Hardware optimizations for gaming (opinionated preset configuration)
    hardware = {
      # Full graphics stack (essential for gaming)
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      # Gaming peripherals (required for Steam controllers, etc.)
      steam-hardware.enable = true;

      # Audio for gaming
      pulseaudio.enable = lib.mkForce false;

      # Enable all firmware for gaming hardware (including proprietary)
      enableAllFirmware = true;
    };

    # Gaming-focused packages (opinionated gaming preset)
    environment.systemPackages = with pkgs; [
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

    # Gaming-specific optimizations (preset configuration)
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=10s
      DefaultLimitNOFILE=1048576
    '';

    # Gaming group and permissions
    users.groups.gamemode = { };
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
