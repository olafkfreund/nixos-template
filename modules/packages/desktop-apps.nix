# Desktop applications for workstation environments
# Web browsers, office suite, multimedia apps
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Web browsers
    firefox
    chromium

    # Office and productivity
    libreoffice
    thunderbird
    evince  # PDF viewer

    # File management
    nautilus
    file-roller

    # Media applications
    vlc
    audacity
    handbrake

    # Graphics and design
    gimp
    inkscape
    blender

    # System utilities with GUI
    gparted
  ];
}