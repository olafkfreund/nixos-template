{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.gnome;
in
{
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Enable X11
    services.xserver = {
      enable = true;
    };

    # Display manager (updated path)
    services.displayManager.gdm = {
      enable = true;
      wayland = true; # Use Wayland by default
    };

    # Desktop environment (updated path)  
    services.desktopManager.gnome.enable = true;

    # GNOME services
    services.gnome = {
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
    };

    # Remove unwanted GNOME applications
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      epiphany # Web browser
      geary # Email
      totem # Video player
    ];

    # Essential GNOME applications
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnome-extension-manager
      dconf-editor
    ];

    # Enable thumbnails
    services.tumbler.enable = true;
  };
}
