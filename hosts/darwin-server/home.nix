# Darwin Server Home Manager Configuration
# Uses shared profiles optimized for server administration
{ config, pkgs, lib, inputs, outputs, ... }:

{
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = { config, pkgs, ... }: {
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

      # Override git configuration for Darwin server administration
      programs.git = {
        userName = "Darwin Server Admin";
        userEmail = "admin@darwin-server.local";
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
      home.packages = with pkgs; [
        # macOS-specific database clients
        mongodb

        # Cloud tools for Darwin servers
        awscli2
        terraform
        ansible

        # Container orchestration
        kubernetes
        kubectl
        helm

        # Security audit tools
        lynis

        # Backup solutions
        borgbackup
      ];

      # Darwin server-specific shell aliases (extends server profile)
      programs.zsh.shellAliases = {
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
      programs.zsh.initExtra = ''
        # Darwin server environment setup

        # Custom functions for Darwin server management

        # Function to show Darwin server resource usage
        darwin-server-resources() {
          echo "🖥️  Darwin Server Resource Usage"
          echo "================================="
          echo ""
          echo "💾 Memory:"
          vm_stat | awk 'NR==1{next} {gsub(/[^0-9]/, "", $3); sum+=$3} END {printf "  Used: %.1f GB\n", sum*4096/1024/1024/1024}'
          echo ""
          echo "💿 Disk:"
          df -h / | awk 'NR==2 {print "  Root: " $3 " used of " $2 " (" $5 ")"}'
          echo ""
          echo "🔥 CPU Load:"
          uptime | sed 's/.*load average: /  Load: /'
        }

        # Function to check Darwin service health
        darwin-health-check() {
          echo "🏥 Darwin Service Health Check"
          echo "============================="
          echo ""

          services=("postgresql" "redis" "nginx" "docker")
          for service in "''${services[@]}"; do
            if pgrep -f "$service" > /dev/null; then
              echo "✅ $service: Running"
              case "$service" in
                "postgresql")
                  pg_isready -q && echo "  ↳ Database: Accepting connections" || echo "  ↳ Database: Not accepting connections"
                  ;;
                "redis")
                  redis-cli ping | grep -q PONG && echo "  ↳ Redis: Responding to ping" || echo "  ↳ Redis: Not responding"
                  ;;
                "docker")
                  docker info > /dev/null 2>&1 && echo "  ↳ Docker daemon: Healthy" || echo "  ↳ Docker daemon: Unhealthy"
                  ;;
              esac
            else
              echo "❌ $service: Not running"
            fi
          done
        }

        # Darwin-specific welcome message
        echo "🍎 Darwin Server Environment: $(scutil --get ComputerName)"
        echo "⚡ Darwin utilities: darwin-server-resources, darwin-health-check"
      '';

      # Enhanced tmux configuration for Darwin server (extends server profile)
      programs.tmux.extraConfig = ''
        # Darwin server-specific tmux enhancements
        set -g status-left '[DARWIN:#{host_short}] '

        # Darwin server monitoring windows
        bind-key D neww -n 'darwin-stats' 'watch -n 2 "darwin-server-resources"'
        bind-key H neww -n 'health' 'watch -n 5 "darwin-health-check"'
      '';

      # Darwin server configuration files
      home.file = {
        # Darwin server monitoring script
        ".local/bin/darwin-server-monitor".text = ''
          #!/bin/bash
          # Continuous Darwin server monitoring

          while true; do
            clear
            echo "🍎 Darwin Server Monitor - $(date)"
            echo "================================="
            echo ""

            # System load
            echo "📊 System Load:"
            uptime | sed 's/^/  /'
            echo ""

            # Memory usage
            echo "💾 Memory Usage:"
            vm_stat | grep -E "(free|active|inactive|wired)" | sed 's/^/  /'
            echo ""

            # Disk usage
            echo "💿 Disk Usage:"
            df -h / | tail -1 | sed 's/^/  /'
            echo ""

            # Top processes
            echo "🏃 Top Processes:"
            ps aux | sort -nr -k 3 | head -5 | awk '{print "  " $2 " " $3 "% " $11}'
            echo ""

            # Network connections
            echo "🌐 Active Connections:"
            netstat -an | grep LISTEN | wc -l | sed 's/^/  Listening ports: /'

            sleep 5
          done
        '';

        # Darwin-specific Docker compose template
        "Projects/darwin-docker-compose.template.yml".text = ''
          version: '3.8'

          services:
            web:
              image: nginx:alpine
              ports:
                - "80:80"
                - "443:443"
              volumes:
                - ./nginx.conf:/etc/nginx/nginx.conf:ro
                - ./html:/usr/share/nginx/html:ro
              restart: unless-stopped

            db:
              image: postgres:15-alpine
              environment:
                POSTGRES_DB: darwinapp
                POSTGRES_USER: admin
                POSTGRES_PASSWORD: password
              volumes:
                - postgres_data:/var/lib/postgresql/data
              ports:
                - "5432:5432"
              restart: unless-stopped

            redis:
              image: redis:7-alpine
              ports:
                - "6379:6379"
              restart: unless-stopped

          volumes:
            postgres_data:
        '';
      };

      # Make Darwin scripts executable
      home.activation = {
        makeDarwinScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          chmod +x "$HOME/.local/bin/darwin-server-monitor" 2>/dev/null || true
        '';

        # Create Darwin server directory structure
        createDarwinServerDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Server/configs"
          mkdir -p "$HOME/Server/scripts"
          mkdir -p "$HOME/Server/backups"
          mkdir -p "$HOME/Server/logs"
          mkdir -p "$HOME/Projects/darwin-servers"
          mkdir -p "$HOME/.config/server"
          mkdir -p "$HOME/.local/bin"

          echo "Darwin server directory structure created"
        '';
      };
    };
  };
}
}
