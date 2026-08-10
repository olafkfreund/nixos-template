# niri Template -- a Wayland tiling desktop
#
# This host exists so the niri module is actually built. Before it, nothing in
# the repository enabled niri, so `nix flake check` never evaluated it and a
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
    baseName = "niri-template";
    profile = "workstation";
    description = "niri tiling desktop template";
    environment = "development";
    tags = [
      "template"
      "niri"
      "wayland"
    ];
  };

  modules = {
    desktop = {
      audio.enable = true;
      niri.enable = true;
    };

    hardware.power-management = {
      enable = true;
      profile = "desktop";
    };

    development.git.enable = true;
  };

  users.users.user = {
    isNormalUser = true;
    description = "niri User";
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
