# Workstation Preset
# High-performance desktop for productivity and development
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isWorkstation = cfg.enable && cfg.preset == "workstation";
in

{
  imports = [
    ../core
    ../desktop
    ../hardware/power-management.nix
    ../development
  ];

  config = lib.mkIf isWorkstation {

    # Hardware optimization for desktop
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "desktop";
      cpuGovernor = "ondemand";
      enableThermalManagement = true;

      desktop = {
        enablePerformanceMode = true;
        disableUsbAutosuspend = true;
      };
    };

    # Desktop environment
    modules.desktop = lib.mkDefault {
      audio.enable = true;
      gnome.enable = true;
    };

    # Development environment
    modules.development = lib.mkDefault {
      enable = true;
      git.enable = true;
    };

    # Essential services
    services = {
      # Disable PulseAudio (PipeWire handles audio)
      pulseaudio.enable = lib.mkForce false;

      # Printing support
      printing.enable = lib.mkDefault true;

      # Network discovery
      avahi = lib.mkDefault {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    # Networking optimized for desktop
    networking = {
      networkmanager.enable = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
        # Allow common development ports
        allowedTCPPorts = lib.mkDefault [ 3000 8000 8080 ];
      };
    };

    # Performance optimizations
    boot.kernelParams = lib.mkDefault [
      # Desktop performance optimizations
      "transparent_hugepage=madvise"
      "vm.swappiness=10"
    ];

    # System packages for workstation
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Essential development tools
      firefox
      chromium
      vscode

      # System utilities  
      htop
      btop
      neofetch

      # File management
      nautilus
      file-roller

      # Media
      vlc

      # Graphics
      gimp
      inkscape
    ];

    # Font configuration
    fonts = {
      enableDefaultPackages = lib.mkDefault true;
      packages = with pkgs; lib.mkDefault [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
      ];
    };

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}
