# Server Template for VM Builder
# Headless server environment optimized for VMs
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

  # Server-optimized kernel
  boot.kernelParams = [
    "elevator=noop"
    "quiet"
    "console=tty0"
    "console=ttyS0,115200"
  ];

  # Essential server packages
  environment.systemPackages = with pkgs; [
    # System administration
    git
    curl
    wget
    vim
    nano
    htop
    tree
    unzip
    tmux
    screen

    # Network tools
    netcat
    nmap
    tcpdump
    dig

    # Server monitoring
    iotop
    iftop
    lsof
    strace

    # Container tools
    docker
    docker-compose

    # Security tools
    fail2ban

    # VM integration
    spice-vdagent
  ];

  # No desktop environment - headless server
  services.xserver.enable = false;

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
    ports = [ 22 ];
  };

  # Networking
  networking = {
    hostName = "nixos-server";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };

  # Users
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Server User";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    password = "nixos"; # Change this in production
    openssh.authorizedKeys.keys = [
      # Add your SSH keys here in production
    ];
  };

  # Server security - require password for sudo
  security.sudo.wheelNeedsPassword = true;

  # VM guest services
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;

    # Docker daemon
    docker = {
      enable = true;
      autoPrune.enable = true;
    };

    # System monitoring
    prometheus = {
      exporters = {
        node = {
          enable = true;
          port = 9100;
          openFirewall = false; # Manual firewall management
        };
      };
    };
  };

  # Disable services not needed in server VMs
  services.smartd.enable = false;
  powerManagement.enable = false;

  # VM-specific optimizations
  virtualisation = {
    diskSize = lib.mkDefault 40960; # 40GB
    memorySize = lib.mkDefault 2048; # 2GB
    cores = lib.mkDefault 2;

    # Minimal graphics for headless
    qemu.options = [
      "-vga cirrus"
      "-display none"
    ];
  };

  # Server-specific system settings
  boot.kernel.sysctl = {
    # Network optimizations
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 12582912 16777216";
    "net.ipv4.tcp_wmem" = "4096 12582912 16777216";

    # File system optimizations
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Enable flakes and new nix command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Server build optimization
    max-jobs = "auto";
    cores = 0;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Log management
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/**/*.log" = {
        rotate = 7;
        daily = true;
        missingok = true;
        compress = true;
        delaycompress = true;
        copytruncate = true;
      };
    };
  };
}
