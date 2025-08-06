{ pkgs, lib, ... }:

{
  # User-specific packages for VirtualBox VM
  home.packages = with pkgs; [
    # Desktop applications
    firefox
    libreoffice

    # File management
    xfce.thunar
    xfce.thunar-volman

    # Text editors
    gedit
    mousepad

    # Media
    vlc

    # Development tools
    vscode
    git

    # Utilities
    htop
    neofetch
  ];

  # Program configurations
  programs = {
    # Git configuration
    git = {
      enable = true;
      userName = lib.mkDefault "VirtualBox User";
      userEmail = lib.mkDefault "vbox-user@example.com";
    };

    # Shell configuration
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        la = "ls -la";
        l = "ls -l";
        cls = "clear";
        ".." = "cd ..";
      };
    };

    # Firefox configuration for VM
    firefox = {
      enable = true;
      profiles.default = {
        name = "Default";
        isDefault = true;

        settings = {
          # Performance optimizations for VMs
          "gfx.webrender.enabled" = false; # Disable for VM compatibility
          "layers.acceleration.disabled" = true;

          # Privacy settings
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false;

          # Disable unnecessary features in VMs
          "geo.enabled" = false;
          "media.navigator.enabled" = false;
        };
      };
    };

    # XDG configuration
    xdg = {
      enable = true;

      # Default applications
      mimeApps.defaultApplications = {
        "text/plain" = [ "mousepad.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/pdf" = [ "firefox.desktop" ];
      };
    };

    # Desktop environment specific settings
    dconf.settings = {
      "org/xfce/desktop" = {
        backdrop = {
          screen0 = {
            monitor0 = {
              workspace0 = {
                last-image = "${pkgs.xfce.xfce4-artwork}/share/pixmaps/xfce-blue.jpg";
              };
            };
          };
        };
      };
    };

    # Services
    services = {
      # Redshift for eye strain
      redshift = {
        enable = true;
        latitude = 40.0; # Adjust to your location
        longitude = -74.0; # Adjust to your location
      };
    };

    # Home Manager state version
    home.stateVersion = "25.05";
  }
