# Home Manager configuration for nix-darwin Desktop
# User-specific configuration and applications

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
      home.stateVersion = "24.11"; # Match your Home Manager version

      # User packages
      home.packages = with pkgs; [
        # Terminal applications
        alacritty
        kitty
        wezterm

        # Development tools
        vscode
        jetbrains.idea-community
        jetbrains.webstorm

        # Version control
        git
        gh
        git-lfs

        # Languages and runtimes
        nodejs_20
        python311
        rustc
        cargo
        go

        # Database tools
        postgresql
        redis

        # Cloud and DevOps
        docker
        kubectl
        terraform
        ansible

        # Productivity
        obsidian
        notion

        # Media tools
        ffmpeg
        imagemagick

        # System utilities
        htop
        btop
        tree
        fd
        ripgrep
        bat
        eza
        zoxide
        fzf
      ];

      # Git configuration
      programs.git = {
        enable = true;
        userName = lib.mkDefault "Your Name";
        userEmail = lib.mkDefault "your.email@example.com";

        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core = {
            editor = "code --wait";
            autocrlf = "input";
          };
          diff = {
            tool = "vscode";
          };
          merge = {
            tool = "vscode";
          };
          "difftool \"vscode\"" = {
            cmd = "code --wait --diff $LOCAL $REMOTE";
          };
          "mergetool \"vscode\"" = {
            cmd = "code --wait $MERGED";
          };
        };
      };

      # Shell configuration
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = {
          # Navigation
          ll = "eza -la";
          ls = "eza";
          la = "eza -a";
          tree = "eza --tree";

          # Git shortcuts
          g = "git";
          gs = "git status";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git pull";
          gco = "git checkout";
          gb = "git branch";
          gd = "git diff";
          glog = "git log --oneline --graph --decorate";

          # Development shortcuts
          code = "code .";
          npm-update = "npm update && npm audit fix";
          py = "python3";

          # System shortcuts
          reload = "source ~/.zshrc";
          ..= "cd ..";
          ... = "cd ../..";

          # macOS specific
          showfiles = "defaults write com.apple.finder AppleShowAllFiles YES; killall Finder";
          hidefiles = "defaults write com.apple.finder AppleShowAllFiles NO; killall Finder";
        };

        initContent = ''
          # Load direnv
          eval "$(direnv hook zsh)"
          
          # Initialize zoxide
          eval "$(zoxide init zsh)"
          
          # FZF configuration
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          
          # Development environment variables
          export EDITOR="code --wait"
          export VISUAL="code --wait"
          
          # Node.js configuration
          export NODE_OPTIONS="--max-old-space-size=4096"
          
          # Go configuration
          export GOPATH="$HOME/go"
          export PATH="$GOPATH/bin:$PATH"
          
          # Rust configuration
          export PATH="$HOME/.cargo/bin:$PATH"
          
          # Python configuration
          export PATH="$HOME/.local/bin:$PATH"
          
          # Welcome message
          echo "👋 Welcome to your nix-darwin desktop environment!"
          echo "🚀 Happy coding!"
        '';

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [
            "git"
            "docker"
            "npm"
            "node"
            "python"
            "rust"
            "golang"
            "kubectl"
            "terraform"
            "macos"
          ];
        };
      };

      # Starship prompt
      programs.starship = {
        enable = true;
        settings = {
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$cmd_duration"
            "$line_break"
            "$python"
            "$nodejs"
            "$rust"
            "$golang"
            "$docker_context"
            "$character"
          ];

          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[➜](bold red)";
          };

          directory = {
            style = "blue";
            truncation_length = 4;
            truncation_symbol = "…/";
          };

          git_branch = {
            format = "[$branch]($style)";
            style = "bright-black";
          };

          git_status = {
            format = "([\\[$all_status$ahead_behind\\]]($style) )";
            style = "cyan";
          };

          nodejs = {
            format = "[$symbol($version )]($style)";
            symbol = "⬢ ";
          };

          python = {
            format = "[$symbol($version )]($style)";
            symbol = "🐍 ";
          };

          rust = {
            format = "[$symbol($version )]($style)";
            symbol = "🦀 ";
          };

          golang = {
            format = "[$symbol($version )]($style)";
            symbol = "🐹 ";
          };
        };
      };

      # Direnv for development environments
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      # FZF fuzzy finder
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      # Bat (better cat)
      programs.bat = {
        enable = true;
        config = {
          theme = "TwoDark";
          pager = "less -FR";
        };
      };

      # Alacritty terminal emulator
      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            decorations = "full";
            opacity = 0.9;
            startup_mode = "Windowed";
          };

          font = {
            normal = {
              family = "JetBrainsMono Nerd Font";
              style = "Regular";
            };
            bold = {
              family = "JetBrainsMono Nerd Font";
              style = "Bold";
            };
            italic = {
              family = "JetBrainsMono Nerd Font";
              style = "Italic";
            };
            size = 14;
          };

          colors = {
            primary = {
              background = "0x1d1f21";
              foreground = "0xc5c8c6";
            };
          };

          key_bindings = [
            { key = "V"; mods = "Command"; action = "Paste"; }
            { key = "C"; mods = "Command"; action = "Copy"; }
            { key = "N"; mods = "Command"; action = "SpawnNewInstance"; }
          ];
        };
      };

      # Development configuration files
      home.file = {
        # VS Code settings
        ".vscode/settings.json".text = builtins.toJSON {
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "editor.fontSize" = 14;
          "editor.lineHeight" = 1.5;
          "editor.fontLigatures" = true;
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = true;
          };
          "workbench.colorTheme" = "Dark+ (default dark)";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        };

        # Prettier configuration
        ".prettierrc".text = builtins.toJSON {
          semi = true;
          trailingComma = "es5";
          singleQuote = true;
          printWidth = 80;
          tabWidth = 2;
        };

        # ESLint configuration
        ".eslintrc.json".text = builtins.toJSON {
          env = {
            browser = true;
            es2021 = true;
            node = true;
          };
          extends = [
            "eslint:recommended"
          ];
          parserOptions = {
            ecmaVersion = "latest";
            sourceType = "module";
          };
        };
      };

      # XDG directories
      xdg = {
        enable = true;

        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "$HOME/Desktop";
          documents = "$HOME/Documents";
          download = "$HOME/Downloads";
          music = "$HOME/Music";
          pictures = "$HOME/Pictures";
          videos = "$HOME/Videos";
          templates = "$HOME/Templates";
          publicShare = "$HOME/Public";
        };
      };

      # Session variables
      home.sessionVariables = {
        EDITOR = "code --wait";
        BROWSER = "open";
        TERMINAL = "alacritty";

        # Development paths
        GOPATH = "$HOME/go";
        CARGO_HOME = "$HOME/.cargo";

        # Node.js settings
        NODE_OPTIONS = "--max-old-space-size=4096";

        # Python settings
        PYTHONDONTWRITEBYTECODE = "1";

        # Homebrew settings
        HOMEBREW_NO_ANALYTICS = "1";
      };

      # Create development directories
      home.activation = {
        createDevelopmentDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Development"
          mkdir -p "$HOME/Projects"
          mkdir -p "$HOME/.config"
          mkdir -p "$HOME/.local/bin"
          
          echo "Development directories created"
        '';
      };
    };
  };
}
