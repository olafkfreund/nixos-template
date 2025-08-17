# Darwin Server Home Manager Configuration
# Uses shared profiles optimized for server administration
{ lib, ... }:

{
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = { pkgs, ... }: {
      # Import shared Home Manager profiles
      imports = [
        ../../home/profiles/base.nix # Base configuration with git, bash, etc.
        ../../home/profiles/server.nix # Server-specific tools and configurations
        ../../home/profiles/development.nix # Development tools for server maintenance
      ];

      # Host-specific user info
      home = {
        username = "admin";
        homeDirectory = lib.mkDefault "/Users/admin";
      };

      # Darwin server-specific program configurations
      programs = {
        # Override git configuration for Darwin server administration
        git = {
          userName = "Darwin Server Admin";
          userEmail = "admin@darwin-server.local";
        };

        # Darwin server-specific zsh configuration
        zsh = {
          # Darwin server-specific shell aliases (extends server profile)
          shellAliases = {
            # Service management (Homebrew on Darwin)
            services = "brew services list";
            start-pg = "brew services start postgresql";
            stop-pg = "brew services stop postgresql";
            start-redis = "brew services start redis";
            stop-redis = "brew services stop redis";

            # Database connections
            pg = "psql -U postgres";
            redis = "redis-cli";
            mongo = "mongosh";

            # Network and connectivity (Darwin-specific)
            ip = "curl -s ifconfig.me && echo";
            ping-test = "ping -c 3 8.8.8.8";
            dns-flush = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";

            # Darwin system monitoring
            mem = "vm_stat";
            ports = "lsof -i -P | grep LISTEN";

            # Log monitoring (Darwin-specific)
            logs-sys = "log stream --level=info";
            logs-tail = "tail -f /usr/local/var/log/nginx/access.log";

            # Darwin cleanup
            cleanup = "brew cleanup && docker system prune -f && nix-collect-garbage -d";
          };

          # Darwin server-specific zsh enhancements
          initExtra = ''
            # Darwin server environment setup
            export SERVER_TYPE="darwin"
            export HOMEBREW_NO_AUTO_UPDATE=1

            # Darwin-specific monitoring function
            server_status() {
              echo "🖥️  Darwin Server Status"
              echo "======================"
              echo "System Load: $(uptime | awk '{print $10 $11 $12}')"
              echo "Memory: $(vm_stat | head -1)"
              echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
              echo "Docker Status: $(docker info >/dev/null 2>&1 && echo 'Running' || echo 'Stopped')"
              echo ""
              echo "Active Services:"
              brew services list | grep started
              echo ""
              echo "Network Connections:"
              lsof -i -P | grep LISTEN | head -10
            }

            # Darwin-specific aliases for server management
            alias server-status='server_status'
            alias server-logs='tail -f /usr/local/var/log/*.log'
            alias server-restart='sudo shutdown -r now'
          '';
        };

        # Darwin server-specific tmux configuration
        tmux.extraConfig = ''
          # Darwin server-specific tmux settings
          set-option -g status-bg colour235
          set-option -g status-fg colour144
          set-option -g status-left '#[fg=colour148,bg=colour235,bold] 🖥️  Darwin Server #[fg=colour144,bg=colour235,nobold,noitalics,nounderscore]⮀'
          set-option -g status-right '#[fg=colour144,bg=colour235,nobold,noitalics,nounderscore]⮂#[fg=colour144,bg=colour235] %Y-%m-%d ⮃ %H:%M #[fg=colour148,bg=colour235,nobold,noitalics,nounderscore]⮂#[fg=colour232,bg=colour148,bold] #h '

          # Server-specific panes
          bind-key S new-window -n "Server" \; \
            split-window -h \; \
            send-keys 'server-status && sleep 5' C-m \; \
            split-window -v \; \
            send-keys 'tail -f /usr/local/var/log/nginx/error.log' C-m \; \
            select-pane -t 0 \; \
            send-keys 'htop' C-m
        '';
      };

      # Darwin server-specific environment variables
      home.sessionVariables = {
        # Server environment identification
        EDITOR = "vim";
        VISUAL = "vim";
        BROWSER = "open";
        SERVER_ENVIRONMENT = "darwin";

        # Darwin-specific development paths
        GOPATH = "$HOME/go";

        # Database URLs (for Darwin development)
        DATABASE_URL = "postgres://admin:password@localhost:5432/myapp";
        REDIS_URL = "redis://localhost:6379";
        MONGODB_URL = "mongodb://localhost:27017";

        # Docker settings
        DOCKER_BUILDKIT = "1";
        COMPOSE_DOCKER_CLI_BUILD = "1";

        # Security
        GNUPGHOME = "$HOME/.gnupg";
        SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";

        # Homebrew
        HOMEBREW_NO_ANALYTICS = "1";
      };

      # Darwin-specific additional packages (extends server profile)
      home.packages = [
        # macOS-specific database clients
        pkgs.mongodb

        # Cloud tools for Darwin servers
        pkgs.awscli2
        pkgs.terraform
        pkgs.ansible

        # Container orchestration
        pkgs.kubernetes
        pkgs.kubectl
        pkgs.helm

        # Security audit tools
        pkgs.lynis

        # Backup solutions
        pkgs.borgbackup
      ];
    }; # Close users.admin
  }; # Close home-manager
}
