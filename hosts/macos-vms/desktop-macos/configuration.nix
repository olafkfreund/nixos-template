# NixOS Desktop VM Configuration for macOS (UTM/QEMU)
# Optimized for Apple Silicon (aarch64) and Intel Macs (x86_64)

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ../../../modules/core
    ../../../modules/desktop
    ../../../modules/development
    ../../../modules/hardware
    ../../../modules/services
  ];

  # System identification
  networking.hostName = "nixos-desktop-macos";

  # Enable desktop environment
  modules = {
    desktop = {
      gnome.enable = true;
      audio.enable = true;
      fonts.enable = true;
    };

    development = {
      git.enable = true;
    };

    hardware = {
      gpu = {
        profile = "desktop";
        # Auto-detect will work for VM graphics
        autoDetect = true;
      };
    };
  };

  # VM-specific optimizations for macOS hosts
  # Note: This configuration is designed for manual QEMU/UTM setup on macOS
  # The VM build system in NixOS doesn't directly support macOS-specific options
  # 
  # For UTM/QEMU on macOS, use these recommended settings:
  # - Memory: 4GB RAM
  # - CPU: 4 cores with Apple Silicon acceleration (-machine virt,accel=hvf)
  # - Graphics: virtio-vga with cocoa display
  # - Audio: coreaudio support
  # - Network: vmnet-host for best performance

  # macOS VM-specific services and optimizations
  services = {
    # X11 forwarding for better GUI integration
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      ports = [ 22 ];
    };

    # Desktop services
    xserver = {
      enable = true;

      # Optimize for VM display
      videoDrivers = [ "modesetting" "virtio" ];

      # Input optimization moved to services.libinput
    };

    # Display manager (moved from xserver)
    displayManager.gdm = {
      enable = true;
      autoSuspend = false; # Don't suspend in VM
    };

    # Clipboard integration with macOS host
    spice-vdagentd.enable = true;

    # Input optimization for macOS hosts
    libinput = {
      enable = true;
      mouse.accelProfile = "flat";
      touchpad.accelProfile = "adaptive";
    };

    # Time synchronization with host
    ntp.enable = true;

    # Audio configuration for VM
    pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };

    # Disable PulseAudio if using PipeWire
    pulseaudio.enable = lib.mkDefault false;
  };

  # Hardware optimizations for VM
  hardware = {
    # Graphics support
    graphics = {
      enable = true;
      # Only enable 32-bit support on x86_64 systems
      enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    };

    # Note: Audio configured through services.pulseaudio or pipewire

    # USB support for guest additions
    enableRedistributableFirmware = true;
  };

  # Networking optimized for macOS VM
  networking = {
    # Use predictable interface names
    usePredictableInterfaceNames = lib.mkDefault true;

    # DHCP for VM networking (can be overridden by NetworkManager)
    useDHCP = lib.mkDefault true;

    # Firewall configuration for VM
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 8080 3000 ]; # Common development ports
    };

    # DNS configuration
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  # Boot configuration for VM
  boot = {
    # Use systemd-boot for UEFI
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Kernel modules for VM
    kernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];

    # Optimize boot for VM
    kernelParams = [
      "quiet"
      "splash"
      "console=tty1"
      "console=ttyS0,115200"
    ];
  };

  # File systems optimized for VM
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  # Swap configuration
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # User configuration for VM testing
  users = {
    mutableUsers = true;
    users = {
      nixos = {
        isNormalUser = true;
        description = "NixOS VM User";
        extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
        initialPassword = "nixos"; # Change after first login
      };
    };
  };

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = false; # Convenient for VM testing
    polkit.enable = true;
  };

  # VM-specific packages
  environment.systemPackages = with pkgs; [
    # VM guest tools and utilities
    spice-vdagent

    # Development tools
    git
    vim
    nano
    curl
    wget

    # System utilities
    htop
    tree
    lsof

    # Network tools
    netcat
    nmap

    # GUI applications for testing
    firefox
    gnome-tweaks

    # Development environment
    vscode

    # Utilities for macOS integration
    (writeShellScriptBin "vm-info" ''
      echo "=== NixOS VM on macOS Information ==="
      echo "Hostname: $(hostname)"
      echo "Architecture: $(uname -m)"
      echo "Kernel: $(uname -r)"
      echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
      echo "CPU: $(nproc) cores"
      echo "VM Optimizations: UTM/QEMU on macOS"
      echo ""
      echo "Network interfaces:"
      ip addr show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':'
      echo ""
      echo "Shared directories:"
      mount | grep -E '(shared|9p|virtio)'
    '')
  ];

  # Environment variables for VM
  environment.variables = {
    EDITOR = "nano";
    BROWSER = "firefox";

    # VM identification
    NIXOS_VM_HOST = "macOS";
    NIXOS_VM_TYPE = "UTM/QEMU";
  };

  # Home Manager configuration for VM user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = { pkgs, ... }: {
      # Import role-based configuration
      imports = [
        ../../../home/roles/developer.nix
        ../../../home/profiles/gnome.nix
      ];

      # User identification
      home = {
        username = "nixos";
        homeDirectory = "/home/nixos";
        stateVersion = "25.05";
      };

      # Git configuration (users should change this)
      programs.git = {
        userName = "NixOS VM User";
        userEmail = "nixos@vm.local";
      };

      # VM-specific shell configuration
      programs.zsh.shellAliases = {
        vm-info = "vm-info";
        vm-ip = "hostname -I | awk '{print $1}'";
        shared = "cd /mnt/shared";
      };
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
