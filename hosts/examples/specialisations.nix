# Specialisations: extra boot entries built from the same configuration.
#
# A specialisation is a variant of your system that gets its own entry in the
# boot menu. Both variants are built and stored; you choose at boot. If the
# variant is broken you reboot into the default and nothing is lost -- which
# makes this the safest way to try a change that could stop the machine
# reaching a login prompt.
#
# The two cases below are the ones people actually hit. Import this file from
# a host's configuration.nix and delete whichever you do not want:
#
#   imports = [ ../examples/specialisations.nix ];
#
# Switch without rebooting (activation only, does not change the boot default):
#
#   sudo /run/current-system/specialisation/nvidia-sync/bin/switch-to-configuration test
{ lib, ... }:

{
  # ── Hybrid graphics: battery life by default, full GPU on demand ──────────
  #
  # On a laptop with both integrated and discrete graphics, running the NVIDIA
  # card constantly costs several watts. Offload mode keeps it powered down and
  # routes individual programs to it with `nvidia-offload <command>`; sync mode
  # drives the display from it entirely, which is what you want for gaming or
  # an external monitor wired directly to the discrete GPU.
  #
  # Requires `hardware.nvidia.prime.*BusId` to be set for your machine; find
  # them with `lspci | grep -E 'VGA|3D'` and convert e.g. 01:00.0 to PCI:1:0:0.
  specialisation.nvidia-sync.configuration = {
    system.nixos.tags = [ "nvidia-sync" ];

    hardware.nvidia.prime = {
      # mkForce because the default configuration sets offload; the module
      # rejects having both offload and sync enabled at once.
      offload.enable = lib.mkForce false;
      offload.enableOffloadCmd = lib.mkForce false;
      sync.enable = true;
    };
  };

  # ── A known-good fallback entry ───────────────────────────────────────────
  #
  # Boots the same system with the graphical session and any out-of-tree
  # drivers left out. Worth keeping on a machine you rely on: when a GPU
  # driver update leaves you at a black screen, this is the entry that still
  # gets you to a shell to roll back from -- without needing install media.
  #
  # Generations already give you rollback, but only to a PREVIOUS build. This
  # covers the case where the current build is broken in a way you can predict
  # (drivers, display manager) rather than one you have to guess at.
  specialisation.rescue.configuration = {
    system.nixos.tags = [ "rescue" ];

    services.xserver.enable = lib.mkForce false;
    services.displayManager.gdm.enable = lib.mkForce false;
    services.desktopManager.gnome.enable = lib.mkForce false;

    # Land on a text console with networking, so you can ssh in or `nixos-
    # rebuild --rollback` locally.
    systemd.defaultUnit = lib.mkForce "multi-user.target";

    # Keep it obvious which one you booted.
    environment.etc."issue".text = ''
      *** RESCUE specialisation -- graphical session disabled ***
      Roll back with: sudo nixos-rebuild switch --rollback

    '';
  };
}
