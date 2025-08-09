# Darwin Desktop Home Manager Configuration
# Uses shared profiles optimized for desktop development
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
        ../../home/profiles/desktop.nix # Desktop applications and GUI tools
        ../../home/profiles/development.nix # Development tools and environments
      ];

      # Host-specific user info
      home = {
        username = "admin";
        homeDirectory = lib.mkDefault "/Users/admin";
      };

      # Override git configuration for Darwin desktop development
      programs.git = {
        userName = "Darwin Desktop Developer";
        userEmail = "developer@darwin-desktop.local";

        extraConfig = {
          # VS Code integration for Darwin
          core.editor = "code --wait";
          diff.tool = "vscode";
          merge.tool = "vscode";
          "difftool \"vscode\".cmd" = "code --wait --diff $LOCAL $REMOTE";
          "mergetool \"vscode\".cmd" = "code --wait $MERGED";
        };
      };

      # Darwin desktop-specific environment variables
      home.sessionVariables = {
        # Desktop-optimized editor settings
        EDITOR = "code --wait";
        VISUAL = "code --wait";
        BROWSER = "open";
        TERMINAL = "alacritty";

        # Development settings for desktop workstation
        NODE_OPTIONS = "--max-old-space-size=4096"; # Full desktop resources
        PYTHONDONTWRITEBYTECODE = "1";

        # Development paths
        GOPATH = "$HOME/go";
        CARGO_HOME = "$HOME/.cargo";

        # Homebrew settings
        HOMEBREW_NO_ANALYTICS = "1";
      };

      # Darwin desktop-specific additional packages (extends profiles)
      home.packages = with pkgs; [
        # Additional terminal emulators for desktop use
        kitty
        wezterm

        # Professional IDEs for desktop development
        jetbrains.idea-community
        jetbrains.webstorm

        # Media tools for desktop content creation
        ffmpeg
        imagemagick

        # Productivity applications
        obsidian

        # Advanced development tools
        git-lfs # Large file support
      ];

      # Darwin desktop-specific shell aliases (extends base profile)
      programs.zsh.shellAliases = {
        # Development shortcuts optimized for desktop workflow
        "npm-update" = "npm update && npm audit fix";
        "py" = "python3";

        # macOS desktop-specific shortcuts
        "showfiles" = "defaults write com.apple.finder AppleShowAllFiles YES; killall Finder";
        "hidefiles" = "defaults write com.apple.finder AppleShowAllFiles NO; killall Finder";

        # Desktop project shortcuts
        "dev" = "cd ~/Development";
        "proj" = "cd ~/Projects";
        "code-here" = "code .";
      };

      # Darwin desktop-specific zsh enhancements
      programs.zsh.initExtra = ''
        # Darwin desktop environment setup

        # Desktop-optimized FZF configuration
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --preview 'bat --color=always --style=header,grid {}'"

        # Desktop development paths
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
        export PATH="$GOPATH/bin:$PATH"

        # Darwin desktop welcome message
        echo "🖥️  Darwin Desktop Development Environment"
        echo "🚀 Full-featured workstation ready for development"
        echo "💻 IDEs: VS Code, IntelliJ IDEA, WebStorm"
      '';

      # Enhanced Alacritty configuration for desktop use
      programs.alacritty = {
        enable = true;
        settings = {
          window = {
            decorations = "full";
            opacity = 0.9;
            startup_mode = "Windowed";
            dimensions = {
              columns = 120;
              lines = 40; # Larger for desktop screens
            };
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
            size = 14; # Larger for desktop displays
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
            { key = "T"; mods = "Command"; action = "CreateNewTab"; }
          ];
        };
      };

      # Darwin desktop development configuration files
      home.file = {
        # Enhanced VS Code settings for desktop development
        ".vscode/settings.json".text = builtins.toJSON {
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "editor.fontSize" = 14;
          "editor.lineHeight" = 1.5;
          "editor.fontLigatures" = true;
          "editor.formatOnSave" = true;
          "editor.codeActionsOnSave" = {
            "source.fixAll" = true;
            "source.organizeImports" = true;
          };
          "workbench.colorTheme" = "Dark+ (default dark)";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "terminal.integrated.fontSize" = 13;

          # Desktop-optimized settings
          "editor.minimap.enabled" = true;
          "workbench.sideBar.location" = "left";
          "explorer.confirmDragAndDrop" = false;
          "files.autoSave" = "onWindowChange";
        };

        # Prettier configuration for consistent formatting
        ".prettierrc".text = builtins.toJSON {
          semi = true;
          trailingComma = "es5";
          singleQuote = true;
          printWidth = 80;
          tabWidth = 2;
          useTabs = false;
        };

        # ESLint configuration for JavaScript/TypeScript
        ".eslintrc.json".text = builtins.toJSON {
          env = {
            browser = true;
            es2021 = true;
            node = true;
          };
          extends = [
            "eslint:recommended"
            "@typescript-eslint/recommended"
          ];
          parserOptions = {
            ecmaVersion = "latest";
            sourceType = "module";
          };
          rules = {
            "no-console" = "warn";
            "no-unused-vars" = "error";
          };
        };
      };

      # Create Darwin desktop-specific development structure
      home.activation = {
        createDarwinDesktopDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    mkdir -p "$HOME/Development"
                    mkdir -p "$HOME/Projects/Web"
                    mkdir -p "$HOME/Projects/Mobile"
                    mkdir -p "$HOME/Projects/Desktop"
                    mkdir -p "$HOME/Projects/Scripts"
                    mkdir -p "$HOME/.config/development"
                    mkdir -p "$HOME/.local/bin"

                    # Create development shortcuts
                    cat > "$HOME/.local/bin/new-project" << 'EOF'
          #!/bin/bash
          echo "🚀 New Darwin Desktop Project Setup"
          if [ -z "$1" ]; then
            echo "Usage: new-project <project-name> [web|mobile|desktop|script]"
            exit 1
          fi

          project_name="$1"
          project_type="''${2:-web}"

          case "$project_type" in
            "web"|"frontend"|"react"|"vue")
              project_dir="$HOME/Projects/Web/$project_name"
              ;;
            "mobile"|"ios"|"android"|"flutter")
              project_dir="$HOME/Projects/Mobile/$project_name"
              ;;
            "desktop"|"electron"|"tauri")
              project_dir="$HOME/Projects/Desktop/$project_name"
              ;;
            "script"|"automation")
              project_dir="$HOME/Projects/Scripts/$project_name"
              ;;
            *)
              project_dir="$HOME/Projects/$project_name"
              ;;
          esac

          mkdir -p "$project_dir"
          cd "$project_dir"
          echo "📁 Created project: $project_dir"

          # Initialize common files
          echo "# $project_name" > README.md
          echo "node_modules/" > .gitignore
          git init

          echo "✅ Project $project_name created successfully!"
          echo "📂 Location: $project_dir"
          code "$project_dir"
          EOF
                    chmod +x "$HOME/.local/bin/new-project"

                    echo "Darwin desktop development environment created"
                    echo "💡 Use 'new-project <name> [type]' to create new projects"
        '';
      };
    };
  };
}
