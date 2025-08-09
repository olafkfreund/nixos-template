# Darwin Laptop Home Manager Configuration
# Uses shared profiles optimized for mobile computing
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
        ../../home/profiles/desktop.nix # Desktop applications and GUI tools (selective)
        ../../home/profiles/development.nix # Development tools
      ];

      # Host-specific user info
      home = {
        username = "admin";
        homeDirectory = lib.mkDefault "/Users/admin";
      };

      # Override git configuration for Darwin laptop
      programs.git = {
        userName = "Darwin Laptop User";
        userEmail = "laptop-user@darwin-laptop.local";

        extraConfig = {
          # Mobile-optimized settings
          core.compression = 9; # Better for limited bandwidth
          core.preloadindex = true; # Faster index operations
          gc.auto = 256; # Less frequent garbage collection
          pack.threads = 2; # Limit CPU usage for battery life
        };
      };

      # Darwin laptop-specific environment variables
      home.sessionVariables = {
        # Power-aware editor selection (overrides base profile)
        EDITOR = "vim"; # Lightweight for battery life
        BROWSER = "open";
        TERMINAL = "alacritty";

        # Development settings optimized for mobile/battery
        NODE_OPTIONS = "--max-old-space-size=2048"; # Conservative memory usage
        PYTHONDONTWRITEBYTECODE = "1"; # Skip bytecode generation

        # Mobile-friendly paths
        GOPATH = "$HOME/go";
        CARGO_HOME = "$HOME/.cargo";

        # Homebrew mobile settings
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_AUTO_UPDATE = "1"; # Save bandwidth and battery
      };

      # Laptop-specific additional packages (extends profiles)
      home.packages = with pkgs; [
        # Mobile development tools
        alacritty # Lightweight terminal optimized for battery life

        # Battery monitoring tools
        powertop # If available on Darwin

        # Lightweight alternatives
        fzf # Fast fuzzy finder
      ];

      # Darwin laptop-specific shell aliases (extends base profile)
      programs.zsh.shellAliases = {
        # Battery and system monitoring (Darwin-specific)
        "battery" = "pmset -g batt";
        "temp" = "sudo powermetrics --samplers smc_temp --sample-count 1 -n 1";
        "sleep" = "pmset sleepnow";
        "caffeinate" = "caffeinate -d"; # Prevent display sleep

        # Network utilities optimized for mobile
        "wifi" = "networksetup -getairportpower en0";
        "wifi-scan" = "airport -s";
        "wifi-info" = "iwgetid";

        # Power-efficient shortcuts
        "cleanup" = "sudo purge && nix-collect-garbage -d";

        # Mobile development shortcuts
        "mobile-dev" = "$HOME/.local/bin/mobile-dev";
        "quick-proj" = "cd ~/Projects/Quick";
      };

      # Darwin laptop-specific bash aliases (extends base profile)
      programs.bash.shellAliases = {
        # Battery monitoring for bash users
        "battery" = "pmset -g batt | head -2";
        "power-status" = "pmset -g batt && pmset -g ps";

        # WiFi management
        "wifi" = "networksetup -getairportpower en0";
      };

      # Darwin laptop-specific zsh enhancements
      programs.zsh.initExtra = ''
        # Darwin laptop mobile optimizations

        # Check power source and optimize accordingly
        if pmset -g batt | grep -q "Battery Power"; then
          # On battery - optimize for power saving
          export NODE_OPTIONS="--max-old-space-size=1024"
          export EDITOR="vim"
          export VISUAL="vim"
          export BATTERY_STATUS="🔋"

          # Reduce shell features for battery life
          export HISTSIZE=1000
        else
          # On AC power - allow more resources
          export NODE_OPTIONS="--max-old-space-size=4096"
          export EDITOR="code --wait"
          export VISUAL="code --wait"
          export BATTERY_STATUS="🔌"

          # Full shell features on AC power
          export HISTSIZE=10000
        fi

        # Mobile-friendly FZF setup
        if command -v fzf > /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --follow --exclude .git'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
        fi

        # Quick battery status function
        battery-status() {
          local battery_level=$(pmset -g batt | grep -E "([0-9]+%)" | awk '{print $3}' | tr -d ';')
          local power_source=$(pmset -g batt | grep -o 'AC Power\|Battery Power')
          echo "🔋 Battery: $battery_level ($power_source)"
        }

        # Power profile switching
        power-profile() {
          case "$1" in
            "save"|"battery")
              echo "🔋 Switching to battery-optimized profile"
              export NODE_OPTIONS="--max-old-space-size=1024"
              export EDITOR="vim"
              ;;
            "performance"|"ac")
              echo "🔌 Switching to performance profile"
              export NODE_OPTIONS="--max-old-space-size=4096"
              export EDITOR="code --wait"
              ;;
            *)
              echo "Usage: power-profile [save|battery|performance|ac]"
              ;;
          esac
        }

        # Darwin laptop welcome message
        echo "💻 Darwin Laptop Environment"
        battery-status
        echo "⚡ Mobile utilities: battery-status, power-profile"
      '';

      # Enhanced starship configuration for mobile (battery indicator)
      programs.starship.settings = {
        # Add battery module to format
        format = lib.mkForce (lib.concatStrings [
          "$directory"
          "$git_branch"
          "$git_status"
          "$nodejs"
          "$python"
          "$battery"
          "$character"
        ]);

        # Battery status in prompt
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

        # Shorter directory paths for mobile screens
        directory = {
          truncation_length = 3;
          truncation_symbol = "../";
        };
      };

      # Lightweight Alacritty configuration for battery life
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
            size = 13; # Optimized for laptop screens
          };

          colors = {
            primary = {
              background = "0x1d1f21";
              foreground = "0xc5c8c6";
            };
          };

          # Battery-friendly settings
          scrolling = {
            history = 5000; # Smaller history for memory efficiency
          };

          key_bindings = [
            { key = "V"; mods = "Command"; action = "Paste"; }
            { key = "C"; mods = "Command"; action = "Copy"; }
          ];
        };
      };

      # Darwin laptop configuration files
      home.file = {
        # Minimal VS Code settings optimized for battery/mobile use
        ".vscode/settings.json".text = builtins.toJSON {
          "editor.fontFamily" = "JetBrainsMono Nerd Font";
          "editor.fontSize" = 13;
          "editor.fontLigatures" = true;
          "editor.formatOnSave" = true;
          "workbench.colorTheme" = "Dark+ (default dark)";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";

          # Battery-friendly settings
          "editor.renderWhitespace" = "none";
          "editor.minimap.enabled" = false;
          "workbench.reduceMotion" = "on";
          "extensions.autoUpdate" = false;
          "workbench.startupEditor" = "none";
          "files.autoSave" = "onFocusChange"; # Save battery with less frequent writes
        };

        # Mobile Git workflow configuration
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
            mobile = "!echo 'Mobile Git shortcuts loaded'"
        '';
      };

      # Create Darwin laptop-specific development structure
      home.activation = {
        createDarwinLaptopDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    mkdir -p "$HOME/Projects/Mobile"
                    mkdir -p "$HOME/Projects/Quick"
                    mkdir -p "$HOME/.config/laptop"
                    mkdir -p "$HOME/.local/bin"

                    # Create mobile development mode script
                    cat > "$HOME/.local/bin/mobile-dev" << 'EOF'
          #!/bin/bash
          echo "📱 Darwin Mobile Development Mode"
          export NODE_OPTIONS="--max-old-space-size=1024"
          export EDITOR="vim"
          export VISUAL="vim"
          cd ~/Projects/Mobile
          echo "🔋 Optimized for battery life"
          exec $SHELL
          EOF
                    chmod +x "$HOME/.local/bin/mobile-dev"

                    # Create quick project script
                    cat > "$HOME/.local/bin/quick-proj" << 'EOF'
          #!/bin/bash
          echo "⚡ Quick Project Setup"
          cd ~/Projects/Quick
          if [ ! -d "$(date +%Y-%m-%d)" ]; then
            mkdir "$(date +%Y-%m-%d)"
            echo "Created project directory: $(date +%Y-%m-%d)"
          fi
          cd "$(date +%Y-%m-%d)"
          exec $SHELL
          EOF
                    chmod +x "$HOME/.local/bin/quick-proj"

                    echo "Darwin laptop mobile development environment created"
        '';
      };
    };
  };
}
