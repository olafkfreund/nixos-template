# Home Manager configuration for nix-darwin Laptop
# Mobile-optimized user environment

{ config, pkgs, lib, inputs, outputs, ... }:

{
  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.admin = { config, pkgs, ... }: {
      # User information
      home.username = "admin";
      home.homeDirectory = lib.mkDefault "/Users/admin";
      home.stateVersion = "25.05";

      # Laptop-optimized packages (minimal for battery life)
      home.packages = with pkgs; [
        # Essential terminal tools
        alacritty # Lightweight terminal

        # Lightweight development tools
        vim
        neovim
        git
        gh

        # Essential languages (minimal)
        nodejs_20
        python311

        # Lightweight system utilities
        htop
        tree
        fd
        ripgrep
        bat
        eza
        fzf

        # Network tools for mobile use
        curl
        wget

        # Archive tools
        unzip
      ];

      # Git configuration optimized for mobile
      programs.git = {
        enable = true;
        userName = lib.mkDefault "Your Name";
        userEmail = lib.mkDefault "your.email@example.com";

        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core = {
            editor = "vim"; # Lightweight editor
            autocrlf = "input";
            # Optimize for mobile/limited bandwidth
            compression = 9;
            preloadindex = true;
          };
          # Battery-friendly settings
          gc = {
            auto = 256; # Less frequent garbage collection
          };
          pack = {
            threads = 2; # Limit CPU usage
          };
        };
      };

      # Lightweight shell configuration
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          # Battery-aware navigation
          ll = "eza -la --icons";
          ls = "eza --icons";
          la = "eza -a --icons";
          tree = "eza --tree --icons";

          # Quick git (mobile-friendly)
          g = "git";
          gs = "git status -s";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git pull";
          gco = "git checkout";
          gb = "git branch";
          gd = "git diff";

          # Mobile development
          code = "code .";
          vim = "nvim"; # Use neovim

          # System shortcuts
          reload = "source ~/.zshrc";
          .. = "cd ..";
          ... = "cd ../..";

          # Battery and system
          battery = "pmset -g batt";
          temp = "sudo powermetrics --samplers smc_temp --sample-count 1 -n 1";

          # Network (mobile-friendly)
          ip = "curl -s ifconfig.me && echo";
          wifi = "networksetup -getairportpower en0";

          # Cleanup shortcuts
          cleanup = "sudo purge && nix-collect-garbage -d";

          # macOS laptop specific
          sleep = "pmset sleepnow";
          caffeinate = "caffeinate -d"; # Prevent display sleep
        };

        initContent = ''
          # Mobile-optimized environment
          
          # Check power source and optimize accordingly
          if pmset -g batt | grep -q "Battery Power"; then
            # On battery - optimize for power saving
            export NODE_OPTIONS="--max-old-space-size=2048"
            export EDITOR="vim"
            export VISUAL="vim"
            
            # Show battery status in prompt
            export BATTERY_STATUS="🔋"
          else
            # On AC power - allow more resources
            export NODE_OPTIONS="--max-old-space-size=4096"
            export EDITOR="code --wait"
            export VISUAL="code --wait"
            
            export BATTERY_STATUS="🔌"
          fi
          
          # Load direnv (but with timeout for mobile)
          if command -v direnv > /dev/null; then
            eval "$(timeout 5 direnv hook zsh)" 2>/dev/null || echo "direnv timeout (mobile optimization)"
          fi
          
          # Quick zoxide initialization
          if command -v zoxide > /dev/null; then
            eval "$(zoxide init zsh)"
          fi
          
          # Lightweight FZF setup
          if command -v fzf > /dev/null; then
            export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'
            export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          fi
          
          # Development paths
          export PATH="$HOME/.local/bin:$PATH"
          export PATH="$HOME/.cargo/bin:$PATH"
          export GOPATH="$HOME/go"
          export PATH="$GOPATH/bin:$PATH"
          
          # Mobile-friendly welcome
          echo "💻 Welcome to your mobile nix-darwin environment!"
          echo "$BATTERY_STATUS $(pmset -g batt | grep -E "([0-9]+%)" | awk '{print $3}' | tr -d ';' 2>/dev/null || echo 'Power status unknown')"
        '';

        oh-my-zsh = {
          enable = true;
          theme = "clean"; # Lightweight theme
          plugins = [
            "git"
            "macos"
            "battery" # Show battery status
          ];
        };
      };

      # Lightweight Starship prompt
      programs.starship = {
        enable = true;
        settings = {
          format = lib.concatStrings [
            "$directory"
            "$git_branch"
            "$git_status"
            "$nodejs"
            "$python"
            "$battery"
            "$character"
          ];

          # Simplified prompt for mobile
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };

          directory = {
            style = "blue";
            truncation_length = 3; # Shorter paths for mobile
            truncation_symbol = "../";
          };

          git_branch = {
            format = "[$branch]($style) ";
            style = "bright-black";
          };

          git_status = {
            format = "([$all_status$ahead_behind]($style) )";
            style = "cyan";
          };

          # Show battery status in prompt
          battery = {
            full_symbol = "🔋";
            charging_symbol = "⚡️";
            discharging_symbol = "💀";
            display = [
              {
                threshold = 15;
                style = "bold red";
              }
              {
                threshold = 50;
                style = "bold yellow";
              }
            ];
          };

          nodejs = {
            format = "[$symbol($version )]($style)";
            symbol = "⬢ ";
            detect_files = [ "package.json" ];
          };

          python = {
            format = "[$symbol($version )]($style)";
            symbol = "🐍 ";
            detect_files = [ "requirements.txt" "pyproject.toml" ];
          };
        };
      };

      # Direnv (with mobile optimizations)
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global = {
            # Mobile-friendly timeouts
            load_dotenv = true;
            strict_env = true;
          };
        };
      };

      # FZF with mobile optimizations
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultOptions = [
          "--height 40%"
          "--layout=reverse"
          "--border"
        ];
      };

      # Bat configuration
      programs.bat = {
        enable = true;
        config = {
          theme = "TwoDark";
          pager = "less -FR";
        };
      };

      # Lightweight Alacritty configuration
      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            decorations = "full";
            opacity = 0.95; # Slightly more opaque for battery life
            startup_mode = "Windowed";
            dimensions = {
              columns = 120;
              lines = 30;
            };
          };

          font = {
            normal = {
              family = "JetBrainsMono Nerd Font";
              style = "Regular";
            };
            size = 13; # Smaller for laptop screens
          };

          colors = {
            primary = {
              background = "0x1d1f21";
              foreground = "0xc5c8c6";
            };
          };

          # Battery-friendly settings
          scrolling = {
            history = 5000; # Smaller history
          };

          key_bindings = [
            { key = "V"; mods = "Command"; action = "Paste"; }
            { key = "C"; mods = "Command"; action = "Copy"; }
          ];
        };
      };

      # Neovim configuration for mobile development
      programs.neovim = {
        enable = true;
        defaultEditor = true;

        extraConfig = ''
          " Mobile-optimized Neovim configuration
          
          " Basic settings
          set number
          set relativenumber
          set tabstop=2
          set shiftwidth=2
          set expandtab
          set smartindent
          set wrap
          
          " Battery-friendly settings
          set lazyredraw
          set ttyfast
          
          " Search settings
          set ignorecase
          set smartcase
          set incsearch
          set hlsearch
          
          " File handling
          set hidden
          set autoread
          
          " Appearance
          set termguicolors
          colorscheme desert
          
          " Status line
          set statusline=%f\ %m%r%h%w\ [%Y]\ [%{&ff}]\ %=[%l,%c]\ %p%%
          set laststatus=2
          
          " Key mappings for mobile use
          let mapleader = " "
          
          " Quick save and quit
          nnoremap <leader>w :w<CR>
          nnoremap <leader>q :q<CR>
          
          " Buffer navigation
          nnoremap <leader>n :bnext<CR>
          nnoremap <leader>p :bprev<CR>
          
          " Clear search highlighting
          nnoremap <leader>h :nohlsearch<CR>
          
          " Git shortcuts
          nnoremap <leader>gs :!git status<CR>
          nnoremap <leader>ga :!git add %<CR>
          nnoremap <leader>gc :!git commit -m ""<Left>
          
          " Mobile-friendly settings
          set mouse=a
          set clipboard=unnamedplus
        '';
      };

      # Mobile-optimized development files
      home.file = {
        # Minimal VS Code settings for when on AC power
        ".vscode/settings.json".text = builtins.toJSON {
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "editor.fontSize" = 13;
          "editor.lineHeight" = 1.4;
          "editor.fontLigatures" = true;
          "editor.formatOnSave" = true;
          "workbench.colorTheme" = "Dark+ (default dark)";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "terminal.integrated.fontSize" = 12;

          # Battery-friendly settings
          "editor.renderWhitespace" = "none";
          "editor.minimap.enabled" = false;
          "workbench.reduceMotion" = "on";
          "extensions.autoUpdate" = false;
        };

        # Git configuration for mobile workflows
        ".gitconfig-mobile".text = ''
          [core]
            editor = vim
            compression = 9
          [push]
            default = simple
          [pull]
            rebase = true
          [alias]
            s = status -s
            co = checkout
            br = branch
            ci = commit
            st = status
            unstage = reset HEAD --
            last = log -1 HEAD
            visual = !gitk
        '';
      };

      # XDG directories optimized for mobile use
      xdg = {
        enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          # Standard directories
          desktop = "$HOME/Desktop";
          documents = "$HOME/Documents";
          download = "$HOME/Downloads";
          pictures = "$HOME/Pictures";
          # Mobile-specific
          templates = "$HOME/Templates";
        };
      };

      # Mobile-optimized session variables
      home.sessionVariables = {
        # Power-aware editor selection
        EDITOR = "vim";
        BROWSER = "open";
        TERMINAL = "alacritty";

        # Development settings optimized for mobile
        NODE_OPTIONS = "--max-old-space-size=2048"; # Conservative memory usage
        PYTHONDONTWRITEBYTECODE = "1";

        # Git settings for mobile
        GIT_EDITOR = "vim";

        # Mobile-friendly paths
        GOPATH = "$HOME/go";
        CARGO_HOME = "$HOME/.cargo";

        # Homebrew mobile settings
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_AUTO_UPDATE = "1"; # Save bandwidth
      };

      # Create mobile-optimized development structure
      home.activation = {
        createMobileDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Projects/Mobile"
          mkdir -p "$HOME/Projects/Quick"
          mkdir -p "$HOME/.config"
          mkdir -p "$HOME/.local/bin"
          
          # Create mobile development shortcuts
          echo '#!/bin/bash' > "$HOME/.local/bin/mobile-dev"
          echo 'echo "📱 Mobile Development Mode"' >> "$HOME/.local/bin/mobile-dev"
          echo 'export NODE_OPTIONS="--max-old-space-size=1024"' >> "$HOME/.local/bin/mobile-dev"
          echo 'export EDITOR="vim"' >> "$HOME/.local/bin/mobile-dev"
          echo 'cd ~/Projects/Mobile' >> "$HOME/.local/bin/mobile-dev"
          chmod +x "$HOME/.local/bin/mobile-dev"
          
          echo "Mobile development directories and tools created"
        '';
      };
    };
  };
}
