# test-gaming Configuration - Preset-Based
# Generated using: just new-host test-gaming gaming
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/presets
  ];

  # System identification
  networking.hostName = "test-gaming";

  # Use gaming preset
  modules.presets = {
    enable = true;
    preset = "gaming";
  };

  # Host-specific customizations (override preset defaults)
  # Example:
  # environment.systemPackages = with pkgs; [ custom-package ];
  # services.myservice.enable = true;

  # Host-specific hardware configuration
  # Most hardware is auto-detected by the preset

  # Timezone (adjust for your location)
  time.timeZone = lib.mkDefault "Europe/London";

  system.stateVersion = "25.05";
}
