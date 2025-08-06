# Server Home Manager Configuration
# Minimal configuration focused on administration and monitoring
{ pkgs, lib, ... }:

{
  # Home Manager basics
  home = {
    username = "user";
    homeDirectory = lib.mkForce "/home/user";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Essential server administration tools
      vim
      git
      htop
      iotop
      nethogs
      tree
      file
      unzip
      wget
      curl
      rsync

      # System monitoring
      lm_sensors
      smartmontools
      lsof
      strace
      tcpdump

      # Network utilities
      nmap
      netcat
      socat
      dig
      whois
      traceroute
      mtr

      # Security tools
      lynis
      # rkhunter  # Package not available in nixpkgs

      # Backup tools
      borgbackup
      rclone

      # Container management
      podman-compose
      buildah
      skopeo

      # Development/scripting
      python3
      nodejs
      jq
    ];

    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
      PAGER = "less";
      SYSTEMD_LESS = "FRXMK"; # Better systemd output
    };
  };

  # Programs configuration
  programs = {
    # Git configuration for server management
    git = {
      enable = true;
      userName = "Server Administrator";
      userEmail = "admin@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;

        # Server-friendly settings
        core.autocrlf = "input";
        fetch.prune = true;

        # Safer defaults for server environments
        push.default = "simple";
        merge.conflictStyle = "diff3";
      };
    };

    # Enhanced bash configuration for server administration
    bash = {
      enable = true;
      enableCompletion = true;
      historySize = 50000; # Large history for server work
      historyControl = [ "ignoreboth" "erasedups" ];

      shellOptions = [
        "histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"
      ];

      shellAliases = {
        # File operations
        ll = "ls -la";
        la = "ls -la";
        l = "ls -l";
        ".." = "cd ..";
        "..." = "cd ../..";

        # System monitoring
        "ps-mem" = "ps aux --sort=-%mem | head";
        "ps-cpu" = "ps aux --sort=-%cpu | head";
        "disk-usage" = "df -h";
        "memory" = "free -h";
        "processes" = "htop";

        # Network monitoring
        "netstat-listen" = "netstat -tlnp";
        "netstat-all" = "netstat -tulnp";
        "ports" = "ss -tlnp";
        "connections" = "ss -tuln";

        # Service management
        "sys-status" = "systemctl status";
        "sys-restart" = "sudo systemctl restart";
        "sys-stop" = "sudo systemctl stop";
        "sys-start" = "sudo systemctl start";
        "sys-enable" = "sudo systemctl enable";
        "sys-disable" = "sudo systemctl disable";
        "sys-reload" = "sudo systemctl reload";

        # Log management
        "logs" = "sudo journalctl -f";
        "logs-error" = "sudo journalctl -p err -f";
        "logs-system" = "sudo journalctl -u";
        "logs-boot" = "sudo journalctl -b";
        "logs-kernel" = "sudo journalctl -k";

        # Security
        "failed-logins" = "sudo journalctl -u sshd | grep 'Failed password'";
        "successful-logins" = "sudo journalctl -u sshd | grep 'Accepted password'";
        "auth-logs" = "sudo journalctl -u sshd -f";

        # Hardware monitoring
        "temp" = "sensors";
        "disk-health" = "sudo smartctl -a /dev/sda"; # Adjust device as needed

        # Container management
        "pods" = "podman pod list";
        "containers" = "podman ps -a";
        "images" = "podman images";

        # Quick system info
        "sysinfo" = "echo 'System Information:' && uname -a && echo && echo 'Memory:' && free -h && echo && echo 'Disk:' && df -h && echo && echo 'Load:' && uptime";

        # Backup helpers
        "backup-test" = "borg list";
        "backup-check" = "borg check --verify-data";
      };

      bashrcExtra = ''
        # Enhanced prompt with system information
        get_load() {
          awk '{print $1}' /proc/loadavg
        }
        
        get_memory_usage() {
          awk '/MemAvailable/{available=$2} /MemTotal/{total=$2} END{printf "%.0f%%", (total-available)/total*100}' /proc/meminfo
        }
        
        get_disk_usage() {
          df / | awk 'NR==2 {print $5}'
        }
        
        # Color-coded prompt with system metrics
        if [ "$EUID" -eq 0 ]; then
          # Root prompt (red)
          PS1="\[\033[01;31m\]\u@\h\[\033[00m\] [\$(get_load)|\$(get_memory_usage)|\$(get_disk_usage)] \[\033[01;34m\]\w\[\033[00m\]# "
        else
          # User prompt (green)
          PS1="\[\033[01;32m\]\u@\h\[\033[00m\] [\$(get_load)|\$(get_memory_usage)|\$(get_disk_usage)] \[\033[01;34m\]\w\[\033[00m\]$ "
        fi
        
        # Useful functions for server administration
        port_check() {
          if [ $# -eq 0 ]; then
            echo "Usage: port_check <port> [host]"
            return 1
          fi
          local port=$1
          local host=''${2:-localhost}
          timeout 3 bash -c "</dev/tcp/$host/$port" &>/dev/null && echo "Port $port is open on $host" || echo "Port $port is closed on $host"
        }
        
        service_info() {
          if [ $# -eq 0 ]; then
            echo "Usage: service_info <service_name>"
            return 1
          fi
          systemctl status "$1" --no-pager -l
          echo
          echo "Recent logs:"
          journalctl -u "$1" -n 10 --no-pager
        }
        
        disk_cleanup() {
          echo "Current disk usage:"
          df -h /
          echo
          echo "Cleaning package cache..."
          sudo nix-collect-garbage -d
          echo
          echo "Cleaning journal logs older than 7 days..."
          sudo journalctl --vacuum-time=7d
          echo
          echo "After cleanup:"
          df -h /
        }
        
        backup_status() {
          if command -v borg >/dev/null 2>&1; then
            echo "Borg repositories:"
            borg list 2>/dev/null | tail -5
          fi
          
          echo
          echo "Systemd backup services:"
          systemctl list-units --type=service | grep backup
        }
        
        security_check() {
          echo "=== Failed SSH Attempts (last 24h) ==="
          sudo journalctl --since "1 day ago" -u sshd | grep "Failed password" | tail -10
          
          echo
          echo "=== Active Network Connections ==="
          ss -tuln | grep LISTEN
          
          echo
          echo "=== Fail2Ban Status ==="
          if command -v fail2ban-client >/dev/null 2>&1; then
            sudo fail2ban-client status 2>/dev/null | head -10
          fi
          
          echo
          echo "=== System Load ==="
          uptime
          
          echo
          echo "=== Disk Usage ==="
          df -h / | grep -v tmpfs
        }
        
        # Auto-completion for systemctl
        if [ -f /usr/share/bash-completion/completions/systemctl ]; then
          source /usr/share/bash-completion/completions/systemctl
        fi
        
        # History settings
        export HISTTIMEFORMAT="%F %T "
        export HISTIGNORE="ls:ll:cd:pwd:exit:date:history"
        
        # Less settings for better log viewing
        export LESS="-R --mouse"
        export LESSHISTFILE=/dev/null
      '';
    };

    # Tmux for persistent sessions
    tmux = {
      enable = true;
      clock24 = true;
      terminal = "screen-256color";
      escapeTime = 0;

      extraConfig = ''
        # Status bar
        set -g status-bg black
        set -g status-fg white
        set -g status-left-length 20
        set -g status-left '#[fg=green]#h #[fg=yellow]#S '
        set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'
        
        # Window status
        setw -g window-status-current-style 'fg=black bg=green'
        setw -g window-status-style 'fg=white'
        
        # Pane borders
        set -g pane-border-style 'fg=colour238'
        set -g pane-active-border-style 'fg=colour51'
        
        # Mouse support
        set -g mouse on
        
        # Vi keys
        setw -g mode-keys vi
        
        # Reload config
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"
        
        # Better pane splitting
        bind | split-window -h
        bind - split-window -v
        
        # Pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
      '';
    };

    # SSH configuration for server access
    ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "10m";
      compression = true;

      # Server-friendly SSH settings
      extraConfig = ''
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        
        # Security settings
        HashKnownHosts yes
        VisualHostKey yes
        
        # Connection settings
        ConnectTimeout 10
        ConnectionAttempts 2
        
        # Multiplexing
        ControlPath ~/.ssh/sockets/%r@%h-%p
      '';
    };

    # Enhanced vim configuration for server administration
    vim = {
      enable = true;
      defaultEditor = true;

      extraConfig = ''
        " Basic settings
        set number
        set relativenumber
        set hlsearch
        set incsearch
        set ignorecase
        set smartcase
        set tabstop=2
        set shiftwidth=2
        set expandtab
        set autoindent
        set smartindent
        
        " Server admin friendly settings
        set ruler
        set showcmd
        set showmode
        set wildmenu
        set wildmode=longest:list,full
        set laststatus=2
        set backspace=indent,eol,start
        
        " Syntax highlighting
        syntax on
        filetype plugin indent on
        
        " Color scheme
        colorscheme desert
        
        " Key mappings
        inoremap jk <Esc>
        nnoremap <leader>w :w<CR>
        nnoremap <leader>q :q<CR>
        
        " Search improvements
        nnoremap <leader>h :nohlsearch<CR>
        
        " File navigation
        nnoremap <leader>e :e .<CR>
        
        " Quick config editing
        nnoremap <leader>v :e $MYVIMRC<CR>
        nnoremap <leader>s :source $MYVIMRC<CR>
      '';
    };
  };

  # Services (minimal for servers)
  services = {
    # SSH agent for key management
    ssh-agent.enable = true;

    # GPG agent for key management (if needed)
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-curses; # Text-based for servers

      # Long timeouts for server work
      defaultCacheTtl = 7200; # 2 hours
      defaultCacheTtlSsh = 7200; # 2 hours
      maxCacheTtl = 86400; # 24 hours
    };
  };

  # Systemd user services for server monitoring
  systemd.user = {
    services = {
      # System health monitor
      system-monitor = {
        Unit = {
          Description = "System Health Monitor";
          After = [ "multi-user.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScript "system-monitor" ''
            #!/bin/bash
            
            # Check system load
            load=$(awk '{print int($1*100)}' /proc/loadavg)  # Convert to integer (e.g., 2.5 -> 250)
            load_threshold=200  # 2.0 threshold as integer (200)
            
            if [ "$load" -gt "$load_threshold" ]; then
              load_display=$(awk '{print $1}' /proc/loadavg)
              echo "High system load detected: $load_display" | logger -p user.warning
            fi
            
            # Check disk usage
            disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
            disk_threshold=90
            
            if [ "$disk_usage" -gt "$disk_threshold" ]; then
              echo "High disk usage detected: $disk_usage%" | logger -p user.warning
            fi
            
            # Check memory usage
            mem_usage=$(awk '/MemAvailable/{available=$2} /MemTotal/{total=$2} END{printf "%.0f", (total-available)/total*100}' /proc/meminfo)
            mem_threshold=90
            
            if [ "$mem_usage" -gt "$mem_threshold" ]; then
              echo "High memory usage detected: $mem_usage%" | logger -p user.warning
            fi
          ''}";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    timers = {
      # Run system monitor every 5 minutes
      system-monitor = {
        Unit = {
          Description = "System Health Monitor Timer";
        };

        Timer = {
          OnCalendar = "*:0/5"; # Every 5 minutes
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
