# Minimal installer ISO configuration  
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ../../modules/installer/minimal-installer.nix
  ];

  # Keep it truly minimal - just add essential template support
  environment.systemPackages = with pkgs; [
    # Template tools
    just

    # Essential development
    git
  ];

  # Include template for reference
  environment.etc."nixos-template" = {
    source = ../..; # Root of this repository (from hosts/installer-isos/)
    mode = "0755";
  };
}
