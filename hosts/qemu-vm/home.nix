# QEMU VM Home Manager Configuration
# Uses shared profiles optimized for VM testing and development
{ config, pkgs, inputs, ... }:

{
  # Import shared Home Manager profiles using inputs.self
  imports = [
    (inputs.self + "/home/profiles/base.nix") # Base configuration with git, bash, etc.
    (inputs.self + "/home/profiles/desktop.nix") # Desktop applications for GUI testing
    (inputs.self + "/home/profiles/development.nix") # Development tools for VM testing
  ];

  # Host-specific user info
  home = {
    username = "vm-user";
    homeDirectory = "/home/vm-user";
  };

  # Override git configuration for VM testing
  programs.git = {
    userName = "VM Test User";
    userEmail = "vm-test@example.com";
  };

  # VM-specific environment variables
  home.sessionVariables = {
    # VM identification
    VM_ENVIRONMENT = "qemu";
    VM_TYPE = "development";

    # Lightweight editor for VM
    EDITOR = "vim";
  };

  # VM-specific packages (lightweight and testing-focused)
  home.packages = with pkgs; [
    # VM management and testing tools
    qemu-utils

    # Network testing tools for VMs
    netcat
    socat
    nmap

    # System analysis for VM testing
    lsof
    strace
    iotop

    # Quick file operations in VMs
    tree
    file
    unzip
  ];

  # VM-specific bash aliases (extends base profile)
  programs.bash.shellAliases = {
    # VM information shortcuts
    "vm-info" = "echo 'QEMU VM: ${config.home.username}@'$(hostname) && uname -a";
    "vm-stats" = "echo 'CPU:' $(nproc) 'Memory:' $(free -h | awk '/^Mem:/ {print $2}')";

    # Quick VM network info
    "vm-net" = "ip addr show | grep -E '(inet|UP)'";
    "vm-routes" = "ip route show";

    # VM-optimized shortcuts
    # "ll" - inherited from base profile
    "ports" = "netstat -tuln";
    "procs" = "ps aux | head -20";
  };

  # VM-specific bash enhancements
  programs.bash.bashrcExtra = ''
    # VM-friendly prompt with hostname highlighting
    export PS1="\[\e[36m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[36m\]@\[\e[m\]\[\e[31m\]VM:\h\[\e[m\]\[\e[36m\]]\[\e[m\] \[\e[33m\]\w\[\e[m\]\$ "

    # Show VM info on login
    echo "🖥️  QEMU VM Environment: $(hostname)"
    echo "📊 CPU: $(nproc) cores, RAM: $(free -h | awk '/^Mem:/ {print $2}')"

    # VM testing helper functions
    vm-test-network() {
      echo "=== VM Network Test ==="
      echo "Interface info:"
      ip addr show | grep -E "(UP|inet )"
      echo ""
      echo "Gateway test:"
      ping -c 2 $(ip route | awk '/default/ {print $3}') 2>/dev/null && echo "✓ Gateway reachable" || echo "✗ Gateway unreachable"
      echo ""
      echo "DNS test:"
      nslookup google.com 2>/dev/null && echo "✓ DNS working" || echo "✗ DNS issues"
    }

    # Quick system resource check
    vm-resources() {
      echo "=== VM Resource Usage ==="
      echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)% used"
      echo "Memory: $(free | awk '/Mem:/ {printf "%.1f%%\n", $3/$2 * 100}')"
      echo "Disk: $(df -h / | awk 'NR==2 {print $5}')"
      echo "Processes: $(ps aux | wc -l)"
    }
  '';

  # Lightweight tmux config for VM testing
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-a";

    extraConfig = ''
      # VM-optimized tmux settings
      set -g mouse on
      set -g history-limit 5000

      # VM status bar
      set -g status-bg colour235
      set -g status-fg colour250
      set -g status-left '[QEMU:#{host_short}] '
      set -g status-right '%H:%M %d-%b'

      # Quick VM monitoring windows
      bind V neww -n 'vm-info' 'watch -n 2 "echo \"VM: $(hostname)\"; free -h; df -h /"'
      bind N neww -n 'network' 'watch -n 2 "ip addr show; echo; netstat -tuln"'
    '';
  };
}
