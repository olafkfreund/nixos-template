# Desktop Configuration - New Preset-based Approach
# This replaces 400+ lines of configuration with just the essentials
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/presets
  ];

  # System identification
  networking.hostName = "desktop-template";

  # Use the workstation preset with gaming extensions
  modules.presets = {
    enable = true;
    preset = "workstation";

    # Override specific settings for this desktop
    customizations = {
      # Add gaming support to workstation preset
      modules.gaming = {
        steam = {
          enable = true;
          performance.gamemode = true;
          performance.mangohud = true;
        };
      };

      # Custom packages for this specific desktop
      environment.systemPackages = with pkgs; [
        # Add desktop-specific packages beyond preset defaults
        gimp
        inkscape
        blender
        obs-studio
      ];

      # Custom firewall rules for development
      networking.firewall.allowedTCPPorts = [ 3000 8000 8080 9000 ];
    };
  };

  # Host-specific hardware configuration would go here
  # (anything that can't be auto-detected)

  # Location for weather/timezone (optional)
  location = {
    latitude = 40.7128;
    longitude = -74.0060;
  };

  # The rest is handled by the preset!
  # No more 400+ lines of repetitive configuration
}
