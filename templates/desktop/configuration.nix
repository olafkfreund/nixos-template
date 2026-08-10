# System configuration for a Wayland desktop.
{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ──────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Identity ──────────────────────────────────────────────────────────────
  networking.hostName = "my-desktop"; # must match the name in flake.nix
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # ── Desktop ───────────────────────────────────────────────────────────────
  # GNOME on Wayland. There is deliberately no `services.xserver.enable` --
  # GNOME is Wayland-only now, and enabling X11 would pull in a session you
  # will never log into.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # XWayland still runs older apps (Steam, some Electron) inside the Wayland
  # session. This is not an X11 session; it is a compatibility layer.
  programs.xwayland.enable = true;

  # ── Audio ─────────────────────────────────────────────────────────────────
  # PipeWire replaces PulseAudio and JACK. `pulseaudio.enable = false` is
  # required -- leaving both on gives you two sound servers fighting over the
  # device, which presents as "no sound" with nothing obviously wrong.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Graphics ──────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;

  # NVIDIA needs more than this -- uncomment and read the wiki page, it is the
  # single most common source of a black screen on first boot:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;

  # ── Users ─────────────────────────────────────────────────────────────────
  # Set the password after first boot with `passwd me`. Never write one here.
  users.users.me = {
    isNormalUser = true;
    description = "Me";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    firefox
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
  ];

  # Some packages (Steam, Discord, VS Code) are not free software and are
  # refused by default. This is the switch people hunt for.
  nixpkgs.config.allowUnfree = true;

  # ── Networking ────────────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ]; # a desktop serves nothing; add ports as needed
  };

  # ── Housekeeping ──────────────────────────────────────────────────────────
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # Run binaries that were not built for NixOS (SDKs, language version
  # managers, the servers VS Code downloads on connect).
  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";
}
