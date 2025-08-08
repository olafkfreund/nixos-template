# Home Manager configuration for nix-darwin Server
# Server administrator user environment

{ config, pkgs, lib, inputs, outputs, ... }:

{
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = { config, pkgs, ... }: {
      # User information
      home = {
        username = "admin";
        homeDirectory = lib.mkDefault "/Users/admin";
        stateVersion = "25.05";

        # Server administrator packages
        packages = with pkgs; [
          # Terminal multiplexers
          tmux
          screen

          # System monitoring
          htop
          btop
          iotop

          # Network tools
          nmap
          tcpdump
          wireshark
          netcat

          # Development tools
          git
          gh
          vim
          neovim

          # Languages for server development
          nodejs_20
          python311
          go
          rustc

          # Database clients
          postgresql
          redis
          mongodb
          sqlite

          # Container tools
          docker
          kubectl

          # Cloud tools
          awscli2
          terraform
          ansible

          # Text processing
          jq
          yq

          # System utilities
          tree
          fd
          ripgrep
          bat
          eza
          curl
          wget

          # Security tools
          gnupg
          age
          sops
        ];

        # Programs configuration
        programs = {
          # Git configuration for server development
          git = {
            enable = true;
            userName = lib.mkDefault "Server Admin";
            userEmail = lib.mkDefault "admin@example.com";

            extraConfig = {
              init.defaultBranch = "main";
              pull.rebase = true;
              push.autoSetupRemote = true;
              core = {
                editor = "vim";
                autocrlf = "input";
              };
              # Server-optimized settings
              gc = {
                auto = 256;
                autopacklimit = 50;
              };
              # Security for server environment
              transfer = {
                fsckobjects = true;
              };
              fetch = {
                fsckobjects = true;
              };
              receive = {
                fsckobjects = true;
              };
            };
          };

          # Server-focused shell configuration
          zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;

            shellAliases = {
              # Navigation
              ll = "eza -la --group-directories-first";
              ls = "eza --group-directories-first";
              la = "eza -a --group-directories-first";
              tree = "eza --tree";

              # Git (server workflow)
              g = "git";
              gs = "git status -s";
              ga = "git add";
              gc = "git commit";
              gp = "git push";
              gl = "git pull";
              gco = "git checkout";
              gb = "git branch";
              gd = "git diff";
              glog = "git log --oneline --graph --decorate --all";

              # System monitoring
              top = "htop";
              mem = "free -h";
              disk = "df -h";
              ports = "lsof -i -P | grep LISTEN";
              processes = "ps aux | grep -v grep";

              # Docker management
              dps = "docker ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}'";
              dimg = "docker images --format 'table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}'";
              dlogs = "docker logs -f --tail 100";
              dexec = "docker exec -it";
              dprune = "docker system prune -af";
              dstop-all = "docker stop $(docker ps -q)";

              # Service management
              services = "brew services list";
              start-pg = "brew services start postgresql";
              stop-pg = "brew services stop postgresql";
              start-redis = "brew services start redis";
              stop-redis = "brew services stop redis";

              # Database connections
              pg = "psql -U postgres";
              redis = "redis-cli";
              mongo = "mongosh";

              # Network and connectivity
              ip = "curl -s ifconfig.me && echo";
              ping-test = "ping -c 3 8.8.8.8";
              dns-flush = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";

              # Server utilities
              serve = "python3 -m http.server 8000";
              tunnel = "ngrok http 8000";
              cert-gen = "mkcert localhost 127.0.0.1 ::1";

              # Log monitoring
              logs-sys = "log stream --level=info";
              logs-tail = "tail -f /usr/local/var/log/nginx/access.log";

              # System shortcuts
              reload = "source ~/.zshrc";
              ".." = "cd ..";
              "..." = "cd ../..";

              # Cleanup
              cleanup = "brew cleanup && docker system prune -f && nix-collect-garbage -d";
            };

            initContent = ''
              # Server environment setup
          
              # Load direnv for project-specific environments
              if command -v direnv > /dev/null; then
                direnv_hook="$(direnv hook zsh 2>/dev/null || echo '')"
                if [[ -n "$direnv_hook" && "$direnv_hook" =~ ^[[:space:]]*direnv ]]; then
                  eval "$direnv_hook"
                fi
              fi
          
              # Initialize zoxide for smart cd
              if command -v zoxide > /dev/null; then
                zoxide_hook="$(zoxide init zsh 2>/dev/null || echo '')"
                if [[ -n "$zoxide_hook" && "$zoxide_hook" =~ ^[[:space:]]*export ]]; then
                  eval "$zoxide_hook"
                fi
              fi
          
              # Server-specific environment variables
              export EDITOR="vim"
              export VISUAL="vim"
              export PAGER="less"
              export BROWSER="open"
          
              # Development settings
              export NODE_OPTIONS="--max-old-space-size=4096"
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
              export PATH="$HOME/.cargo/bin:$PATH"
              export PATH="$HOME/.local/bin:$PATH"
          
              # Database settings
              export PGDATA="/usr/local/var/postgres"
              export REDIS_URL="redis://localhost:6379"
              export MONGODB_URL="mongodb://localhost:27017"
          
              # Docker settings
              export DOCKER_BUILDKIT=1
              export COMPOSE_DOCKER_CLI_BUILD=1
          
              # AWS/Cloud settings
              export AWS_REGION="us-east-1"
          
              # Security settings
              export GNUPGHOME="$HOME/.gnupg"
              export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
          
              # Custom functions for server management
          
              # Function to show server resource usage
              server-resources() {
                echo "📊 Server Resource Usage"
                echo "======================="
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
          
              # Function to check service health
              health-check() {
                echo "🏥 Service Health Check"
                echo "====================="
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
          
              # Function to tail multiple log files
              multi-tail() {
                if command -v multitail > /dev/null; then
                  multitail /usr/local/var/log/nginx/access.log /usr/local/var/log/nginx/error.log
                else
                  echo "Install multitail for better log monitoring: brew install multitail"
                  tail -f /usr/local/var/log/nginx/access.log
                fi
              }
          
              # Welcome message for server admins
              echo "🖥️  Welcome to nix-darwin Server Environment!"
              echo "⚡ Server utilities: server-resources, health-check, multi-tail"
            '';

            oh-my-zsh = {
              enable = true;
              theme = "bira"; # Clean theme with git info
              plugins = [
                "git"
                "docker"
                "kubectl"
                "terraform"
                "ansible"
                "aws"
                "node"
                "python"
                "golang"
                "rust"
              ];
            };
          };

          # Starship prompt for servers
          starship = {
            enable = true;
            settings = {
              format = lib.concatStrings [
                "$username"
                "$hostname"
                "$directory"
                "$git_branch"
                "$git_status"
                "$docker_context"
                "$kubectl_context"
                "$aws"
                "$cmd_duration"
                "$line_break"
                "$nodejs"
                "$python"
                "$golang"
                "$rust"
                "$character"
              ];

              character = {
                success_symbol = "[🖥️ ➜](bold green)";
                error_symbol = "[🖥️ ➜](bold red)";
              };

              directory = {
                style = "blue";
                truncation_length = 5;
                format = "[$path]($style) ";
              };

              hostname = {
                ssh_only = false;
                format = "[@$hostname](bold red) ";
              };

              username = {
                format = "[$user]($style)";
                style_user = "bold yellow";
                show_always = true;
              };

              git_branch = {
                format = "[$branch]($style) ";
                style = "bright-black";
              };

              git_status = {
                format = "([$all_status$ahead_behind]($style) )";
                style = "cyan";
              };

              docker_context = {
                format = "[🐳 $context](bold blue) ";
              };

              kubectl_context = {
                format = "[⎈ $context](bold purple) ";
              };

              aws = {
                format = "[☁️ $profile]($style) ";
                style = "bold orange";
              };

              cmd_duration = {
                format = "[⏱ $duration]($style) ";
                style = "yellow";
                min_time = 2000;
              };
            };
          };

          # Tmux configuration for server sessions
          tmux = {
            enable = true;
            shortcut = "a"; # Use Ctrl-a instead of Ctrl-b
            keyMode = "vi";

            extraConfig = ''
              # Server-optimized tmux configuration
          
              # Improve colors
              set -g default-terminal "screen-256color"
          
              # Set scrollback buffer
              set -g history-limit 10000
          
              # Mouse support
              set -g mouse on
          
              # Start window numbering at 1
              set -g base-index 1
              setw -g pane-base-index 1
          
              # Renumber windows when one is closed
              set -g renumber-windows on
          
              # Activity monitoring
              setw -g monitor-activity on
              set -g visual-activity on
          
              # Status bar configuration
              set -g status-bg black
              set -g status-fg white
              set -g status-left '#[fg=green]#H #[fg=yellow]#S '
              set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'
              set -g status-left-length 30
          
              # Pane borders
              set -g pane-border-style fg=black
              set -g pane-active-border-style fg=brightred
          
              # Window status format
              setw -g window-status-current-style fg=brightred,bg=black
          
              # Key bindings
              bind r source-file ~/.tmux.conf \; display "Config reloaded!"
              bind | split-window -h
              bind - split-window -v
          
              # Vim-style pane selection
              bind h select-pane -L
              bind j select-pane -D
              bind k select-pane -U
              bind l select-pane -R
          
              # Quick session switching
              bind S choose-session
          
              # Server monitoring session
              bind M new-session -d -s monitoring \; \
                send-keys 'htop' C-m \; \
                split-window -v -p 30 \; \
                send-keys 'tail -f /usr/local/var/log/nginx/access.log' C-m \; \
                select-pane -t 0
            '';
          };

          # Neovim configuration for server administration
          neovim = {
            enable = true;
            defaultEditor = true;

            extraConfig = ''
              " Server admin Neovim configuration
          
              " Basic settings
              set number
              set relativenumber
              set tabstop=2
              set shiftwidth=2
              set expandtab
              set smartindent
              set wrap
              set ignorecase
              set smartcase
              set incsearch
              set hlsearch
              set hidden
              set autoread
              set clipboard=unnamedplus
          
              " File type detection
              filetype plugin indent on
              syntax on
          
              " Color scheme
              set termguicolors
              colorscheme desert
          
              " Status line
              set statusline=%f\ %m%r%h%w\ [%Y]\ [%{&ff}]\ %=[%l,%c]\ %p%%
              set laststatus=2
          
              " Key mappings
              let mapleader = " "
          
              " File operations
              nnoremap <leader>w :w<CR>
              nnoremap <leader>q :q<CR>
              nnoremap <leader>x :x<CR>
          
              " Buffer management
              nnoremap <leader>n :bnext<CR>
              nnoremap <leader>p :bprev<CR>
              nnoremap <leader>d :bdelete<CR>
          
              " Search
              nnoremap <leader>h :nohlsearch<CR>
          
              " Git shortcuts
              nnoremap <leader>gs :!git status<CR>
              nnoremap <leader>ga :!git add %<CR>
              nnoremap <leader>gc :!git commit -m ""<Left>
              nnoremap <leader>gp :!git push<CR>
          
              " System commands
              nnoremap <leader>sh :terminal<CR>
              nnoremap <leader>ss :!server-status<CR>
          
              " Log file shortcuts
              nnoremap <leader>la :e /usr/local/var/log/nginx/access.log<CR>
              nnoremap <leader>le :e /usr/local/var/log/nginx/error.log<CR>
          
              " Configuration files
              nnoremap <leader>vc :e ~/.config/nixpkgs/home.nix<CR>
              nnoremap <leader>vz :e ~/.zshrc<CR>
          
              " Auto-reload configuration files
              autocmd BufWritePost *.nix !darwin-rebuild switch
          
              " Highlight trailing whitespace
              highlight ExtraWhitespace ctermbg=red guibg=red
              match ExtraWhitespace /\s\+$/
            '';
          };

          # Direnv for project environments
          direnv = {
            enable = true;
            nix-direnv.enable = true;
          };

          # Bat for syntax highlighted file viewing
          bat = {
            enable = true;
            config = {
              theme = "TwoDark";
              pager = "less -FR";
            };
          };
        };

        # Server configuration files
        file = {
          # Server monitoring script
          ".local/bin/server-monitor".text = ''
            #!/bin/bash
            # Continuous server monitoring
          
            while true; do
              clear
              echo "🖥️  Server Monitor - $(date)"
              echo "=========================="
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
              ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print "  " $2 " " $3 "% " $11}' 
              echo ""
            
              # Network connections
              echo "🌐 Active Connections:"
              netstat -an | grep LISTEN | wc -l | sed 's/^/  Listening ports: /'
            
              sleep 5
            done
          '';

          # Docker compose template
          "Projects/docker-compose.template.yml".text = ''
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
                  POSTGRES_DB: myapp
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

        # Make scripts executable
        home.activation = {
          makeScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            chmod +x "$HOME/.local/bin/server-monitor" 2>/dev/null || true
          '';
        };

        # XDG directories for server organization
        xdg = {
          enable = true;
          userDirs = {
            enable = true;
            createDirectories = true;
            desktop = "$HOME/Desktop";
            documents = "$HOME/Documents";
            download = "$HOME/Downloads";
            # Server-specific directories
          };
        };

        # Server environment variables
        home.sessionVariables = {
          EDITOR = "vim";
          VISUAL = "vim";
          BROWSER = "open";
          TERMINAL = "alacritty";

          # Development
          NODE_OPTIONS = "--max-old-space-size=4096";
          GOPATH = "$HOME/go";

          # Database URLs (for development)
          DATABASE_URL = "postgres://admin:password@localhost:5432/myapp";
          REDIS_URL = "redis://localhost:6379";
          MONGODB_URL = "mongodb://localhost:27017";

          # Docker
          DOCKER_BUILDKIT = "1";
          COMPOSE_DOCKER_CLI_BUILD = "1";

          # Security
          GNUPGHOME = "$HOME/.gnupg";

          # Homebrew
          HOMEBREW_NO_ANALYTICS = "1";
        };

        # Create server directory structure
        home.activation = {
          createServerDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/Server/configs"
            mkdir -p "$HOME/Server/scripts"
            mkdir -p "$HOME/Server/backups"
            mkdir -p "$HOME/Server/logs"
            mkdir -p "$HOME/Projects/servers"
            mkdir -p "$HOME/.config/server"
            mkdir -p "$HOME/.local/bin"
          
            echo "Server directory structure created"
          '';
        };
      };
    };
  };
}
