# Laptop Configuration - New Preset-based Approach
# Minimal configuration focusing on laptop-specific needs
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/presets
  ];

  # System identification
  networking.hostName = "laptop-template";

  # Use the laptop preset
  modules.presets = {
    enable = true;
    preset = "laptop";

    # Laptop-specific customizations
    customizations = {
      # Enable development tools for mobile work
      modules.development = {
        enable = true;
        git = {
          enable = true;
          # Configure for mobile development
          config = {
            user.name = "Your Name";
            user.email = "your.email@example.com";
          };
        };
      };

      # Add laptop-specific packages
      environment.systemPackages = with pkgs; [
        # Mobile productivity
        libreoffice
        thunderbird

        # VPN clients for remote work
        openvpn
        networkmanager-openvpn

        # Battery monitoring
        powertop
        tlp
      ];

      # Custom power settings
      services.tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        };
      };
    };
  };

  # Laptop-specific hardware (if needed)
  # Most hardware detection is automatic via preset
}
