# WSL2 Template Home Manager Configuration
# Uses shared profiles optimized for Windows Subsystem for Linux development
{ config, pkgs, ... }:

{
  # Import shared Home Manager profiles
  imports = [
    ../../home/profiles/base.nix # Base configuration with git, bash, etc.
    ../../home/profiles/development.nix # Development tools and environments
    # Note: Not importing desktop profile as WSL2 is typically headless
  ];

  # Host-specific user info (REQUIRED - must be customized per user)
  home = {
    username = "nixos"; # Change to your username
    homeDirectory = "/home/nixos"; # Change to your home directory
  };

  # Override git configuration with user-specific details (REQUIRED)
  programs.git = {
    userName = "Your Name"; # Change to your name
    userEmail = "your.email@example.com"; # Change to your email
  };

  # WSL2-specific environment variables
  home.sessionVariables = {
    # WSL2 integration
    DISPLAY = ":0"; # For X11 forwarding if needed
    PULSE_RUNTIME_PATH = "/mnt/wslg/pulse"; # WSLg audio support

    # Development optimizations for WSL2
    EDITOR = "code"; # VS Code integration
    BROWSER = "/mnt/c/Program Files/Mozilla Firefox/firefox.exe"; # Windows browser

    # WSL2 performance
    WSLENV = "PATH/l"; # Environment variable passing
  };

  # WSL2-specific packages (extends development profile)
  home.packages = with pkgs; [
    # Windows integration tools
    wslu # WSL utilities

    # Network tools for WSL2 development
    socat # For port forwarding
    netcat # Network testing

    # File system utilities for Windows integration
    unzip
    p7zip

    # Development tools optimized for WSL2
    nodejs_20 # Latest Node.js for web development
    python311 # Python for scripting

    # WSL2-specific utilities
    procps # Process utilities
    psmisc # Additional process tools
  ];

  # WSL2-specific shell configuration
  programs.zsh = {
    enable = true;

    # WSL2-specific aliases (extends base profile)
    shellAliases = {
      # Windows integration
      "explorer" = "explorer.exe";
      "notepad" = "notepad.exe";
      "code" = "code.exe";
      "pwsh" = "powershell.exe";
      "cmd" = "cmd.exe";

      # WSL2 management
      "wsl-shutdown" = "wsl.exe --shutdown";
      "wsl-restart" = "wsl.exe --terminate $WSL_DISTRO_NAME && wsl.exe -d $WSL_DISTRO_NAME";
      "wsl-info" = "wsl.exe --status";

      # Windows path navigation
      "cdc" = "cd /mnt/c/";
      "cdd" = "cd /mnt/d/";
      "cdwin" = "cd /mnt/c/Users/$USER/";
      "cddesk" = "cd /mnt/c/Users/$USER/Desktop/";
      "cddocs" = "cd /mnt/c/Users/$USER/Documents/";

      # Development shortcuts optimized for WSL2
      "serve" = "python -m http.server 8000";
      "json" = "python -m json.tool";
      "ports" = "netstat -tuln";

      # File operations with Windows integration
      "open" = "explorer.exe";
      "clip" = "clip.exe"; # Copy to Windows clipboard
    };

    # WSL2-specific Zsh configuration
    initExtra = ''
      # WSL2 environment setup
      export WSL_DISTRO_NAME=$(cat /proc/version | grep -oP 'Microsoft.*' | head -1 || echo "WSL2")

      # Windows PATH integration (selective)
      export PATH="$PATH:/mnt/c/Windows/System32:/mnt/c/Windows"

      # WSL2 prompt with Windows integration indicator
      autoload -U colors && colors
      PS1="%{$fg[cyan]%}[WSL2:%{$fg[green]%}%n%{$fg[cyan]%}@%{$fg[blue]%}%m]%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%}$ "

      # WSL2 helper functions
      wsl-ip() {
        ip route show | grep -i default | awk '{ print $3}'
      }

      win-path() {
        wslpath -w "$1"
      }

      linux-path() {
        wslpath -u "$1"
      }

      # Quick Windows application launchers
      vscode() {
        if [ $# -eq 0 ]; then
          code.exe .
        else
          code.exe "$@"
        fi
      }

      # WSL2 system information
      wsl-info() {
        echo "=== WSL2 System Information ==="
        echo "Distribution: $WSL_DISTRO_NAME"
        echo "Kernel: $(uname -r)"
        echo "WSL Version: $(cat /proc/version | grep -oP 'Microsoft.*')"
        echo "Windows IP: $(wsl-ip)"
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"
      }

      # Show WSL2 info on login
      echo "🐧 WSL2 Environment: $WSL_DISTRO_NAME"
      echo "💻 Windows Integration: $(wsl-ip)"
    '';
  };

  # Enhanced bash configuration for users who prefer bash
  programs.bash = {
    shellAliases = {
      # Windows integration (same as zsh)
      "explorer" = "explorer.exe";
      "notepad" = "notepad.exe";
      "code" = "code.exe";
      "pwsh" = "powershell.exe";

      # WSL2 management
      "wsl-shutdown" = "wsl.exe --shutdown";
      "wsl-info" = "echo 'WSL2:' $WSL_DISTRO_NAME '| IP:' $(ip route show | grep default | awk '{print $3}')";

      # Windows path shortcuts
      "cdc" = "cd /mnt/c/";
      "cdwin" = "cd /mnt/c/Users/$USER/";
    };

    bashrcExtra = ''
      # WSL2 environment identification
      export WSL_DISTRO_NAME=$(cat /proc/version | grep -oP 'Microsoft.*' | head -1 || echo "WSL2")

      # WSL2-optimized prompt
      PS1="\[\e[36m\][WSL2:\[\e[32m\]\u\[\e[36m\]@\[\e[34m\]\h]\[\e[0m\] \[\e[33m\]\w\[\e[0m\]$ "

      # Show WSL2 status on login
      echo "🐧 WSL2 Development Environment"
      echo "📊 $(free -h | awk '/^Mem:/ {print "Memory: " $3 "/" $2}') | $(df -h / | awk 'NR==2 {print "Disk: " $5}')"
    '';
  };

  # WSL2-specific Git configuration
  programs.git.extraConfig = {
    # Windows line ending handling
    core.autocrlf = "input";
    core.eol = "lf";

    # WSL2 performance optimizations
    core.preloadindex = true;
    core.fscache = true;

    # Windows credential integration
    credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
  };
}
