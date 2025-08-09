# nix-darwin Server Configuration
# Headless server configuration for macOS development machines

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../darwin/default.nix
    ./home.nix
  ];

  # System identification
  networking.hostName = lib.mkForce "nix-darwin-server";
  networking.localHostName = lib.mkForce "nix-darwin-server";
  networking.computerName = lib.mkForce "nix-darwin Server";

  # Enable Darwin package collections for server use
  darwin.packages = {
    profiles = {
      essential = true;
      development = {
        enable = true;
        languages = [ "node" "python" "go" "rust" "java" ];
        databases = true;
        docker = true;
      };
      server = {
        enable = true;
        cloud = [ "aws" "gcp" "azure" ];
      };
    };

    homebrew = {
      enableExtraSecurityTools = true; # Servers need security tools
    };
  };

  # Server-specific packages not covered by collections
  environment.systemPackages = with pkgs; [
    # Server-specific tools not in the collections
    mongodb
    nginx
    caddy
    prometheus
    grafana
    ngrok
    mkcert
    wireshark
    podman
    gnupg
    age
    sops
    screen

    # Server-specific utilities
    (writeShellScriptBin "server-status" ''
      echo "🖥️  Server Status Dashboard"
      echo "=========================="
      echo ""

      echo "💻 System Information:"
      echo "  Hostname: $(hostname)"
      echo "  macOS: $(sw_vers -productVersion)"
      echo "  Architecture: $(uname -m)"
      echo "  Uptime: $(uptime | cut -d',' -f1 | cut -d' ' -f4-)"
      echo "  Load Average: $(uptime | cut -d':' -f4-)"
      echo ""

      echo "💾 Memory Usage:"
      vm_stat | awk '
        /free/ { free = $3 }
        /active/ { active = $3 }
        /inactive/ { inactive = $3 }
        /wired/ { wired = $3 }
        END {
          total = (free + active + inactive + wired) * 4096 / 1024 / 1024 / 1024
          used = (active + inactive + wired) * 4096 / 1024 / 1024 / 1024
          printf "  Total: %.1f GB, Used: %.1f GB (%.0f%%)\n", total, used, (used/total)*100
        }'
      echo ""

      echo "💿 Disk Usage:"
      df -h / | tail -1 | awk '{print "  Root: " $3 " used of " $2 " (" $5 " full)"}'
      echo "  Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')"
      echo ""

      echo "🌐 Network:"
      echo "  External IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to determine')"
      echo "  Active Connections: $(netstat -an | grep LISTEN | wc -l | xargs)"
      echo ""

      echo "🚀 Development Services:"
      services=("postgresql" "redis-server" "nginx" "docker")
      for service in "''${services[@]}"; do
        if pgrep -f "$service" >/dev/null; then
          echo "  ✅ $service: Running"
        else
          echo "  ❌ $service: Stopped"
        fi
      done
      echo ""

      echo "🔧 Development Environment:"
      echo "  Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
      echo "  Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
      echo "  Go: $(go version 2>/dev/null | cut -d' ' -f3 || echo 'Not installed')"
      echo "  Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'Not running')"
      echo ""

      echo "📊 Resource Usage:"
      echo "  CPU Temperature: $(sudo powermetrics --samplers smc_temp --sample-count 1 -n 1 2>/dev/null | grep "CPU die temperature" | cut -d: -f2 | xargs || echo "Not available")"
    '')

    (writeShellScriptBin "server-logs" ''
      echo "📋 Server Logs"
      echo "=============="
      echo ""

      service="''${1:-system}"
      lines="''${2:-50}"

      case "$service" in
        "system")
          echo "🖥️  System logs (last $lines lines):"
          log show --last 1h --predicate 'senderImagePath contains "kernel"' | tail -n "$lines" | sed 's/^/  /'
          ;;
        "nginx")
          echo "🌐 Nginx logs:"
          if [ -f /usr/local/var/log/nginx/access.log ]; then
            tail -n "$lines" /usr/local/var/log/nginx/access.log | sed 's/^/  /'
          else
            echo "  Nginx logs not found"
          fi
          ;;
        "docker")
          echo "🐳 Docker logs:"
          docker logs --tail "$lines" $(docker ps -q) 2>/dev/null | sed 's/^/  /' || echo "  No running containers"
          ;;
        *)
          echo "Usage: server-logs [system|nginx|docker] [lines]"
          echo "Available services: system, nginx, docker"
          ;;
      esac
    '')

    (writeShellScriptBin "dev-server" ''
      echo "🚀 Development Server Manager"
      echo "============================="
      echo ""

      action="''${1:-status}"
      service="''${2:-all}"

      start_postgres() {
        if ! pgrep -f postgres >/dev/null; then
          echo "🐘 Starting PostgreSQL..."
          pg_ctl -D /usr/local/var/postgres -l /usr/local/var/log/postgres.log start 2>/dev/null || \
          brew services start postgresql 2>/dev/null || \
          echo "  Unable to start PostgreSQL (check installation)"
        else
          echo "  PostgreSQL already running"
        fi
      }

      start_redis() {
        if ! pgrep -f redis >/dev/null; then
          echo "🔴 Starting Redis..."
          redis-server --daemonize yes 2>/dev/null || \
          brew services start redis 2>/dev/null || \
          echo "  Unable to start Redis (check installation)"
        else
          echo "  Redis already running"
        fi
      }

      start_nginx() {
        if ! pgrep -f nginx >/dev/null; then
          echo "🌐 Starting Nginx..."
          nginx 2>/dev/null || \
          brew services start nginx 2>/dev/null || \
          echo "  Unable to start Nginx (check installation)"
        else
          echo "  Nginx already running"
        fi
      }

      start_docker() {
        if ! docker info >/dev/null 2>&1; then
          echo "🐳 Starting Docker..."
          open -a Docker 2>/dev/null || echo "  Docker Desktop not found"
          echo "  Waiting for Docker to start..."
          sleep 5
        else
          echo "  Docker already running"
        fi
      }

      case "$action" in
        "start")
          case "$service" in
            "postgres") start_postgres ;;
            "redis") start_redis ;;
            "nginx") start_nginx ;;
            "docker") start_docker ;;
            "all")
              start_postgres
              start_redis
              start_nginx
              start_docker
              ;;
            *) echo "Unknown service: $service" ;;
          esac
          ;;
        "stop")
          echo "🛑 Stopping services..."
          case "$service" in
            "postgres") pg_ctl -D /usr/local/var/postgres stop 2>/dev/null || brew services stop postgresql ;;
            "redis") pkill redis-server 2>/dev/null || brew services stop redis ;;
            "nginx") nginx -s quit 2>/dev/null || brew services stop nginx ;;
            "docker") osascript -e 'quit app "Docker"' 2>/dev/null ;;
            "all")
              pg_ctl -D /usr/local/var/postgres stop 2>/dev/null || brew services stop postgresql
              pkill redis-server 2>/dev/null || brew services stop redis
              nginx -s quit 2>/dev/null || brew services stop nginx
              osascript -e 'quit app "Docker"' 2>/dev/null
              ;;
            *) echo "Unknown service: $service" ;;
          esac
          ;;
        "restart")
          echo "🔄 Restarting services..."
          "$0" stop "$service"
          sleep 2
          "$0" start "$service"
          ;;
        "status")
          echo "📊 Service Status:"
          services=("postgres" "redis-server" "nginx" "docker")
          for svc in "''${services[@]}"; do
            if [[ "$svc" == "docker" ]]; then
              if docker info >/dev/null 2>&1; then
                echo "  ✅ Docker: Running"
              else
                echo "  ❌ Docker: Stopped"
              fi
            elif pgrep -f "$svc" >/dev/null; then
              echo "  ✅ $svc: Running (PID: $(pgrep -f "$svc" | head -1))"
            else
              echo "  ❌ $svc: Stopped"
            fi
          done
          ;;
        *)
          echo "Usage: dev-server [start|stop|restart|status] [service]"
          echo "Services: postgres, redis, nginx, docker, all"
          ;;
      esac
    '')

    (writeShellScriptBin "container-manager" ''
      echo "🐳 Container Manager"
      echo "==================="
      echo ""

      action="''${1:-list}"

      case "$action" in
        "list")
          echo "📋 Running Containers:"
          if docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; then
            echo ""
            echo "💾 Container Resources:"
            docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null
          else
            echo "  Docker not running or no containers"
          fi
          ;;
        "logs")
          container="''${2}"
          if [ -z "$container" ]; then
            echo "Usage: container-manager logs <container-name>"
            exit 1
          fi
          echo "📋 Logs for $container:"
          docker logs --tail 50 -f "$container" 2>/dev/null
          ;;
        "clean")
          echo "🧹 Cleaning up containers..."
          docker container prune -f 2>/dev/null
          docker image prune -f 2>/dev/null
          docker volume prune -f 2>/dev/null
          echo "  Cleanup complete"
          ;;
        "stats")
          echo "📊 Container Statistics:"
          docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null
          ;;
        *)
          echo "Usage: container-manager [list|logs|clean|stats]"
          ;;
      esac
    '')
  ];

  # Additional server-specific Homebrew packages
  homebrew = {
    brews = [
      "postgresql" # Often better managed via Homebrew
      "redis"
      "nginx"
      "mongodb/brew/mongodb-community"
      "grafana"
      "prometheus"
    ];

    taps = [
      "mongodb/brew"
    ];

    casks = [
      "pgadmin4" # Database management GUI
      "mongodb-compass" # MongoDB GUI
    ];
  };

  # Server-optimized system settings (minimal GUI)
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      show-recents = false;
      static-only = true;
      mineffect = "scale";
      tilesize = 32; # Small dock
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      CreateDesktop = false; # No desktop icons
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowScrollBars = "Always"; # For server monitoring
    };
  };

  # Server services configuration
  services = {
    nix-daemon.enable = true;
  };

  # Network configuration for server use
  networking = {
    dns = [
      "1.1.1.1"
      "8.8.8.8"
      "1.0.0.1"
      "8.8.4.4"
    ];
  };

  # Server-specific system activation
  system.activationScripts.serverSetup.text = ''
        # Create server directories
        mkdir -p /usr/local/var/log 2>/dev/null || true
        mkdir -p /usr/local/var/run 2>/dev/null || true

        # Set up log rotation (basic)
        mkdir -p ~/.local/bin 2>/dev/null || true

        # Create server management shortcuts
        cat > ~/.local/bin/server-quick-start << 'EOF'
    #!/bin/bash
    echo "🚀 Quick Server Start"
    dev-server start all
    echo "✅ Development server stack started"
    EOF
        chmod +x ~/.local/bin/server-quick-start || true

        echo "Server environment configured"
  '';

  # Time zone for server (typically UTC)
  time.timeZone = lib.mkDefault "UTC";

  # Fonts minimal set for server
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  # Server-optimized shell configuration
  programs.zsh = {
    shellInit = lib.mkAfter ''
      # Server management shortcuts
      alias status="server-status"
      alias logs="server-logs"
      alias services="dev-server status"
      alias containers="container-manager list"

      # Quick navigation
      alias logs-dir="cd /usr/local/var/log"
      alias proj="cd ~/Projects"
      alias srv="cd ~/Server"

      # Development shortcuts
      alias pg="psql -U postgres"
      alias redis-cli="redis-cli"
      alias mongo="mongosh"

      # Docker shortcuts
      alias dps="docker ps"
      alias dimg="docker images"
      alias dlogs="docker logs"
      alias dexec="docker exec -it"
      alias dprune="docker system prune -f"

      # System monitoring
      alias top="htop"
      alias ports="lsof -i -P | grep LISTEN"
      alias network="netstat -rn"

      # Git server shortcuts
      alias gst="git status"
      alias glog="git log --oneline --graph"
      alias gdiff="git diff"

      # Server utilities
      alias serve-dir="python3 -m http.server 8000"
      alias tunnel="ngrok http"
      alias cert-local="mkcert localhost 127.0.0.1"

      echo "🖥️  nix-darwin Server Environment Ready!"
      echo "🚀 Run 'server-status' for system overview"
      echo "⚡ Run 'dev-server start all' to start development services"
    '';
  };

  # User configuration for server admin
  users.users."${config.users.users.admin.name or "admin"}" = {
    description = "Server Administrator";
    shell = pkgs.zsh;
  };
}
