{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.fonts;
in
{
  options.modules.desktop.fonts = {
    enable = lib.mkEnableOption "font configuration";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      # Enable font configuration
      fontconfig = {
        enable = true;

        # Better font rendering
        subpixel.rgba = "rgb";
        hinting.enable = true;
        hinting.style = "slight";
        antialias = true;

        # Default fonts
        defaultFonts = {
          serif = [ "Noto Serif" "Liberation Serif" ];
          sansSerif = [ "Noto Sans" "Liberation Sans" ];
          monospace = [ "JetBrains Mono" "Liberation Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };

      # Font packages
      packages = with pkgs; [
        # System fonts
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        liberation_ttf

        # Programming fonts
        jetbrains-mono
        fira-code
        source-code-pro

        # Popular fonts
        roboto
        open-sans
        ubuntu_font_family

        # Icon fonts
        font-awesome
        (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
      ];

      # Enable 32-bit font support
      enableGhostscriptFonts = true;
    };
  };
}
