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

    # Desktop environment (preset choice - use lib.mkDefault to allow override)
    modules.desktop = lib.mkDefault {
      audio.enable = true;
      gnome.enable = true;
    };

    # Development environment (preset choice - use lib.mkDefault to allow override) 
    modules.development.git.enable = lib.mkDefault true;

    # Essential services (opinionated preset configuration)
    services = {
      # Disable PulseAudio (PipeWire handles audio)
      pulseaudio.enable = lib.mkForce false;

      # Printing support (workstations typically need printing)
      printing.enable = true;

      # Network discovery (helpful for workstations)
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    # Networking optimized for desktop  
    networking = {
      networkmanager.enable = true;
      firewall = {
        enable = true;
        # Common development ports (opinionated for workstation preset)
        allowedTCPPorts = [ 3000 8000 8080 ];
      };
    };

    # Performance optimizations (workstation-specific)
    boot.kernelParams = [
      "transparent_hugepage=madvise"
      "vm.swappiness=10"
    ];

    # Core workstation packages (opinionated preset choice)
    environment.systemPackages = with pkgs; [
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

    # Font configuration (workstation needs good fonts)
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
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
