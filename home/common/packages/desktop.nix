# Desktop Packages
# GUI applications for desktop environments
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; lib.mkDefault [
    # Web Browsers
    firefox # Open-source browser

    # Office and Productivity
    libreoffice # Office suite
    evince # PDF viewer

    # File Management
    nautilus # GNOME file manager (works in other DEs)

    # Media Players
    vlc # Video player

    # Graphics and Design
    gimp # Image editor
    inkscape # Vector graphics

    # Text Editors
    gedit # Simple GUI text editor

    # System Tools
    gnome-system-monitor # System monitor GUI

    # Archive Management
    file-roller # Archive manager

    # Communication
    # (Uncomment as needed)
    # thunderbird     # Email client
    # discord         # Chat application
    # slack           # Team communication

    # Development (GUI)
    # (Uncomment as needed)
    # vscode          # Code editor
    # gitg            # Git GUI
  ];

  # Desktop-specific program configurations
  programs = {
    # Note: File managers like thunar are typically configured at system level
    # Add user-level desktop programs here
  };
}
