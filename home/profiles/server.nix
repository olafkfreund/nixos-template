# Server Home Manager profile
# Configuration for server/headless environments
{ lib, pkgs, ... }:

{
  # Import base configuration
  imports = [ ./base.nix ];

  # Override desktop defaults for server environment
  # Home configuration consolidated
  home = {
    # Server-focused packages
    packages = [
      # System monitoring
      pkgs.htop
      pkgs.iotop
      pkgs.nethogs
      pkgs.iftop
      pkgs.ncdu # Disk usage analyzer

      # Network tools
      pkgs.netcat
      pkgs.socat
      pkgs.nmap
      pkgs.traceroute
      pkgs.tcpdump
      pkgs.wireshark-cli # tshark

      # Text processing
      pkgs.ripgrep
      pkgs.fd
      pkgs.jq
      pkgs.yq

      # File manipulation
      pkgs.rsync
      pkgs.rclone

      # Archive tools
      pkgs.p7zip
      pkgs.unrar

      # Log analysis
      pkgs.logrotate
      pkgs.multitail

      # Performance monitoring
      pkgs.sysstat # iostat, mpstat, etc.

      # Security tools
      pkgs.nftables
      pkgs.fail2ban

      # Database clients
      pkgs.postgresql_15 # psql client
      pkgs.mysql80 # mysql client
      pkgs.sqlite
      pkgs.redis

      # Container tools
      pkgs.docker
      pkgs.docker-compose
      pkgs.podman

      # Cloud tools
      pkgs.awscli2
      pkgs.google-cloud-sdk
      pkgs.terraform

      # Backup tools
      pkgs.restic
      pkgs.borgbackup

      # Configuration management
      pkgs.ansible

      # API testing
      pkgs.curl
      pkgs.httpie

      # Process management
      # pkgs.supervisor  # Package not available in current nixpkgs
    ];

    # Server environment variables
    sessionVariables = {
      TERMINAL = lib.mkForce "tmux"; # Servers need tmux
      EDITOR = lib.mkDefault "vim"; # Can be overridden by development profile
      PAGER = lib.mkDefault "less -R"; # Can be overridden by host config
      SYSTEMD_PAGER = "less -R";

      # Optimize for server use
      HISTTIMEFORMAT = "%F %T ";
      HISTSIZE = "10000";
      HISTFILESIZE = "20000";

      # Security
      UMASK = "022";

      # Locale
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
    };
  };

  # Programs configuration
  programs = {
    # Prefer bash on servers
    zsh.enable = lib.mkDefault false;

    # Server-optimized shell configuration
    bash = {
      shellAliases = {
        # System monitoring
        ps-mem = "ps aux --sort=-%mem | head";
        ps-cpu = "ps aux --sort=-%cpu | head";
        df-h = "df -h";
        du-h = "du -h --max-depth=1";
        free-h = "free -h";

        # Network monitoring
        netstat-listen = "netstat -tuln";
        netstat-connections = "netstat -tun";
        ss-listen = "ss -tuln";
        ports-listening = "netstat -tuln | grep LISTEN"; # Server-specific version

        # Log analysis (can be overridden by host-specific configs)
        syslog = lib.mkDefault "tail -f /var/log/syslog";
        messages = "tail -f /var/log/messages";
        auth-log = "tail -f /var/log/auth.log";
        nginx-access = "tail -f /var/log/nginx/access.log";
        nginx-error = "tail -f /var/log/nginx/error.log";

        # Service management
        systemctl-status = "systemctl status";
        systemctl-failed = "systemctl --failed";
        systemctl-list = "systemctl list-units --type=service";

        # File permissions and ownership
        perm-web = "find . -type f -exec chmod 644 {} + && find . -type d -exec chmod 755 {} +";
        fix-perms = "chmod -R u+rw,g+r,o+r";

        # Database shortcuts
        psql-list = "psql -l";
        mysql-list = "mysql -e 'show databases;'";

        # Docker management
        docker-cleanup = "docker system prune -af";
        docker-logs = "docker logs -f";
        docker-stats = "docker stats --no-stream";

        # Backup shortcuts
        backup-check = "restic snapshots";
        backup-status = "systemctl status backup-*";

        # Security monitoring
        last-logins = "last -n 20";
        failed-logins = "grep 'Failed password' /var/log/auth.log | tail -20";
        active-connections = "ss -tuln";

        # Configuration validation
        nginx-test = "nginx -t";
        apache-test = "apache2ctl configtest";

        # Quick file editing
        edit-hosts = "sudo vim /etc/hosts";
        edit-fstab = "sudo vim /etc/fstab";
        edit-crontab = "crontab -e";

        # System updates (NixOS)
        update-system = "sudo nixos-rebuild switch";
        update-check = "sudo nixos-rebuild dry-run";
        rollback = "sudo nixos-rebuild switch --rollback";
      };

      bashrcExtra = ''
        # Server-specific bash configuration

        # Enhanced prompt with system load info
        export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] [$(uptime | cut -d, -f3-)] \$ '

        # Automatic tmux session
        if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
          tmux attach-session -t default || tmux new-session -s default
        fi

        # Server environment checks
        alias check-services='systemctl --failed && echo "=== Disk Usage ===" && df -h && echo "=== Memory Usage ===" && free -h'
        alias server-status='check-services && echo "=== Load Average ===" && uptime'
      '';
    };

    # Git configuration for server environments
    git.extraConfig = {
      # Server-optimized settings
      core = {
        editor = "vim";
        pager = "less -R";
      };

      # Simplified workflow for server configs (can be overridden)
      push.default = lib.mkDefault "simple";
      pull.rebase = lib.mkDefault false;

      # Server-specific aliases
      alias = {
        config-diff = "diff --no-index";
        backup-config = "!cp $1 $1.backup.$(date +%Y%m%d_%H%M%S)";
        restore-config = "!mv $1.backup.* $1";
      };
    };

    # Tmux configuration for server sessions
    tmux = {
      enable = lib.mkDefault true;

      clock24 = true;
      terminal = "screen-256color";
      historyLimit = 10000;

      extraConfig = ''
        # Server-optimized tmux configuration

        # Status bar configuration
        set -g status-bg colour235
        set -g status-fg colour136
        set -g status-left '#[fg=colour160]#H #[fg=colour136][#S] '
        set -g status-left-length 30
        set -g status-right '#[fg=colour136]%Y-%m-%d %H:%M'

        # Window status format
        set -g window-status-format '#I:#W'
        set -g window-status-current-format '#[fg=colour160]#I:#W'

        # Pane border colors
        set -g pane-border-style fg=colour235
        set -g pane-active-border-style fg=colour136

        # Enable mouse support
        set -g mouse on

        # Vi mode keys
        setw -g mode-keys vi

        # Reload configuration
        bind r source-file ~/.tmux.conf \; display "Configuration reloaded!"

        # Better pane splitting
        bind | split-window -h
        bind - split-window -v

        # Server monitoring session setup
        bind M new-window -n 'monitor' 'htop' \; \
               split-window -v -t 'monitor' 'iotop' \; \
               split-window -h -t 'monitor' 'nethogs' \; \
               select-layout tiled
      '';
    };
  };

  # Server-specific services
  services = {
    # SSH agent
    ssh-agent.enable = lib.mkDefault true;
  };

  # Minimal XDG configuration for servers
  xdg = {
    enable = true;

    # Server-appropriate directories (can be overridden by other profiles)
    userDirs = {
      enable = lib.mkDefault false; # Don't create desktop directories on servers by default
    };
  };
}
