# Server Administrator Role Configuration
# Tools and configurations for server administration
{ pkgs, ... }:

{
  imports = [
    ../common/base.nix
    ../common/git.nix
    ../common/packages/essential.nix
  ];

  # Server administration packages
  home.packages = with pkgs; [
    # System monitoring and management
    htop # Process monitor
    iotop # I/O monitor
    nethogs # Network traffic monitor
    iftop # Network bandwidth monitor
    ncdu # Disk usage analyzer
    lsof # List open files

    # Network tools
    nmap # Network scanner
    netcat # Network utility
    tcpdump # Packet analyzer
    dig # DNS lookup
    whois # Domain information

    # System administration
    rsync # File synchronization
    screen # Terminal multiplexer
    tmux # Modern terminal multiplexer

    # Text processing
    awk # Text processing
    sed # Stream editor
    grep # Text search

    # Security tools
    fail2ban # Intrusion prevention

    # Backup tools
    borgbackup # Deduplicating backup
    restic # Modern backup tool

    # Container management
    podman # Container runtime
    podman-compose # Container orchestration

    # Service management
    systemctl-tui # Systemd TUI interface

    # Log analysis
    lnav # Log navigator
    multitail # Multi-file tail

    # Performance analysis
    sysstat # System statistics
    perf-tools # Performance analysis
  ];

  # Server admin shell configuration
  programs = {
    # Bash with server-focused aliases
    bash = {
      shellAliases = {
        # System monitoring
        ports = "netstat -tuln";
        processes = "ps aux | head -20";
        diskspace = "df -h";
        meminfo = "free -h";

        # Service management
        status = "systemctl status";
        restart = "sudo systemctl restart";
        reload = "sudo systemctl reload";
        enable = "sudo systemctl enable";
        disable = "sudo systemctl disable";

        # Log viewing
        logs = "journalctl -f";
        errors = "journalctl -p err -f";

        # Network
        listening = "ss -tuln";
        connections = "ss -tun";

        # File operations
        backup = "rsync -avzh --progress";

        # Docker/Podman shortcuts
        psa = "podman ps -a";
        psi = "podman images";
        psl = "podman logs";
      };
    };

    # Git with server-focused settings
    git = {
      extraConfig = {
        core.editor = "vim"; # Vim is more common on servers
        user.useConfigOnly = true; # Require explicit user config
      };
    };

    # Vim configuration for server editing
    vim = {
      enable = true;

      settings = {
        number = true;
        relativenumber = true;
        tabstop = 2;
        shiftwidth = 2;
        expandtab = true;
        autoindent = true;
        smartindent = true;
        hlsearch = true;
        incsearch = true;
        ignorecase = true;
        smartcase = true;
      };
    };

    # Tmux for session management
    tmux = {
      enable = true;

      extraConfig = ''
        # Improve colors
        set -g default-terminal "screen-256color"
        
        # Set scrollback buffer to 10000
        set -g history-limit 10000
        
        # Customize the status line
        set -g status-fg green
        set -g status-bg black
        
        # Enable mouse support
        set -g mouse on
        
        # Split panes using | and -
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %
        
        # Reload config file
        bind r source-file ~/.config/tmux/tmux.conf
        
        # Switch panes using Alt-arrow without prefix
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D
      '';
    };
  };
}
