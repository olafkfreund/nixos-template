{ config, pkgs, ... }:

{
  # Home Manager configuration for VM user

  # Basic user info
  home = {
    username = "vm-user";
    homeDirectory = "/home/vm-user";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Git configuration for development
  programs.git = {
    enable = true;
    userName = "VM User";
    userEmail = "vm-user@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # Shell configuration optimized for VMs
  programs.bash = {
    enable = true;

    shellAliases = {
      # Use eza instead of ls for better file listing
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      tree = "eza --tree";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";

      # VM-specific aliases
      "vm-info" = "echo 'VM: ${config.home.username}@'$(hostname) && uname -a";
      "net-info" = "ip addr show && ip route show";

      # NixOS specific aliases
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config";
    };

    bashrcExtra = ''
      # VM-friendly prompt with hostname
      export PS1="\[\e[36m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[36m\]@\[\e[m\]\[\e[34m\]\h\[\e[m\]\[\e[36m\]]\[\e[m\] \[\e[33m\]\w\[\e[m\]\$ "
      
      # Show VM info on login
      echo "🖥️  VM Environment: $(hostname)"
      echo "📍 IP: $(hostname -I | awk '{print $1}')"
    '';
  };

  # Essential terminal applications for VMs
  programs = {
    # Better file listing
    eza = {
      enable = true;
    };

    # Better cat
    bat.enable = true;

    # System monitoring
    htop.enable = true;

    # Directory navigation
    zoxide.enable = true;

    # Terminal multiplexer for persistent sessions
    tmux = {
      enable = true;
      terminal = "screen-256color";
      prefix = "C-a";
      keyMode = "vi";

      extraConfig = ''
        # VM-friendly tmux configuration
        set -g mouse on
        set -g history-limit 10000
        
        # Status bar
        set -g status-bg blue
        set -g status-fg white
        set -g status-left '[VM:#{host_short}] '
        set -g status-right '%Y-%m-%d %H:%M'
      '';
    };
  };

  # VM-focused packages
  home.packages = with pkgs; [
    # Network tools
    curl
    wget
    netcat
    socat
    nmap

    # File transfer
    rsync
    openssh # includes scp

    # System utilities
    tree
    file
    which
    lsof
    strace

    # Text processing
    jq
    yq

    # VM management tools
    qemu-utils

    # Development tools (lightweight)
    git
    nano
    vim
  ];

  # XDG directories (minimal for VMs)
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
    };
  };

  # SSH configuration for VM access
  programs.ssh = {
    enable = true;

    extraConfig = ''
      # VM-friendly SSH settings
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        
      # Common VM access patterns
      Host host hypervisor
        HostName 10.0.2.2
        User your-username
        Port 22
    '';
  };

  # Environment variables for VMs
  home.sessionVariables = {
    EDITOR = "nano";
    PAGER = "less";

    # VM identification
    VM_ENVIRONMENT = "true";
    VM_HOSTNAME = "qemu-vm";
  };
}
