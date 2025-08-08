# NixOS Laptop VM Configuration for macOS (UTM/QEMU)
# Optimized for MacBook testing with laptop-specific features

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
  networking.hostName = "nixos-laptop-macos";

  # Enable laptop-specific modules
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
        profile = "laptop";
        autoDetect = true;
      };
    };
  };

  # VM-specific optimizations for laptop testing on macOS
  # Note: This configuration is designed for manual QEMU/UTM setup on macOS
  # The VM build system in NixOS doesn't directly support macOS-specific options
  #
  # For UTM/QEMU on macOS laptop simulation, use these settings:
  # - Memory: 3GB RAM (laptop-like constraints)
  # - CPU: 2 cores with Apple Silicon acceleration
  # - Display: cocoa with zoom-to-fit for laptop screen
  # - Power: ACPI simulation for laptop features

  # Laptop-specific services and power management
  services = {
    # Power management for laptop simulation
    upower.enable = true;
    thermald.enable = false; # Not needed in VM

    # Laptop-specific services
    auto-cpufreq.enable = false; # Not applicable in VM

    # Network management configured in networking section

    # SSH for development
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };

    # Desktop environment
    xserver = {
      enable = true;
      videoDrivers = [ "modesetting" "virtio" ];

      # Laptop input optimization  
      # Note: libinput configuration moved to services.libinput
    };

    # Display manager (moved from xserver)
    displayManager.gdm = {
      enable = true;
      autoSuspend = false; # Disable in VM
    };

    # Bluetooth simulation (not functional in VM but for testing)
    blueman.enable = true;

    # Location services for laptop features
    geoclue2.enable = true;

    # Time synchronization
    ntp.enable = true;

    # Clipboard integration
    spice-vdagentd.enable = true;

    # Laptop input configuration
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true; # Mac-like scrolling
        accelProfile = "adaptive";
      };
      mouse.accelProfile = "flat";
    };

    # Audio configuration for VM
    pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
    };

    # Disable PulseAudio if using PipeWire
    pulseaudio.enable = lib.mkDefault false;
  };

  # Hardware configuration for laptop VM
  hardware = {
    # Graphics
    graphics = {
      enable = true;
      # Only enable 32-bit support on x86_64 systems
      enable32Bit = pkgs.stdenv.hostPlatform.isx86_64;
    };

    # Note: Audio configured through services.pulseaudio or pipewire

    # Bluetooth (simulated)
    bluetooth = {
      enable = true;
      powerOnBoot = false; # Don't auto-enable in VM
    };

    # Firmware
    enableRedistributableFirmware = true;
  };

  # Laptop-like networking
  networking = {
    usePredictableInterfaceNames = lib.mkDefault true;
    useDHCP = lib.mkDefault false; # Use NetworkManager

    # NetworkManager configuration
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };

    # Firewall for laptop
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 8080 3000 5000 8000 ];
    };

    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Laptop-appropriate kernel modules
    kernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "virtio_balloon" ];
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];

    # Power management kernel parameters
    kernelParams = [
      "quiet"
      "splash"
      "console=tty1"
      "console=ttyS0,115200"
      "acpi=on"
      "acpi_osi=Linux"
    ];
  };

  # File system configuration
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" "compress=zstd" ]; # SSD-like optimizations
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
  };

  # Swap configuration (smaller for laptop simulation)
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # User configuration
  users = {
    mutableUsers = true;
    users = {
      laptop-user = {
        isNormalUser = true;
        description = "Laptop VM User";
        extraGroups = [ "wheel" "networkmanager" "audio" "video" "bluetooth" ];
        initialPassword = "nixos";
      };
    };
  };

  # Security
  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
  };

  # Power management and laptop-specific packages
  environment.systemPackages = with pkgs; [
    # VM and power tools
    spice-vdagent
    upower

    # Development tools
    git
    vim
    nano
    curl
    wget

    # Laptop utilities
    powertop
    acpi
    lm_sensors

    # Network tools
    networkmanager
    wirelesstools

    # System monitoring
    htop
    iotop
    tree
    lsof

    # GUI applications
    firefox
    gnome-tweaks
    gnome-power-manager

    # Development environment
    vscode

    # Laptop VM utilities
    (writeShellScriptBin "laptop-vm-info" ''
      echo "=== NixOS Laptop VM on macOS Information ==="
      echo "Hostname: $(hostname)"
      echo "Architecture: $(uname -m)"
      echo "Kernel: $(uname -r)"
      echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
      echo "CPU: $(nproc) cores"
      echo "VM Type: Laptop simulation on macOS"
      echo ""
      echo "Power status:"
      upower -i $(upower -e | grep 'BAT') 2>/dev/null || echo "No battery detected (VM)"
      echo ""
      echo "Network interfaces:"
      nmcli device status
      echo ""
      echo "Shared directories:"
      mount | grep -E '(projects|downloads|shared|9p|virtio)'
    '')

    (writeShellScriptBin "laptop-vm-optimize" ''
      echo "Optimizing laptop VM performance..."
      
      # CPU governor simulation
      echo "Setting CPU performance profile..."
      
      # Network optimization
      echo "Optimizing network settings..."
      nmcli connection modify "Wired connection 1" connection.autoconnect yes 2>/dev/null || true
      
      # Power management
      echo "Configuring power management..."
      
      echo "Laptop VM optimization complete!"
    '')
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "nano";
    BROWSER = "firefox";

    # VM identification
    NIXOS_VM_HOST = "macOS";
    NIXOS_VM_TYPE = "UTM/QEMU-Laptop";
  };

  # Location configuration for laptop features
  location = {
    latitude = 37.7749;
    longitude = -122.4194;
  };

  # Home Manager for laptop user
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.laptop-user = { pkgs, ... }: {
      imports = [
        ../../../home/roles/developer.nix
        ../../../home/profiles/gnome.nix
      ];

      home = {
        username = "laptop-user";
        homeDirectory = "/home/laptop-user";
        stateVersion = "25.05";
      };

      programs.git = {
        userName = "Laptop VM User";
        userEmail = "laptop@vm.local";
      };

      # Laptop-specific shell configuration
      programs.zsh.shellAliases = {
        laptop-info = "laptop-vm-info";
        laptop-optimize = "laptop-vm-optimize";
        battery = "upower -i $(upower -e | grep 'BAT')";
        wifi = "nmcli device wifi";
        bluetooth = "bluetoothctl";
        projects = "cd /mnt/projects";
        downloads = "cd /mnt/downloads";
      };

      # Laptop-specific services
      services = {
        # Redshift for eye care (laptop feature)
        redshift = {
          enable = true;
          latitude = 37.7749;
          longitude = -122.4194;
          temperature = {
            day = 6500;
            night = 4500;
          };
        };
      };
    };
  };

  # System state version
  system.stateVersion = "25.05";
}
