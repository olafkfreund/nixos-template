{ config, lib, pkgs, ... }:

{
  # GNOME-specific Home Manager configuration

  # GNOME applications
  home.packages = with pkgs; [
    # Core GNOME apps
    gnome-tweaks
    gnome-extension-manager
    dconf-editor
    
    # Additional GNOME apps
    gnome-calculator
    gnome-calendar
    gnome-weather
    gnome-maps
    gnome-music
    gnome-photos
    
    # Extensions
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.user-themes
    gnomeExtensions.vitals
    gnomeExtensions.blur-my-shell
    gnomeExtensions.clipboard-indicator
  ];

  # GTK theming
  gtk = {
    enable = true;
    
    theme = {
      package = pkgs.adwaita-qt;
      name = "Adwaita-dark";
    };
    
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    
    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };
    
    font = {
      name = "Inter";
      size = 11;
    };
    
    gtk2.extraConfig = ''
      gtk-application-prefer-dark-theme=1
    '';
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # GNOME dconf settings
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
    
    "org/gnome/desktop/wm/preferences" = {
      theme = "Adwaita-dark";
      titlebar-font = "Inter Bold 11";
    };
    
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "Vitals@CoreCoding.com"
        "blur-my-shell@aunetx"
        "clipboard-indicator@tudmotu.com"
      ];
      
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.gnome.Console.desktop"
        "org.gnome.TextEditor.desktop"
        "code.desktop"
      ];
    };
    
    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = false;
      custom-theme-shrink = false;
      dock-position = "BOTTOM";
      height-fraction = 0.9;
      preferred-monitor = -2;
      show-mounts = false;
    };
    
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      natural-scroll = false;
    };
    
    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = true;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };
    
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "gnome-terminal";
      name = "Open Terminal";
    };
    
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = false;
    };
  };

  # GNOME session variables
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
  };
}