# Test Gaming Home Manager Configuration
# Uses shared profiles optimized for gaming and testing
{ config, pkgs, ... }:

{
  # Import shared Home Manager profiles
  imports = [
    ../../home/profiles/base.nix # Base configuration with git, bash, etc.
    ../../home/profiles/desktop.nix # Desktop applications and GUI tools
    ../../home/roles/gamer.nix # Gaming-specific tools and configurations
  ];

  # Host-specific user info
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # Override git configuration for gaming tests
  programs.git = {
    userName = "Test Gamer";
    userEmail = "gamer@test-gaming.local";
  };

  # Gaming-specific environment optimizations
  home.sessionVariables = {
    # Performance optimization for gaming
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia";

    # Gaming-specific editor
    EDITOR = "vim"; # Lightweight for gaming systems
  };

  # Gaming performance aliases (extends base profile)
  programs.bash.shellAliases = {
    # Performance tuning
    "gaming-mode" = "sudo cpupower frequency-set -g performance";
    "power-save" = "sudo cpupower frequency-set -g powersave";

    # Hardware monitoring for gaming
    "temps" = "watch -n 2 'sensors | grep -E \"(CPU|GPU)\"'";
    "gpu-info" = "nvidia-smi || lspci | grep -i vga";

    # Gaming testing
    "fps-test" = "glxgears -info";
    "gl-info" = "glxinfo | grep -E '(OpenGL|Direct)'";

    # Game management
    "steam-native" = "steam -no-cef-sandbox";
  };

  # Gaming-specific bash functions
  programs.bash.bashrcExtra = ''
    # Gaming performance helper
    gaming-status() {
      echo "=== Gaming System Status ==="
      echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
      echo "CPU Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq | awk '{print $1/1000000 " GHz"}')"
      if command -v nvidia-smi &> /dev/null; then
        echo "GPU Status: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)% usage"
      fi
      echo "RAM Usage: $(free | awk '/Mem:/ {printf "%.1f%%", $3/$2 * 100}')"
    }

    # Quick game launcher helper
    launch-game() {
      echo "Setting performance mode for gaming..."
      sudo cpupower frequency-set -g performance 2>/dev/null
      echo "Launching: $*"
      "$@"
      echo "Returning to balanced mode..."
      sudo cpupower frequency-set -g ondemand 2>/dev/null
    }
  '';
}
