{ config, lib, pkgs, ... }:

{
  # Home Manager configuration for server administrator

  # Basic user info
  home = {
    username = "server-admin";
    homeDirectory = "/home/server-admin";
    stateVersion = "25.05";
  };

  # All program configurations
  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # Git configuration for server administration
    git = {
      enable = true;
      userName = "Server Admin";
      userEmail = "admin@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # Shell configuration optimized for server management
    bash = {
      enable = true;

      shellAliases = {
        # Basic navigation
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";

        # System monitoring
        "top" = "htop";
        "cpu" = "htop -s PERCENT_CPU";
        "mem" = "htop -s PERCENT_MEM";
        "gpu" = "nvtop"; # GPU monitoring

        # Network tools
        "ports" = "ss -tuln";
        "netstat" = "ss -tuln";
        "ips" = "ip addr show";

        # Docker shortcuts (if enabled)
        "dps" = "docker ps";
        "dimg" = "docker images";
        "dlog" = "docker logs -f";

        # System information
        "sysinfo" = "echo 'Host:' $(hostname) && echo 'Uptime:' $(uptime -p) && echo 'Load:' $(cat /proc/loadavg | awk '{print $1, $2, $3}') && echo 'Memory:' $(free -h | grep Mem | awk '{print $3\"/\"$2}')";
        "gpuinfo" = "nvidia-smi || radeontop -d - -l 1 || intel_gpu_top -l";

        # NixOS specific
        "rebuild" = "sudo nixos-rebuild switch --flake ~/nixos-config";
        "rebuild-test" = "sudo nixos-rebuild test --flake ~/nixos-config";
        "update" = "nix flake update ~/nixos-config";
      };

      bashrcExtra = ''
        # Server-focused prompt with system info
        export PS1="\[\e[31m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[31m\]@\[\e[m\]\[\e[34m\]\h\[\e[m\]\[\e[31m\]]\[\e[m\] \[\e[33m\]\w\[\e[m\]\$ "

        # Show server status on login
        echo "🖥️  Server: $(hostname)"
        echo "📊 Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
        echo "💾 Memory: $(free -h | grep Mem | awk '{print $3\"/\"$2\" (\"$5\" available)\"}')"
        echo "💿 Disk: $(df -h / | tail -1 | awk '{print $3\"/\"$2\" (\"$5\" used)\"}')"

        # GPU status if available
        if command -v nvidia-smi &> /dev/null; then
          echo "🎮 GPU: $(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu --format=csv,noheader,nounits | head -1)"
        elif command -v radeontop &> /dev/null; then
          echo "🎮 AMD GPU detected"
        fi

        echo ""
      '';
    };
    # Better file listing
    eza = {
      enable = true;
      aliases = {
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        tree = "eza --tree";
      };
    };

    # Better cat with syntax highlighting
    bat.enable = true;

    # System monitoring
    htop = {
      enable = true;
      settings = {
        tree_view = 1;
        show_cpu_frequency = 1;
        show_cpu_temperature = 1;
        highlight_base_name = 1;
      };
    };

    # Terminal multiplexer for persistent sessions
    tmux = {
      enable = true;
      terminal = "screen-256color";
      prefix = "C-a";
      keyMode = "vi";
      mouse = true;

      extraConfig = ''
        # Server-focused tmux configuration
        set -g history-limit 50000

        # Status bar with server info
        set -g status-bg black
        set -g status-fg green
        set -g status-left-length 30
        set -g status-left '[#{host_short}:#{session_name}] '
        set -g status-right-length 50
        set -g status-right 'Load: #(cat /proc/loadavg | cut -d" " -f1-3) | %Y-%m-%d %H:%M'

        # Window status colors
        setw -g window-status-current-style bg=green,fg=black,bold

        # Pane border colors
        set -g pane-border-style fg=colour238
        set -g pane-active-border-style fg=green

        # Copy mode colors
        setw -g mode-style bg=green,fg=black
      '';
    };

    # Directory navigation
    zoxide.enable = true;
  };

  # Server management packages
  home.packages = with pkgs; [
    # System monitoring
    iotop # I/O monitoring
    nethogs # Network usage per process
    ncdu # Disk usage analyzer

    # Network tools
    nmap # Network scanner
    netcat # Network utility
    socat # Socket utility
    tcpdump # Network packet analyzer

    # File operations
    rsync # File synchronization
    rclone # Cloud storage sync

    # Text processing
    jq # JSON processor
    yq # YAML processor
    ripgrep # Fast text search

    # Archive tools
    zip
    unzip
    p7zip

    # Development tools
    git
    vim
    nano

    # Container tools (if Docker is enabled)
    docker-compose

    # GPU monitoring (automatically included based on GPU type)
    nvtop # Universal GPU monitoring

    # System utilities
    lsof # List open files
    strace # System call tracer
    tree # Directory tree view
    which # Command location
    file # File type detection
  ];

  # SSH configuration for server management
  programs.ssh = {
    enable = true;

    extraConfig = ''
      # Server management SSH settings
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        Compression yes

      # Quick access to common server types
      Host gpu-* ai-* ml-*
        Port 22
        ForwardAgent yes

      # Local development/staging servers
      Host dev-* staging-*
        Port 22
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
    '';
  };

  # Environment variables for server management
  home.sessionVariables = {
    EDITOR = "vim";
    PAGER = "less";

    # Server identification
    SERVER_ENVIRONMENT = "true";
    SERVER_ROLE = "admin";

    # GPU-specific variables (set automatically based on GPU configuration)
    CUDA_CACHE_PATH = "$HOME/.nv/ComputeCache";

    # Container environment
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
  };

  # XDG directories (minimal for servers)
  xdg = {
    enable = true;

    # Only create essential directories
    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "${config.home.homeDirectory}/docs";
      download = "${config.home.homeDirectory}/downloads";
    };
  };

  # Service monitoring scripts (as systemd user services)
  systemd.user.services = {
    # GPU monitoring service (example)
    gpu-monitor = lib.mkIf config.modules.hardware.gpu.nvidia.enable {
      Unit = {
        Description = "GPU Monitoring Alert";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "gpu-check" ''
          # Check GPU temperature and usage
          temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
          if [ "$temp" -gt 80 ]; then
            echo "Warning: GPU temperature is $temp°C"
          fi
        ''}";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
