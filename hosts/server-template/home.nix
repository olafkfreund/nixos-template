# Server Template Home Manager Configuration
# Uses shared profiles optimized for headless server administration
{ config, pkgs, inputs, ... }:

{
  # Import shared Home Manager profiles using inputs.self
  imports = [
    (inputs.self + "/home/profiles/base.nix") # Base configuration with git, bash, etc.
    (inputs.self + "/home/profiles/server.nix") # Server-specific tools and configurations
    (inputs.self + "/home/profiles/development.nix") # Development tools for server maintenance
  ];

  # Host-specific user info (overrides base profile defaults)
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # Override git configuration with host-specific details
  programs.git = {
    userName = "Server Admin";
    userEmail = "admin@example.com";
  };

  # Server-specific environment variables
  home.sessionVariables = {
    # Override base profile for server administration
    EDITOR = "vim"; # Prefer vim for server administration
    PAGER = "less";

    # Server environment identification
    SERVER_ENVIRONMENT = "template";
  };

  # Server-specific additional packages (extends server profile)
  home.packages = with pkgs; [
    # Advanced monitoring tools (beyond server profile)
    iotop
    nethogs
    lm_sensors
    smartmontools

    # Security and audit tools
    lynis

    # Container orchestration (for modern servers)
    kubernetes
    kubectl
    helm

    # Backup solutions (beyond server profile)
    borgbackup

    # Database administration
    postgresql_15
    redis
  ];

  # Server-specific bash aliases (extends base and server profiles)
  programs.bash.shellAliases = {
    # Server administration shortcuts
    "syslog" = "journalctl -f";
    "sysfail" = "systemctl --failed";
    "sysreload" = "sudo systemctl daemon-reload";

    # Process monitoring
    "psmem" = "ps aux | sort -nr -k 4 | head -10"; # Top memory processes
    "pscpu" = "ps aux | sort -nr -k 3 | head -10"; # Top CPU processes

    # Disk usage
    "dush" = "du -sh * | sort -hr"; # Directory sizes sorted
    "dfh" = "df -h | grep -v tmpfs"; # Disk usage without tmpfs

    # Network monitoring
    "netports" = "netstat -tuln";
    "netconns" = "netstat -ant";

    # Log analysis
    "tailf" = "tail -f";
    "logs" = "journalctl --since today";
    "errors" = "journalctl -p err --since today";
  };

  # Server-specific bash functions
  programs.bash.bashrcExtra = ''
    # Server administration functions

    # Quick service management
    sctl() {
      if [ $# -eq 1 ]; then
        systemctl status "$1"
      else
        systemctl "$1" "$2"
      fi
    }

    # Quick log viewing
    logs() {
      local service="$1"
      if [ -n "$service" ]; then
        journalctl -u "$service" -f
      else
        journalctl -f
      fi
    }

    # System resource overview
    sysinfo() {
      echo "=== System Overview ==="
      echo "Uptime: $(uptime -p)"
      echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      echo ""
      echo "=== Memory Usage ==="
      free -h
      echo ""
      echo "=== Disk Usage ==="
      df -h | grep -v tmpfs
      echo ""
      echo "=== Top Processes (CPU) ==="
      ps aux | sort -nr -k 3 | head -5 | awk '{print $3"% "$11}'
    }
  '';

  # Server-optimized tmux configuration (extends server profile)
  programs.tmux.extraConfig = ''
    # Server-specific tmux enhancements
    set -g status-left-length 30
    set -g status-left '[SRV:#{host_short}] '

    # Quick server monitoring windows
    bind-key M neww -n 'monitor' 'htop'
    bind-key L neww -n 'logs' 'journalctl -f'
    bind-key S neww -n 'status' 'watch -n 2 "systemctl status"'
  '';
}
