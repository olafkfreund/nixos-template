# Development Template for VM Builder
# Full development environment with programming tools and IDEs
{ config, pkgs, lib, ... }:

{
  imports = [
    # Enable VM optimizations
    <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
    <nixpkgs/nixos/modules/virtualisation/qemu-guest-agent.nix>
  ];

  # System configuration
  system.stateVersion = "24.05";

  # Boot configuration for VMs
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Development-optimized kernel
  boot.kernelParams = [
    "elevator=noop"
    "quiet"
    "splash"
  ];

  # Comprehensive development packages
  environment.systemPackages = with pkgs; [
    # System tools
    git
    curl
    wget
    vim
    nano
    htop
    tree
    unzip
    tmux
    zsh

    # Development essentials
    vscode
    neovim
    emacs

    # Programming languages
    nodejs_20
    python311
    python311Packages.pip
    python311Packages.virtualenv
    rustc
    cargo
    go
    openjdk17
    gcc
    clang

    # Development tools
    docker
    docker-compose
    kubernetes-helm
    kubectl
    terraform
    ansible

    # Version control
    gh # GitHub CLI
    gitui
    lazygit

    # Database tools
    postgresql
    mysql80
    redis
    mongodb
    sqlite

    # Network development
    postman
    httpie

    # Build tools
    cmake
    gnumake
    ninja
    meson

    # Desktop applications for development
    firefox
    thunderbird
    slack
    discord

    # Graphics and media (for UI development)
    gimp
    inkscape

    # VM integration
    spice-vdagent
  ];

  # Desktop environment for development
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Development-optimized video drivers
    videoDrivers = [ "vmware" "virtualbox" "qxl" ];
  };

  # Enable hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio for development (video calls, etc.)
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Networking with development ports
  networking = {
    hostName = "nixos-development";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 3000 5432 8080 8000 9000 ];
      allowedUDPPorts = [ ];
    };
  };

  # Development user with all necessary groups
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Development User";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" "video" ];
    password = "nixos"; # Change this in production
    shell = pkgs.zsh;
  };

  # Development-friendly sudo (passwordless for convenience)
  security.sudo.wheelNeedsPassword = false;

  # VM guest services
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;

    # Auto-login for development convenience
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };

    # Development services
    docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # Database services
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
    };

    redis.servers."".enable = true;

    # SSH for remote development
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };
  };

  # Development programs configuration
  programs = {
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "docker" "kubectl" "terraform" ];
        theme = "robbyrussell";
      };
    };

    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
        core.editor = "code --wait";
      };
    };
  };

  # Disable services not needed for development
  services.smartd.enable = false;
  powerManagement.enable = false;

  # VM-specific optimizations for development
  virtualisation = {
    diskSize = lib.mkDefault 61440; # 60GB for development projects
    memorySize = lib.mkDefault 8192; # 8GB RAM - increased for IDEs and containers
    cores = lib.mkDefault 6; # More cores for better compile performance

    # Graphics optimizations for IDEs
    qemu.options = [
      "-vga qxl"
      "-spice port=5930,disable-ticketing"
    ];
  };

  # Development-optimized system settings
  boot.kernel.sysctl = {
    # File watching limits for IDEs and build tools
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 8192;

    # Network optimizations for development
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;

    # Memory management for development workloads
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Enable flakes and optimize for development
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Development build optimization
    max-jobs = "auto";
    cores = 0;
    # Allow unfree packages for development tools
    allow-unfree = true;
    # Substituters for faster development
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # Conservative garbage collection for development
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Development-friendly fonts
  fonts.packages = with pkgs; [
    source-code-pro
    fira-code
    jetbrains-mono
    liberation_ttf
    dejavu_fonts
    noto-fonts
    noto-fonts-emoji
  ];

  # XDG portal for development tools
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Environment variables for development
  environment.variables = {
    EDITOR = "code";
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";
  };
}
