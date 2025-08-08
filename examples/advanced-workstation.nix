# Advanced Workstation Configuration Example
# Demonstrates all the new expert-level features implemented

{ lib, pkgs, ... }:

{
  imports = [
    # Import hardware configuration
    ./hardware-configuration.nix

    # Import common base configuration
    ../hosts/common.nix

    # Import all advanced modules
    ../modules/hardware
    ../modules/services
    ../modules/development
  ];

  # System identification
  networking.hostName = "advanced-workstation";

  # Advanced hardware detection and optimization
  modules.hardware.detection = {
    enable = true;
    autoOptimize = true;
    profile = null; # Auto-detect performance profile

    reporting = {
      enable = true;
      logLevel = "debug";
    };

    # Override detection if needed
    overrides = {
      # cpu.vendor = "intel";
      # virtualization.type = "bare-metal";
    };
  };

  # Advanced Nix optimization
  modules.core.nixOptimization = {
    enable = true;

    tmpfs = {
      enable = true;
      size = "8G"; # Large tmpfs for high-memory systems
    };

    store = {
      autoOptimise = true;
      gc = {
        automatic = true;
        dates = "daily"; # More aggressive GC for development
        options = "--delete-older-than 7d";
        persistent = true;
      };
    };

    experimental = {
      enable = true;
      features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "recursive-nix"
      ];
    };

    performance = {
      maxJobs = "auto";
      cores = 0; # Use all cores
      keepOutputs = true;
      keepDerivations = true;
      useCgroups = true;
    };
  };

  # Comprehensive monitoring setup
  modules.services.monitoring = {
    enable = true;

    prometheus = {
      enable = true;
      port = 9090;
      listenAddress = "0.0.0.0";
      retention = "30d";
      scrapeInterval = "15s";

      alerting = {
        enable = true;
        customRules = ''
          groups:
          - name: development.rules
            rules:
            - alert: HighBuildLoad
              expr: node_load15 > 8
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High build load detected"
                description: "Build load is {{ $value }} on {{ $labels.instance }}"
        '';
      };

      remoteWrite = [
        # Example remote write to external monitoring
        # {
        #   url = "https://prometheus.example.com/api/v1/write";
        #   basicAuth = {
        #     username = "monitoring";
        #     password = "secret";
        #   };
        # }
      ];
    };

    exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "0.0.0.0";
      };

      systemd = {
        enable = true;
        port = 9558;
      };

      process = {
        enable = true;
        port = 9256;
      };

      blackbox = {
        enable = true;
        port = 9115;
      };
    };

    grafana = {
      enable = true;
      port = 3000;
      domain = "localhost";
      adminPassword = "secure-password-change-me";
    };

    systemHealth = {
      enable = true;
      checkInterval = "1m";
      checks = [
        "disk-space"
        "memory-usage"
        "cpu-temperature"
        "service-status"
        "network-connectivity"
      ];
    };

    logAggregation = {
      enable = true;
      retention = "14d";
    };

    notification = {
      enable = false;
      # webhook = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL";
      # email = {
      #   to = [ "admin@example.com" ];
      #   from = "monitoring@example.com";
      #   smtpHost = "smtp.example.com";
      #   smtpPort = 587;
      # };
    };
  };

  # Template module example usage
  modules.template = {
    enable = true;

    settings = {
      logLevel = "info";
      timeout = 30;
      retries = 3;
    };

    services = {
      web-api = {
        name = "web-api";
        port = 8080;
        enable = true;
        extraConfig = {
          workers = 4;
          database_url = "postgresql://localhost/api";
        };
      };

      background-worker = {
        name = "background-worker";
        port = 8081;
        enable = true;
        extraConfig = {
          queue_size = 1000;
          batch_size = 10;
        };
      };
    };

    networking = {
      port = 8080;
      interface = "0.0.0.0";
      allowedIPs = [ "127.0.0.1" "10.0.0.0/8" "192.168.0.0/16" ];
    };

    user = "webapp";
    group = "webapp";

    logging = {
      level = "info";
      file = "/var/log/webapp/app.log";
      rotate = true;
    };

    resources = {
      memory = "2G";
      cpu = "50%";
    };

    features = {
      metrics = true;
      healthCheck = true;
      apiDocs = true;
    };
  };

  # Development environment
  modules.development = {
    git.enable = true;
  };

  # Advanced security configuration
  security = {
    # Enable AppArmor for additional security
    apparmor.enable = true;

    # Advanced audit configuration
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        "-w /etc/group -p wa -k group_changes"
        "-w /etc/sudoers -p wa -k sudo_changes"
        "-w /var/log/auth.log -p wa -k auth_log"
      ];
    };

    # Fail2ban for SSH protection
    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      ignoreIP = [ "127.0.0.1/8" "10.0.0.0/8" "192.168.0.0/16" ];
    };
  };

  # System services
  services = {
    # Enable SSH with secure configuration
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        MaxAuthTries = 3;
      };
      ports = [ 22 ];
    };

    # NTP for time synchronization
    ntp.enable = true;

    # Automatic updates (optional)
    # system-update = {
    #   enable = true;
    #   dates = "weekly";
    # };
  };

  # Advanced networking
  networking = {
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        3000 # Grafana
        8080 # Web API
        9090 # Prometheus
        9100 # Node exporter
      ];

      # Advanced firewall rules
      extraCommands = ''
        # Rate limiting for SSH
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name ssh --rsource
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --rttl --name ssh --rsource -j DROP
        
        # Block common attack patterns
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
        iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
        iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
      '';
    };

    # Advanced DNS configuration
    nameservers = [ "1.1.1.1" "8.8.8.8" "9.9.9.9" ];

    # Network optimization
    kernel.sysctl = {
      # TCP optimization
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_fastopen" = 3;

      # Network buffer optimization
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 65536 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";

      # Connection tracking optimization
      "net.netfilter.nf_conntrack_max" = 1000000;
      "net.netfilter.nf_conntrack_tcp_timeout_established" = 600;
    };
  };

  # Advanced boot configuration
  boot = {
    # Latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;

    # Kernel parameters for performance and security
    kernelParams = [
      # Security
      "mitigations=auto"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"

      # Performance
      "transparent_hugepage=madvise"
      "elevator=mq-deadline"

      # Debugging (disable in production)
      "quiet"
      "loglevel=3"
    ];

    # Enable various filesystems
    supportedFilesystems = [ "ntfs" "exfat" "btrfs" "zfs" ];

    # ZFS support (if using ZFS)
    # zfs = {
    #   enableUnstable = true;
    #   forceImportRoot = false;
    #   forceImportAll = false;
    # };

    # Plymouth for nice boot screen
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # User configuration
  users.users.developer = {
    isNormalUser = true;
    description = "Developer User";
    extraGroups = [
      "wheel" # sudo access
      "networkmanager" # network management
      "docker" # docker access (if enabled)
      "libvirtd" # virtualization (if enabled)
      "audio" # audio access
      "video" # video access
      "input" # input devices
      "dialout" # serial ports
      "plugdev" # removable devices
    ];

    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."
    ];
  };

  # Home Manager configuration for the developer user
  home-manager.users.developer = { pkgs, ... }: {
    imports = [
      ../home/roles/developer.nix
      ../home/profiles/desktop.nix
    ];

    home = {
      username = "developer";
      homeDirectory = "/home/developer";
      stateVersion = "25.05";
    };

    programs.git = {
      userName = "Developer";
      userEmail = "developer@example.com";
    };
  };

  # Advanced system packages
  environment.systemPackages = with pkgs; [
    # System monitoring and debugging
    htop
    btop
    iotop
    nethogs
    iftop
    nload
    bandwhich
    bottom

    # Network tools
    nmap
    netcat
    curl
    wget
    aria2
    mtr
    traceroute
    whois
    dig

    # Development tools
    git
    vim
    neovim
    tmux
    screen

    # Archive tools
    p7zip
    unzip
    zip
    unrar

    # File management
    tree
    fd
    ripgrep
    fzf
    bat
    exa

    # System information
    neofetch
    lscpu
    lshw
    inxi
    hwinfo

    # Performance testing
    sysbench
    stress-ng
    iperf3

    # Container and virtualization
    docker-compose
    podman-compose
    vagrant

    # Security tools
    nmap
    wireshark
    tcpdump

    # Text processing
    jq
    yq
    xmlstarlet

    # Backup and sync
    rsync
    rclone
    borgbackup

    # Build tools
    gnumake
    cmake
    gcc
    clang

    # Package management helpers
    nix-tree
    nix-diff
    nix-index
    comma # Run programs without installing them
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "kitty";
  };

  # System state version
  system.stateVersion = "25.05";

  # Additional system tweaks
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

    # Enable fish shell as alternative
    fish.enable = true;

    # Enable Starship prompt
    starship.enable = true;

    # Command-not-found with Nix integration
    command-not-found.enable = false; # Disable in favor of comma

    # Enable mosh for mobile shell
    mosh.enable = true;
  };

  # Enable Zram for compressed swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # Advanced power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
    powertop.enable = true;
  };

  # Hardware enablements
  hardware = {
    # Enable all firmware
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    # Graphics
    graphics = {
      enable = true;
      enable32Bit = true; # For 32-bit applications
    };

    # Audio
    pulseaudio.enable = false; # Disable in favor of PipeWire

    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    # Printing
    printers.ensureDefaultPrinter = "Default-Printer";
  };

  # PipeWire for audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "FiraCode Nerd Font" "Liberation Mono" ];
      };
    };
  };

  # Desktop environment (if needed)
  # services.xserver = {
  #   enable = true;
  #   displayManager.gdm.enable = true;
  #   desktopManager.gnome.enable = true;
  # };

  # Enable Docker (optional)
  # virtualisation.docker = {
  #   enable = true;
  #   enableOnBoot = true;
  #   autoPrune = {
  #     enable = true;
  #     dates = "weekly";
  #   };
  # };

  # Enable libvirtd for KVM (optional)  
  # virtualisation.libvirtd = {
  #   enable = true;
  #   qemu = {
  #     package = pkgs.qemu_kvm;
  #     runAsRoot = false;
  #   };
  # };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Store optimization
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ];
  };
}
