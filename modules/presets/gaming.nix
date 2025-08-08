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
    ../packages/gaming.nix
    ../packages/desktop-apps.nix
  ];

  config = lib.mkIf isGaming {

    # Maximum performance hardware configuration
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "gaming";
      cpuGovernor = "performance";
      enableThermalManagement = true;

      # Gaming uses desktop performance settings
      desktop = {
        enablePerformanceMode = true;
        disableUsbAutosuspend = true;
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
    modules.development.git.enable = lib.mkDefault true;

    # Gaming-specific services (opinionated preset configuration)
    services = {
      # Disable PulseAudio for lowest latency
      pulseaudio.enable = lib.mkForce false;
    };

    # Gaming programs
    programs.gamemode.enable = true;

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
        "elevator=noop"
        # GPU optimizations
        "nvidia-drm.modeset=1"
        # Disable mitigations for maximum performance (less secure)
        "mitigations=off"
        # Low latency
        "preempt=full"
      ];

      # Gaming-optimized kernel parameters
      kernel.sysctl = {
        # Minimize swap usage for better gaming performance
        "vm.swappiness" = 1;
        # Increase maximum memory map areas for games
        "vm.max_map_count" = 2147483642;
      };

      # Gaming kernel for lower latency (opinionated choice for gaming)
      kernelPackages = pkgs.linuxPackages_zen;

      # Load gaming-related modules (required for gaming hardware)
      kernelModules = [ "uinput" "kvm-intel" "kvm-amd" ];
    };

    # Hardware optimizations for gaming (opinionated preset configuration)
    hardware = {
      # Full graphics stack (essential for gaming)
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Gaming peripherals (required for Steam controllers, etc.)
      steam-hardware.enable = true;

      # Enable all firmware for gaming hardware (including proprietary)
      enableAllFirmware = true;
    };

    # Gaming-specific packages not covered by shared modules
    environment.systemPackages = with pkgs; [
      # Gaming-specific tools only
      nvidia-system-monitor-qt
      teamspeak_client
      chromium

      # Emulation
      retroarch

      # System utilities for gamers
      corectrl

      # RGB and peripheral control
      openrgb
      libratbag
    ];

    # Gaming-specific system configuration
    # Note: rtkit auto-enabled by desktop audio modules

    # Gaming-specific optimizations (preset configuration)
    systemd.settings.Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultLimitNOFILE = "1048576";
    };

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
