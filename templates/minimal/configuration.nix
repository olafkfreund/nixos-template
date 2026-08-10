# System configuration. Everything here applies to the whole machine.
{ pkgs, ... }:

{
  imports = [
    # Generated for YOUR hardware -- do not copy this file between machines:
    #   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
    ./hardware-configuration.nix
  ];

  # ── Boot ──────────────────────────────────────────────────────────────────
  # UEFI. If this machine boots in legacy BIOS mode, swap these two lines for
  #   boot.loader.grub = { enable = true; device = "/dev/sda"; };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Identity ──────────────────────────────────────────────────────────────
  networking.hostName = "my-machine"; # must match the name in flake.nix
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Users ─────────────────────────────────────────────────────────────────
  # Set a password AFTER the first boot with `passwd me`; a password written
  # here would land in the world-readable Nix store.
  users.users.me = {
    isNormalUser = true;
    description = "Me";
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
    ];
  };

  # ── Packages ──────────────────────────────────────────────────────────────
  # System-wide: things root and rescue shells need. Everything personal goes
  # in home.nix instead. Never use `nix-env -i` -- it is invisible to this file
  # and survives rebuilds, which defeats the entire point of NixOS.
  environment.systemPackages = with pkgs; [
    git # needed to `nixos-rebuild --flake` at all
    vim
    curl
  ];

  # ── Services ──────────────────────────────────────────────────────────────
  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # ── Housekeeping ──────────────────────────────────────────────────────────
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Ignoring this is the most common new-user mistake: without it /nix/store
  # grows without bound and eventually fills the disk.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # Lets you run binaries that were not built for NixOS -- the FAQ's
  # "I downloaded a binary and it won't run". Costs nothing when unused.
  programs.nix-ld.enable = true;

  # The release you FIRST installed. Not a version to bump on upgrade --
  # it tells stateful services which on-disk format to expect. Leave it.
  system.stateVersion = "26.05";
}
