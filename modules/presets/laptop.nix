# Laptop Preset
# Optimized for mobile computing with battery life focus
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isLaptop = cfg.enable && cfg.preset == "laptop";
in

{
  imports = [
    ../core
    ../desktop
    ../hardware/power-management.nix
    ../development
  ];

  config = lib.mkIf isLaptop {

    # Hardware optimization for laptop
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "laptop";
      enableThermalManagement = true;

      laptop = {
        enableBatteryOptimization = true;
        enableTlp = true;
        suspendMethod = "suspend";
        wakeOnLid = true;
      };
    };

    # Desktop environment optimized for mobile
    modules.desktop = lib.mkDefault {
      audio.enable = true;
      gnome.enable = true;
    };

    # Development environment (lighter than workstation)
    modules.development.git.enable = lib.mkDefault true;

    # Mobile-optimized services
    services = {
      # Disable PulseAudio (PipeWire handles audio)
      pulseaudio.enable = lib.mkForce false;

      # Essential for mobile work
      printing.enable = true;

      # Bluetooth for peripherals (common on laptops)
      blueman.enable = true;

      # Location services (useful for laptops that move around)
      geoclue2.enable = true;

      # Time synchronization (important for mobile devices)
      ntp.enable = true;
    };

    # Mobile networking configuration
    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          powersave = true;
          backend = "iwd";
        };
      };

      # Secure firewall (laptops are more exposed)
      firewall = {
        enable = true;
        # More restrictive than workstation (no dev ports)
        allowedTCPPorts = [ ];
      };
    };

    # Battery-optimized boot parameters
    boot.kernelParams = lib.mkDefault [
      # Power saving optimizations
      "intel_pstate=enable"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
    ];

    # Laptop-specific hardware
    hardware = {
      # Enable all firmware (including WiFi)
      enableAllFirmware = lib.mkDefault true;

      # CPU microcode updates
      cpu.intel.updateMicrocode = lib.mkDefault true;
      cpu.amd.updateMicrocode = lib.mkDefault true;

      # Graphics acceleration
      opengl.enable = lib.mkDefault true;

      # Bluetooth
      bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = lib.mkDefault false; # Save battery
      };
    };

    # Mobile-focused system packages
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Essential productivity
      firefox

      # Communication
      thunderbird

      # System monitoring (battery focused)
      htop
      powertop

      # File management
      nautilus

      # Quick text editing
      gedit

      # Network utilities
      networkmanager-openvpn
      networkmanager-openconnect
    ];

    # Power management settings
    powerManagement = {
      enable = lib.mkDefault true;
      cpuFreqGovernor = lib.mkDefault "powersave";
    };

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}
