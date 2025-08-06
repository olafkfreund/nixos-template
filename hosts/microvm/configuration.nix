{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Hardware configuration (generate with nixos-generate-config)
    ./hardware-configuration.nix

    # Virtualization modules
    ../../modules/virtualization

    # Core modules only (minimal)
    ../../modules/core
  ];

  # Hostname
  networking.hostName = "microvm";

  # Enable MicroVM optimizations (aggressive minimization)
  modules.virtualization.microvm = {
    enable = true;
    minimizeSize = true;
    disableDocumentation = true;
    useMinimalKernel = true;
  };

  # Minimal user setup
  users.users.micro = {
    isNormalUser = true;
    description = "MicroVM User";
    extraGroups = [ "wheel" ];

    # Use SSH key authentication only
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAA... user@host"
    ];

    # No password login
    hashedPassword = "!";
  };

  # Allow wheel group to sudo without password (secure with SSH keys)
  security.sudo.wheelNeedsPassword = false;

  # Minimal services
  services = {
    # SSH only for remote access (no local login)
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        Protocol = 2;
      };

      # Only ED25519 host key for minimal footprint
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };

  # Minimal network configuration
  networking = {
    # Use systemd-networkd (lighter than NetworkManager)
    useNetworkd = true;
    useDHCP = false;

    # Minimal firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH only
      allowPing = true;

      # Drop all other traffic
      extraCommands = ''
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
      '';
    };

    # No IPv6 to reduce overhead
    enableIPv6 = false;
  };

  # Single interface configuration
  systemd.network = {
    enable = true;

    networks."10-eth" = {
      matchConfig.Name = "eth* en*";
      networkConfig = {
        DHCP = "yes";
        IPv4Forwarding = false;
        IPv6Forwarding = false;
      };
      dhcpV4Config = {
        RouteMetric = 1024;
      };
    };
  };

  # Minimal boot configuration
  boot = {
    # Use systemd-boot for speed
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3; # Keep only 3 generations
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0; # No boot menu delay
    };

    # Minimal kernel
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # Aggressive kernel parameters for minimal footprint
    kernelParams = [
      "quiet"
      "loglevel=1"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=1"

      # Memory optimizations
      "transparent_hugepage=never"
      "mem_sleep_default=s2idle"

      # Disable unnecessary features
      "nmi_watchdog=0"
      "nowatchdog"
      "processor.ignore_ppc=1"

      # Fast boot
      "elevator=noop"
      "clocksource=tsc"
      "no_timer_check"
    ];

    # Minimal initrd
    initrd = {
      systemd.enable = true;
      verbose = false;

      # Only essential modules
      availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_net"
      ];

      # Aggressive compression
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
    };
  };

  # Minimal system packages
  environment = {
    # Essential packages only
    systemPackages = with pkgs; [
      # System utilities
      util-linux
      coreutils
      findutils

      # Network
      iproute2
      iputils

      # Text editing
      nano

      # Process management
      procps
      psmisc
    ];

    # Minimal variables
    variables = {
      EDITOR = "nano";
      PAGER = "cat";
    };

    # Remove default packages
    defaultPackages = [ ];
  };

  # Disable all unnecessary systemd services
  systemd.services = {
    # Disable network time sync (use simple time sync instead)
    systemd-timesyncd.enable = false;

    # Disable USB automount
    udisks2.enable = false;

    # Disable log rotation (logs are in memory anyway)
    logrotate.enable = false;
  };

  # Minimal documentation
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  # Aggressive Nix configuration
  nix = {
    settings = {
      # Minimal substituters
      substituters = [ "https://cache.nixos.org/" ];

      # Aggressive optimization
      auto-optimise-store = true;
      min-free = 128 * 1024 * 1024; # 128MB
      max-free = 256 * 1024 * 1024; # 256MB
    };

    # Aggressive garbage collection
    gc = {
      automatic = true;
      dates = "hourly";
      options = "--delete-older-than 1d";
    };
  };

  # No swap at all
  swapDevices = [ ];
  zramSwap.enable = false;

  # Minimal hardware configuration
  hardware = {
    # No firmware updates
    enableRedistributableFirmware = false;

    # No graphics needed
    graphics.enable = false;
  };

  # Disable power management
  powerManagement.enable = false;
  services.thermald.enable = false;
  services.tlp.enable = false;

  # Minimal console setup
  console = {
    earlySetup = true;
    keyMap = lib.mkForce "us";
    font = lib.mkForce "Lat2-Terminus16";
  };

  # System state version
  system.stateVersion = "25.05";
}
