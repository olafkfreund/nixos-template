# Preconfigured installer ISO configuration
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ../../modules/installer/preconfigured-installer.nix
  ];

  # This is the full-featured installer with all templates ready to use
  # Additional customizations can be added here
}
