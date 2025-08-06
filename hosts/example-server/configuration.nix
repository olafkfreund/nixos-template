{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Hardware configuration (generate with nixos-generate-config)
    ./hardware-configuration.nix

    # Core modules only (no desktop)
    ../../modules/core
    ../../modules/development

    # Hardware support
    ../../modules/hardware
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Hostname
  networking.hostName = "example-server";

  # Enable server modules
  modules = {
    development = {
      git = {
        enable = true;
        userName = "Server Admin";
        userEmail = "admin@example.com";
      };
    };

    # GPU Configuration for AI/Compute workloads
    hardware.gpu = {
      # Auto-detect GPUs (recommended)
      autoDetect = true;
      profile = "ai-compute"; # Optimized for AI/ML workloads

      # Manual GPU selection for AI/Compute (uncomment the one you have)

      # AMD GPU for AI/Compute (ROCm)
      # amd = {
      #   enable = true;
      #   model = "auto";  # auto, rdna3, rdna2, rdna1, vega
      #   compute = {
      #     enable = true;
      #     rocm = true;      # ROCm platform for AI
      #     openCL = true;    # OpenCL support
      #     hip = true;       # HIP runtime
      #   };
      #   powerManagement = {
      #     enable = true;
      #     profile = "high";  # High performance for compute
      #   };
      # };

      # NVIDIA GPU for AI/Compute (CUDA)
      # nvidia = {
      #   enable = true;
      #   driver = "stable";  # Use stable driver for servers
      #   hardware = {
      #     model = "auto";  # auto, rtx40, rtx30, rtx20
      #     powerLimit = null;  # Set power limit in watts (e.g., 300)
      #   };
      #   compute = {
      #     enable = true;
      #     cuda = true;         # CUDA toolkit
      #     cudnn = true;        # cuDNN for deep learning
      #     tensorrt = true;     # TensorRT for inference
      #     containers = true;   # NVIDIA container runtime
      #     mig = false;         # Multi-Instance GPU (for A100, H100)
      #   };
      #   professional = {
      #     enable = true;       # Professional features
      #   };
      # };

      # Intel Arc/Xe for AI/Compute (OneAPI)
      # intel = {
      #   enable = true;
      #   generation = "arc";  # arc, xe for compute workloads
      #   compute = {
      #     enable = true;
      #     oneapi = true;       # Intel OneAPI toolkit
      #     opencl = true;       # OpenCL support
      #     level_zero = true;   # Level Zero API
      #   };
      # };

      # Multi-GPU compute setup
      # multiGpu = {
      #   enable = true;
      #   primary = "nvidia";  # Primary for management
      # };
    };
  };

  # Server users
  users.users.server-admin = {
    isNormalUser = true;
    description = "Server Administrator";
    extraGroups = [
      "wheel" # sudo access
      "docker" # container access (if enabled)
      "video" # GPU access
      "render" # compute access
    ];

    # Use SSH keys for authentication
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAA... user@host"
    ];

    # No password login for security
    hashedPassword = "!";
  };

  # Home Manager configuration for server admin
  home-manager.users.server-admin = import ./home.nix;

  # Server-specific services
  services = {
    # SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
      };
    };

    # Monitoring
    prometheus = {
      enable = lib.mkDefault false; # Enable if you want monitoring
    };

    # Container runtime (for AI workloads)
    docker = {
      enable = lib.mkDefault false; # Enable if needed
      enableOnBoot = true;
    };
  };

  # Network configuration for servers
  networking = {
    # Use NetworkManager for flexibility, or configure static IPs
    networkmanager.enable = lib.mkDefault true;

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        # 8080  # Add application ports as needed
      ];
      allowPing = true;
    };

    # Server networking optimizations
    kernel.sysctl = {
      # Network performance tuning
      "net.core.rmem_max" = 268435456;
      "net.core.wmem_max" = 268435456;
      "net.ipv4.tcp_rmem" = "4096 65536 268435456";
      "net.ipv4.tcp_wmem" = "4096 65536 268435456";

      # For high-performance computing
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # Hardware optimizations for servers
  hardware = {
    # Enable firmware
    enableRedistributableFirmware = true;

    # CPU microcode
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # Boot configuration for servers
  boot = {
    # Use GRUB for better compatibility
    loader = {
      grub = {
        enable = lib.mkDefault true;
        device = lib.mkDefault "/dev/sda"; # Adjust for your setup
        timeout = 5;
      };

      # Disable systemd-boot for servers
      systemd-boot.enable = lib.mkForce false;
    };

    # Server kernel parameters
    kernelParams = [
      "quiet"
      "loglevel=3"

      # Memory management for large datasets
      "transparent_hugepage=always"

      # CPU isolation for compute workloads (optional)
      # "isolcpus=2-7"  # Isolate CPUs 2-7 for compute tasks
    ];

    # Kernel modules for server hardware
    kernelModules = [
      "kvm-intel" # or kvm-amd
    ];
  };

  # System packages for server management
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    iotop
    nethogs

    # Network tools
    netcat
    socat
    nmap

    # Container tools (if using containers)
    docker-compose

    # File transfer
    rsync

    # Text processing
    jq
    yq

    # System utilities
    screen
    tmux
    vim

    # GPU monitoring (added automatically based on GPU selection)
    nvtop # Works with both NVIDIA and AMD
  ];

  # Virtualization support (for VMs or containers)
  virtualisation = {
    # Enable KVM
    libvirtd.enable = lib.mkDefault false; # Enable if needed

    # Docker configuration
    docker = lib.mkIf config.services.docker.enable {
      enableOnBoot = true;

      # NVIDIA container support (enabled automatically if NVIDIA GPU is detected)
      enableNvidia = config.modules.hardware.gpu.nvidia.enable;

      # Docker daemon configuration
      daemon.settings = {
        # Logging configuration
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };

        # Storage optimization
        storage-driver = "overlay2";
      };
    };
  };

  # Power management (disabled for servers by default)
  powerManagement = {
    enable = false;
  };

  # Disable unnecessary services for servers
  services = {
    # No power management services
    thermald.enable = false;
    tlp.enable = false;

    # No desktop services
    avahi.enable = false;

    # Minimal logging for performance
    journald.extraConfig = ''
      SystemMaxUse=1G
      RuntimeMaxUse=500M
    '';
  };

  # Security hardening for servers
  security = {
    # Stricter sudo configuration
    sudo.wheelNeedsPassword = true;

    # Audit framework
    audit.enable = true;
    auditd.enable = true;
  };

  # System state version
  system.stateVersion = "25.05";
}
