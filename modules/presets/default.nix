# Presets Module
# High-level configuration presets that eliminate boilerplate
{ config, lib, ... }:

let
  cfg = config.modules.presets;
in

{
  imports = [
    ./workstation.nix
    ./laptop.nix
    ./server.nix
    ./vm.nix
    ./gaming.nix
  ];

  options.modules.presets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable preset configurations";
    };

    preset = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "workstation"
        "laptop"
        "server"
        "gaming"
        "vm-guest"
        "developer"
      ]);
      default = null;
      description = "The system preset to use";
    };

  };

  config = lib.mkIf cfg.enable {
    # Preset configurations are handled by individual preset modules
    # based on the preset option

    assertions = [
      {
        assertion = cfg.preset != null;
        message = "modules.presets.preset must be set when presets are enabled";
      }
    ];
  };
}
