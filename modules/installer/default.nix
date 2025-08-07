# Installer modules
# These are configurations for NixOS installers and live systems

{ ... }:

{
  imports = [
    ./base.nix
    ./minimal-installer.nix
    ./desktop-installer.nix
    ./preconfigured-installer.nix
  ];
}
