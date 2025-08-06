{ config, pkgs, ... }:

{
  # Server administration focused Home Manager configuration

  # User information
  home = {
    username = "server";
    homeDirectory = "/home/server";
    stateVersion = "25.05";
  };

  # Program configurations
  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # Server-focused Git configuration
    git = {
      enable = true;
      userName = "Server Admin";
      userEmail = "admin@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "vim";
      };
    };

    # Server administration shell configuration
    bash = {
      enable = true;

      shellAliases = {
        # Enhanced listing for server management
        ll = "ls -alF --time-style=long-iso";
        la = "ls -A";
        l = "ls -CF";

        # Navigation
        ".." = "cd ..";
        "..." = "cd ../..";

        # System administration
        ports = "ss -tuln";
        listen = "ss -tuln | grep LISTEN";
        procs = "ps aux";
        meminfo = "free -h";
        diskinfo = "df -h";

        # Service management
        sysstatus = "systemctl status";
        sysstart = "sudo systemctl start";
        sysstop = "sudo systemctl stop";
        sysrestart = "sudo systemctl restart";
        sysenable = "sudo systemctl enable";
        sysdisable = "sudo systemctl disable";

        # Log viewing
        logs = "journalctl -f";
        syslogs = "journalctl -u";

        # Network diagnostics
        netstat = "ss -tuln";
        connections = "ss -tup";

        # NixOS server management
        rebuild = "sudo nixos-rebuild switch --flake .";
        rebuild-test = "sudo nixos-rebuild test --flake .";
        rollback = "sudo nixos-rebuild --rollback switch";

        # Security and monitoring
        who-logged = "last";
        failed-logins = "journalctl _SYSTEMD_UNIT=sshd.service | grep 'Failed'";

        # Docker management (if enabled)
        dps = "docker ps";
        dpa = "docker ps -a";
        di = "docker images";
        dlog = "docker logs";
        dex = "docker exec -it";

        # File permissions
        perm = "stat -c '%A %n'";
      };

      bashrcExtra = ''
        # Server admin prompt with system info
        export PS1="[\u@\h \W]\$ "
      
        # History settings for server administration
        export HISTSIZE=10000
        export HISTFILESIZE=20000
        export HISTCONTROL=ignoredups:erasedups
        export HISTTIMEFORMAT="%F %T "
        shopt -s histappend
      
        # Server environment
        export EDITOR="vim"
        export VISUAL="vim"
        export PAGER="less"
      
        # Useful functions
        sysinfo() {
          echo "=== System Information ==="
          echo "Hostname: $(hostname)"
          echo "Uptime: $(uptime -p)"
          echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
          echo "Memory: $(free -h | grep '^Mem:' | awk '{print $3"/"$2}')"
          echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
          echo "Users: $(who | wc -l) logged in"
          echo ""
        }
      
        # Network info function
        netinfo() {
          echo "=== Network Information ==="
          ip -4 addr show | grep -E '^[0-9]+:' -A 2 | grep 'inet' | awk '{print $2}' | head -5
          echo ""
          echo "Active connections:"
          ss -tup | head -10
        }
      
        # Service status function  
        services() {
          echo "=== Critical Services Status ==="
          systemctl is-active sshd nginx postgresql redis docker 2>/dev/null | paste <(echo -e "sshd\nnginx\npostgresql\nredis\ndocker") -
        }
      
        # Show system info on login
        sysinfo
      '';

      historyControl = [ "ignoredups" "erasedups" ];
      historySize = 10000;
      historyFileSize = 20000;
    };
    # Enhanced command line tools for server management
    eza = {
      enable = true;
      aliases = {
        ls = "eza --time-style=long-iso";
        ll = "eza -l --time-style=long-iso";
        la = "eza -la --time-style=long-iso";
        tree = "eza --tree";
      };
    };

    bat = {
      enable = true;
      config = {
        theme = "base16";
        pager = "less -FR";
      };
    };

    # Essential for server file management
    fd.enable = true;
    ripgrep.enable = true;

    # System monitoring
    htop = {
      enable = true;
      settings = {
        show_cpu_frequency = true;
        show_cpu_temperature = true;
        show_cpu_usage = true;
        tree_view = true;
      };
    };

    btop.enable = true;

    # Directory navigation
    zoxide.enable = true;

    # Advanced SSH configuration for server management
    ssh = {
      enable = true;

      matchBlocks = {
        "prod-server" = {
          hostname = "production.example.com";
          user = "admin";
          port = 22;
          # identityFile = "~/.ssh/id_ed25519_prod";
        };

        "staging" = {
          hostname = "staging.example.com";
          user = "admin";
          port = 22;
          # identityFile = "~/.ssh/id_ed25519_staging";
        };

        "backup-server" = {
          hostname = "backup.example.com";
          user = "backup";
          port = 22;
          # identityFile = "~/.ssh/id_ed25519_backup";
        };
      };

      extraConfig = ''
        # Server administration SSH settings
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        Compression yes
      '';
    };

    # Vim with server admin configuration
    vim = {
      enable = true;
      extraConfig = ''
        " Server administration vim config
        set nocompatible
        syntax on
        set number
        set ruler
        set showcmd
        set incsearch
        set hlsearch
        set autoindent
        set tabstop=2
        set shiftwidth=2
        set expandtab
        
        " Useful for config files
        set backspace=indent,eol,start
        set wildmenu
        set wildmode=list:longest
        
        " Show whitespace
        set listchars=tab:>-,trail:·
        set list
      '';
    };
  };

  # Server administration packages
  home.packages = with pkgs; [
    # System Monitoring
    htop
    btop
    iotop
    nethogs # Network usage per process
    iftop # Network bandwidth usage
    ncdu # Disk usage analyzer
    lsof # Open files
    strace # System call tracer
    tcpdump # Network packet analyzer

    # Network Tools
    nmap
    netcat-gnu
    socat
    dig
    whois
    traceroute
    mtr # Network diagnostic tool
    curl
    wget
    rsync

    # File Management
    file
    tree
    p7zip
    unzip
    zip

    # Text Processing
    jq # JSON processor
    yq # YAML processor
    xmlstarlet # XML processor

    # System Administration
    psmisc # killall, fuser, pstree
    procps # ps, top, kill
    util-linux # Various utilities

    # Log Analysis
    logrotate
    multitail # Multi-file tail

    # Security Tools
    gnupg
    openssl

    # Backup Tools
    borgbackup
    rclone
    duplicity

    # Database Tools
    # postgresql
    # sqlite
    # redis

    # Container Management (uncomment if using containers)
    # docker
    # docker-compose
    # podman
    # buildah

    # Virtualization (uncomment if managing VMs)
    # libvirt
    # qemu

    # Cloud Tools (uncomment as needed)
    # awscli2
    # google-cloud-sdk
    # azure-cli
    # terraform
    # ansible

    # Development/Automation
    git
    tmux
    screen

    # Performance Analysis
    perf-tools
    sysstat # sar, iostat, mpstat

    # System Information
    lshw
    pciutils
    usbutils
    dmidecode
    smartmontools # Hard drive health

    # Text Editors
    vim
    nano

    # Miscellaneous
    man-pages
    man-pages-posix
  ];

  # Server-friendly XDG directories
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
    };
  };

  # Server administration environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";

    # History settings
    HISTCONTROL = "ignoredups:erasedups";
    HISTSIZE = "10000";
    HISTFILESIZE = "20000";
    HISTTIMEFORMAT = "%F %T ";

    # Server paths
    SCRIPTS_DIR = "${config.home.homeDirectory}/scripts";
    BACKUPS_DIR = "${config.home.homeDirectory}/backups";
    LOGS_DIR = "${config.home.homeDirectory}/logs";
  };

  # Create server administration directories and configs
  home.file = {
    # Directory structure
    "scripts/.keep".text = "";
    "backups/.keep".text = "";
    "logs/.keep".text = "";
    "configs/.keep".text = "";

    # Useful server administration scripts
    "scripts/system-info.sh" = {
      text = ''
        #!/bin/bash
        # System information script
        
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        echo "=== Memory Usage ==="
        free -h
        echo ""
        
        echo "=== Disk Usage ==="
        df -h
        echo ""
        
        echo "=== Network Interfaces ==="
        ip -4 addr show | grep -E '^[0-9]+:' -A 2
        echo ""
        
        echo "=== Active Services ==="
        systemctl list-units --type=service --state=active | head -10
      '';
      executable = true;
    };

    "scripts/backup-check.sh" = {
      text = ''
        #!/bin/bash
        # Simple backup verification script
        
        BACKUP_DIR="/path/to/backups"
        
        echo "=== Backup Status Check ==="
        echo "Checking backups in: $BACKUP_DIR"
        
        if [ -d "$BACKUP_DIR" ]; then
            echo "Latest backups:"
            ls -lt "$BACKUP_DIR" | head -5
        else
            echo "Backup directory not found: $BACKUP_DIR"
        fi
      '';
      executable = true;
    };

    # tmux configuration for server administration
    ".tmux.conf".text = ''
      # Server administration tmux configuration
      
      # Set prefix key
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix
      
      # Basic settings
      set -g default-terminal "screen-256color"
      set -g history-limit 10000
      set -g mouse on
      
      # Status bar
      set -g status-bg colour235
      set -g status-fg colour248
      set -g status-left '[#S] '
      set -g status-right '%Y-%m-%d %H:%M'
      
      # Window settings
      setw -g window-status-current-style 'fg=colour15 bg=colour238 bold'
      
      # Pane settings
      set -g pane-border-style 'fg=colour238'
      set -g pane-active-border-style 'fg=colour51'
      
      # Key bindings
      bind | split-window -h
      bind - split-window -v
      bind r source-file ~/.tmux.conf \; display "Config reloaded!"
    '';
  };

  # Server administration services
  services = {
    # GPG agent for secure key management
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 3600; # 1 hour
      maxCacheTtl = 86400; # 24 hours
    };
  };
}
