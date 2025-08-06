{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.graphics;
in
{
  options.modules.desktop.graphics = {
    enable = lib.mkEnableOption "desktop graphics support";
  };

  config = lib.mkIf cfg.enable {
    # Hardware graphics support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;  # 32-bit support for compatibility
      
      # Common graphics packages
      extraPackages = with pkgs; [
        mesa.drivers
        
        # Video acceleration
        libva
        libva-utils
        
        # Vulkan support
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
      ];
    };
    
    # Graphics utilities
    environment.systemPackages = with pkgs; [
      # Graphics info tools
      glxinfo
      vulkan-tools
      libva-utils
      
      # Image viewers and editors
      gimp
      inkscape
      
      # Video tools
      vlc
      mpv
    ];
  };
}