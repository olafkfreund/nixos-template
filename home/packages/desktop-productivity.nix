# Desktop productivity applications
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Web browsers
    firefox
    chromium

    # Office suite
    libreoffice
    evince

    # Email and communication
    thunderbird
    discord
    signal-desktop
    slack

    # Media and creativity
    gimp
    inkscape
    vlc
    audacity
    krita
    darktable

    # Graphics and design
    blender
    obs-studio

    # Cloud and sync
    rclone
    syncthing
  ];
}