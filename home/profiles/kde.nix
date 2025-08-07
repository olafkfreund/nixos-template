{ config, pkgs, ... }:

{
  # KDE-specific Home Manager configuration

  # KDE applications
  home.packages = with pkgs; [
    # KDE applications
    kate
    dolphin
    konsole
    spectacle
    gwenview
    okular
    ark
    kfind
    kcalc

    # KDE development
    kdePackages.kdevelop

    # Multimedia
    kdePackages.kdenlive
    kdePackages.krita
  ];

  # KDE Connect
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # Qt/KDE theming (updated for newer NixOS versions)
  qt = {
    enable = true;
    platformTheme = "kde6";
    style = "breeze";
  };

  # KDE-specific configurations
  programs = {
    # Konsole terminal configuration
    konsole = {
      enable = true;
      profiles = {
        default = {
          name = "Default";
          colorScheme = "Breeze";
          font = {
            name = "JetBrains Mono";
            size = 11;
          };
        };
      };
    };
  };

  # Plasma desktop configuration (via plasma-manager if available)
  # programs.plasma = {
  #   enable = true;
  #   
  #   workspace = {
  #     lookAndFeel = "org.kde.breezedark.desktop";
  #     theme = "breeze-dark";
  #   };
  #   
  #   panels = [
  #     {
  #       location = "bottom";
  #       height = 44;
  #     }
  #   ];
  # };

  # KDE session variables
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "kde";
    KDEHOME = "${config.home.homeDirectory}/.kde";
  };
}
