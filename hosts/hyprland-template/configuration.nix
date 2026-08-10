# Hyprland Template -- a Wayland tiling desktop
#
# This host exists so the hyprland module is actually built. Before it, nothing in
# the repository enabled hyprland, so `nix flake check` never evaluated it and a
# broken profile could sit unnoticed.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/power-management.nix
    ../../modules/development
  ];

  systemId = {
    baseName = "hyprland-template";
    profile = "workstation";
    description = "Hyprland tiling desktop template";
    environment = "development";
    tags = [
      "template"
      "hyprland"
      "wayland"
    ];
  };

  modules = {
    desktop = {
      audio.enable = true;
      hyprland.enable = true;
    };

    hardware.power-management = {
      enable = true;
      profile = "desktop";
    };

    development.git.enable = true;
  };

  users.users.user = {
    isNormalUser = true;
    description = "Hyprland User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];
    group = "users";
  };

  home-manager.users.user = import ./home.nix;
}
