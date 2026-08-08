{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.gnome;
in
{
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # No `services.xserver.enable` here: GNOME 50 is Wayland-only, so an X
    # server session is dead weight. XWayland is enabled explicitly instead, so
    # X11-only apps (Steam, Discord, older Electron) still run.
    programs.xwayland.enable = true;

    # Display manager. GNOME 50 is Wayland-only, so `gdm.wayland` is gone —
    # setting it is now a hard error rather than a no-op.
    services.displayManager.gdm.enable = true;

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
      showtime # Video player (replaced totem in GNOME 48+)
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
