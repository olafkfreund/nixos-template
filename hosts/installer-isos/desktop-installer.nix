# Desktop installer ISO configuration
{ pkgs, ... }:

{
  imports = [
    ../../modules/installer/desktop-installer.nix
  ];

  # Additional customizations for desktop installer ISO
  environment.systemPackages = with pkgs; [
    # Include template management tools
    just
    nixpkgs-fmt

    # Additional desktop tools
    firefox
    gnome-tweaks

    # Development
    vscode
    git
  ];

  # Include a copy of this template on the ISO
  environment.etc."nixos-template" = {
    source = ../..; # Root of this repository (from hosts/installer-isos/)
    mode = "0755";
  };

  # Desktop launcher for template browser
  environment.etc."xdg/applications/nixos-template.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=NixOS Template Browser
      Comment=Browse available NixOS configurations
      Exec=nautilus /etc/nixos-template
      Icon=folder
      Categories=System;
    '';
  };
}
