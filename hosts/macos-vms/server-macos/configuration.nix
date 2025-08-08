# NixOS Server VM Configuration for macOS (UTM/QEMU)
# Headless server configuration optimized for development and testing

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../common.nix
    ../../../modules/core
    ../../../modules/development
    ../../../modules/hardware
    ../../../modules/services
    ../../../modules/virtualization
  ];

  # System identification
  networking.hostName = "nixos-server-macos";

  # Server-specific module configuration
  modules = {
    development = {
      git.enable = true;
    };

    hardware = {
      gpu = {
        profile = "server-compute";
        autoDetect = false;  # No GPU needed for headless server
      };
    };

    # Note: Podman and Docker configured at system level in services section
  };

  # VM configuration optimized for server workloads
  # Note: This configuration is designed for manual QEMU/UTM setup on macOS
  # The VM build system in NixOS doesn't directly support macOS-specific options
  #
  # For UTM/QEMU on macOS server setup, use these settings:
  # - Memory: 2GB RAM (server baseline)
  # - CPU: 2 cores with Apple Silicon acceleration
  # - Display: headless operation (-nographic)
  # - Network: vmnet-host for development access

  # Server services configuration
  services = {
    # SSH server (primary interface)
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        X11Forwarding = false;  # No X11 for headless server
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };
      ports = [ 22 ];
    };

    # Web server for development
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      
      # Default server block
      virtualHosts."localhost" = {
        listen = [
          { addr = "0.0.0.0"; port = 80; }
          { addr = "0.0.0.0"; port = 8080; }
        ];
        locations."/" = {
          return = "200 'NixOS Server VM on macOS is running!'";
          extraConfig = "add_header Content-Type text/plain;";
        };
      };
    };

    # Database services
    postgresql = {
      enable = true;
      ensureDatabases = [ "development" "testing" ];
      ensureUsers = [
        {
          name = "developer";
          ensurePermissions = {
            "DATABASE development" = "ALL PRIVILEGES";
            "DATABASE testing" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    redis = {
      servers.main = {
        enable = true;
        port = 6379;
        bind = "127.0.0.1";
      };
    };

    # Container registry
    dockerRegistry = {
      enable = false;  # Enable if needed for container development
    };

    # Monitoring
    prometheus = {
      enable = true;
      port = 9090;
      listenAddress = "0.0.0.0";
      
      scrapeConfigs = [
        {
          job_name = "nixos-server";
          static_configs = [
            { targets = [ "localhost:9100" ]; }
          ];
        }
      ];
    };

    prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "0.0.0.0";
    };

    # Log management
    journald.extraConfig = ''
      SystemMaxUse=1G
      RuntimeMaxUse=100M
    '';

    # Time synchronization
    ntp.enable = true;

    # Container runtime
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    
    # Disable unneeded services for headless
    xserver.enable = false;
    displayManager.gdm.enable = false;
  };

  # Server hardware configuration
  hardware = {
    # Minimal graphics
    graphics = {
      enable = false;  # Headless server
    };
    
    # No audio
    pulseaudio.enable = false;
    
    # No Bluetooth
    bluetooth.enable = false;
    
    # Firmware
    enableRedistributableFirmware = true;
  };

  # Server networking
  networking = {
    usePredictableInterfaceNames = true;
    useDHCP = lib.mkDefault true;
    
    # Server firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        22    # SSH
        80    # HTTP
        443   # HTTPS
        8080  # Alternative HTTP
        3000  # Development server
        5000  # Flask/development
        8000  # Python development
        9090  # Prometheus
        9100  # Node exporter
        5432  # PostgreSQL
        6379  # Redis
      ];
      
      # Additional ports for container services
      allowedTCPPortRanges = [
        { from = 8000; to = 8999; }  # Development services
      ];
    };
    
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  # Boot configuration for headless server
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # Server kernel modules
    kernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "virtio_console" ];
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];
    
    # Server boot parameters
    kernelParams = [
      "console=ttyS0,115200"
      "console=tty1"
      "systemd.unified_cgroup_hierarchy=1"
    ];
  };

  # File system configuration
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];  # Server optimization
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

  # Server users
  users = {
    mutableUsers = true;
    users = {
      server-admin = {
        isNormalUser = true;
        description = "Server Administrator";
        extraGroups = [ "wheel" "docker" "systemd-journal" ];
        initialPassword = "nixos";
        openssh.authorizedKeys.keys = [
          # Add SSH public keys here for key-based authentication
        ];
      };
    };
  };

  # Security configuration
  security = {
    sudo = {
      wheelNeedsPassword = false;  # For VM testing convenience
    };
    polkit.enable = true;
  };

  # Server packages
  environment.systemPackages = with pkgs; [
    # System administration
    htop
    iotop
    nethogs
    iftop
    lsof
    tree
    
    # Network tools
    curl
    wget
    netcat
    nmap
    tcpdump
    
    # Development tools
    git
    vim
    nano
    tmux
    
    # Container tools
    podman
    podman-compose
    skopeo
    buildah
    
    # Database tools
    postgresql
    redis
    
    # Monitoring tools
    prometheus
    
    # System utilities
    rsync
    unzip
    jq
    yq
    
    # Server utilities
    (writeShellScriptBin "server-status" ''
      echo "=== NixOS Server VM on macOS Status ==="
      echo "Hostname: $(hostname)"
      echo "Uptime: $(uptime -p)"
      echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
      echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
      echo ""
      echo "Services:"
      systemctl is-active nginx && echo "  ✓ Nginx (Port 80, 8080)"
      systemctl is-active postgresql && echo "  ✓ PostgreSQL (Port 5432)"
      systemctl is-active redis && echo "  ✓ Redis (Port 6379)"
      systemctl is-active prometheus && echo "  ✓ Prometheus (Port 9090)"
      echo ""
      echo "Network:"
      echo "  IP: $(hostname -I | awk '{print $1}')"
      echo "  SSH: ssh server-admin@$(hostname -I | awk '{print $1}')"
      echo ""
      echo "Containers:"
      podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  No containers running"
    '')
    
    (writeShellScriptBin "server-logs" ''
      case "$1" in
        nginx)
          journalctl -u nginx -f
          ;;
        postgresql)
          journalctl -u postgresql -f
          ;;
        redis)
          journalctl -u redis -f
          ;;
        prometheus)
          journalctl -u prometheus -f
          ;;
        *)
          echo "Usage: server-logs [nginx|postgresql|redis|prometheus]"
          echo "Available services:"
          systemctl list-units --type=service --state=running | grep -E "(nginx|postgresql|redis|prometheus)"
          ;;
      esac
    '')
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "vim";
    
    # Server identification
    NIXOS_VM_HOST = "macOS";
    NIXOS_VM_TYPE = "UTM/QEMU-Server";
    
    # Development environment
    PGHOST = "localhost";
    PGUSER = "developer";
    REDIS_URL = "redis://localhost:6379";
  };

  # Home Manager for server admin
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.server-admin = { pkgs, ... }: {
      imports = [
        ../../../home/roles/server-admin.nix
        ../../../home/profiles/headless.nix
      ];

      home = {
        username = "server-admin";
        homeDirectory = "/home/server-admin";
        stateVersion = "25.05";
      };

      programs.git = {
        userName = "Server Admin";
        userEmail = "admin@server.local";
      };

      # Server-specific shell configuration
      programs.zsh.shellAliases = {
        server-status = "server-status";
        server-logs = "server-logs";
        logs = "journalctl -f";
        containers = "podman ps -a";
        services = "systemctl list-units --type=service --state=running";
        ports = "netstat -tlnp";
        
        # Development shortcuts
        code = "cd /mnt/code";
        data = "cd /mnt/data";
        
        # Service management
        nginx-reload = "sudo systemctl reload nginx";
        pg-status = "sudo systemctl status postgresql";
        redis-cli = "redis-cli";
      };

      # Tmux configuration for server management
      programs.tmux = {
        enable = true;
        
        extraConfig = ''
          # Server monitoring layout
          bind-key M new-session -d -s monitoring \; \
            new-window -t monitoring:1 -n 'htop' 'htop' \; \
            new-window -t monitoring:2 -n 'logs' 'journalctl -f' \; \
            new-window -t monitoring:3 -n 'network' 'watch -n 1 netstat -tlnp' \; \
            select-window -t monitoring:1
        '';
      };
    };
  };

  # System state version
  system.stateVersion = "25.05";
}