# Server Configuration Template
# Optimized for reliability, security, and performance
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/hardware/power-management.nix
    ../../modules/security
    ../../modules/virtualization/podman.nix
    ../../modules/virtualization/libvirt.nix
  ];

  # System identification
  networking.hostName = "server-template";

  # Hardware profile for server
  modules.hardware.power-management = {
    enable = true;
    profile = "server";
    cpuGovernor = "ondemand"; # Balance performance and efficiency for servers
    enableThermalManagement = true;

    server = {
      enableServerOptimizations = true;
      disableWakeOnLan = false; # Keep WoL enabled for remote management
    };
  };

  # No desktop environment for server (modules.desktop doesn't have enable option)

  # Security hardening (agenix module doesn't have enable option)
  # modules.security.agenix can be enabled per host as needed

  # Container support for services
  modules.virtualization.podman.enable = true;

  # VM hosting capability
  modules.virtualization.libvirt.enable = true;

  # Network configuration for server
  networking = {
    # Use systemd-networkd for servers (more reliable)
    useNetworkd = true;
    useDHCP = false;

    # Configure specific interface (adjust as needed)
    interfaces.enp0s31f6 = {
      useDHCP = true;
      # Static IP example:
      # ipv4.addresses = [{
      #   address = "192.168.1.100";
      #   prefixLength = 24;
      # }];

      # Wake-on-LAN support
      wakeOnLan.enable = true;
    };

    # Server firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
      ];

      # Additional server ports as needed
      # allowedTCPPorts = [ 3000 5432 6379 ];  # App, PostgreSQL, Redis

      # Log rejected connections for monitoring
      logRefusedConnections = true;
      logRefusedPackets = true;
    };

    # IPv6 configuration
    enableIPv6 = true;

    # DNS settings
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  # Server services
  services = {
    # SSH server with security hardening
    openssh = {
      enable = true;
      ports = [ 22 ];

      settings = {
        # Security settings
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        AuthenticationMethods = "publickey";

        # Connection settings
        MaxAuthTries = 3;
        MaxSessions = 10;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;

        # Protocol settings
        Protocol = 2;
        PermitTunnel = "no";
        AllowTcpForwarding = "yes";
        X11Forwarding = false;
        PrintMotd = false;

        # Limit users (uncomment and adjust as needed)
        # AllowUsers = [ "user" "admin" ];
      };

      # Additional SSH hardening
      extraConfig = ''
        # Disable unused authentication methods
        ChallengeResponseAuthentication no
        KerberosAuthentication no
        GSSAPIAuthentication no
        
        # Logging
        SyslogFacility AUTH
        LogLevel INFO
        
        # Network settings
        TCPKeepAlive yes
        Compression delayed
        
        # Security
        StrictModes yes
        IgnoreRhosts yes
        HostbasedAuthentication no
        PermitEmptyPasswords no
        PermitUserEnvironment no
        
        # Banner
        Banner /etc/ssh/banner
      '';
    };

    # System monitoring
    prometheus = {
      enable = true;
      port = 9090;

      # Basic system metrics
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "processes"
            "interrupts"
            "ksmd"
            "logind"
            "meminfo_numa"
            "mountstats"
            "network_route"
            "systemd"
            "tcpstat"
            "wifi"
          ];
        };
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{
            targets = [ "localhost:9100" ];
          }];
        }
      ];
    };

    # Log management
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        MaxRetentionSec=1month
        ForwardToSyslog=no
      '';
    };

    # Automatic updates (with reboot protection)
    # Note: nixos-upgrade service doesn't exist - use system.autoUpgrade instead
    # nixos-upgrade = {
    #   enable = false;  # Enable carefully on servers
    #   dates = "04:00";
    #   allowReboot = false;  # Never auto-reboot servers
    # };

    # Time synchronization (critical for servers)
    ntp = {
      enable = true;
      servers = [
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
    };

    # Fail2Ban for intrusion prevention
    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = lib.mkForce "1h"; # Server uses longer ban times
      bantime-increment = {
        enable = true;
        multipliers = "2 4 8 16 32 64";
        maxtime = "168h"; # 1 week max
        overalljails = true;
      };

      jails = {
        # SSH protection
        sshd = {
          enabled = true;
          settings = {
            port = "22";
            filter = "sshd";
            logpath = "/var/log/auth.log";
            maxretry = 5;
            findtime = 600;
            bantime = 3600;
          };
        };

        # Nginx protection (if enabled)
        nginx-http-auth = {
          enabled = false; # Enable if using Nginx
          settings = {
            port = "80,443";
            logpath = "/var/log/nginx/error.log";
          };
        };
      };
    };

    # Log rotation
    logrotate = {
      enable = true;
      settings = {
        header = {
          dateext = true;
          compress = true;
          copytruncate = true;
        };

        "/var/log/*.log" = {
          rotate = 4;
          weekly = true;
          missingok = true;
          notifempty = true;
        };
      };
    };

    # Hardware monitoring (lm_sensors service doesn't exist)
    smartd = {
      enable = true;
      autodetect = true;
    };

    # Automatic filesystem maintenance
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    # Zfs maintenance (if using ZFS)
    # zfs.autoScrub = {
    #   enable = true;
    #   interval = "weekly";
    # };
  };

  # Hardware configuration for servers
  hardware = {
    # Minimal graphics (headless server)
    graphics.enable = false;

    # No audio needed
    pulseaudio.enable = false;

    # CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Disable bluetooth
    bluetooth.enable = false;
  };

  # Kernel configuration for server stability
  boot = {
    # Stable kernel for servers
    kernelPackages = pkgs.linuxPackages;

    kernelParams = [
      # Server optimizations
      "intel_idle.max_cstate=1"
      "processor.max_cstate=1"

      # Security
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
    ];

    # System control parameters (moved from kernelParams as they contain spaces)
    kernel.sysctl = {
      # Memory management (server-specific overrides)
      "vm.dirty_ratio" = lib.mkForce 15;
      "vm.dirty_background_ratio" = lib.mkForce 5;
      "vm.swappiness" = lib.mkForce 10;

      # Network optimizations
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    };

    # Kernel modules
    kernelModules = [ "kvm-intel" "kvm-amd" ];

    # Boot configuration
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 5; # Give time for recovery
    };

    # Clean /tmp on boot
    tmp.cleanOnBoot = true;
  };

  # Server-optimized file systems
  fileSystems."/" = {
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  # Swap configuration (minimal for servers)
  swapDevices = [ ];
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # Smaller than desktop
  };

  # Environment for server administration
  environment = {
    variables = {
      EDITOR = "vim";
      PAGER = "less";
    };

    systemPackages = with pkgs; [
      # Essential server tools
      vim
      git
      wget
      curl
      rsync
      screen
      tmux

      # System monitoring
      htop
      iotop
      nethogs
      iftop
      lsof
      strace
      tcpdump

      # Network tools
      nmap
      netcat
      socat
      dig
      whois
      traceroute
      mtr

      # Hardware monitoring
      lm_sensors
      smartmontools
      hdparm

      # Security tools
      fail2ban
      lynis
      # rkhunter  # Package not available in nixpkgs

      # Backup and sync
      borgbackup
      rclone

      # Archive tools
      p7zip
      unzip

      # Development/scripting
      python3
      nodejs

      # Containers
      podman-compose
      buildah
      skopeo

      # Virtualization
      qemu
      virt-manager
    ];
  };

  # User configuration (minimal)
  users = {
    # Disable mutable users for security
    mutableUsers = false;

    users = {
      root = {
        # Disable root login
        hashedPassword = "!";
      };

      user = {
        isNormalUser = true;
        description = "Server Administrator";
        extraGroups = [
          "wheel"
          "systemd-journal"
          "docker"
          "libvirtd"
          "podman"
        ];

        # Set hashed password (generate with: mkpasswd -m sha-512)
        hashedPassword = "$6$rounds=4096$..."; # Replace with actual hash

        # SSH keys for secure access
        openssh.authorizedKeys.keys = [
          # Add your SSH public keys here
          # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD... user@workstation"
        ];
      };
    };
  };

  # Security configuration
  security = {
    # Sudo configuration
    sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true; # Always require password

      extraRules = [
        {
          users = [ "user" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl restart *";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/systemctl status *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    # PAM configuration
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65536";
      }
    ];

    # Kernel security
    lockKernelModules = true;

    # AppArmor for additional security
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Systemd configuration
  systemd = {
    # Watchdog configuration
    watchdog = {
      runtimeTime = "20s";
      rebootTime = "30s";
    };

    # Sleep configuration (servers shouldn't sleep)
    targets.sleep.enable = false;
    targets.suspend.enable = false;
    targets.hibernate.enable = false;
    targets.hybrid-sleep.enable = false;

    # Service hardening defaults
    services = {
      # Harden SSH service
      sshd.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };

  # Duplicate user configuration removed - defined above

  # Home Manager (minimal server setup)
  home-manager.users.user = import ./home.nix;

  # System maintenance
  system = {
    # Disable auto-upgrade for servers (manual control preferred)
    autoUpgrade.enable = false;

    stateVersion = "25.05";
  };

  # Nix configuration for servers
  nix = {
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkForce "--delete-older-than 30d"; # Server keeps more history
    };

    # Optimise store
    settings.auto-optimise-store = true;

    # Build settings
    settings = {
      cores = 0; # Use all cores
      max-jobs = "auto";

      # Substitute settings
      trusted-substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
    };
  };
}
