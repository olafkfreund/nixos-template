{ config, pkgs, ... }:

{
  # Import shared Home Manager profiles
  imports = [
    ../../home/profiles/base.nix # Base configuration with git, bash, etc.
    ../../home/profiles/desktop.nix # Desktop applications and GUI tools
    ../../home/profiles/development.nix # Development tools and environments
  ];

  # Host-specific user info (overrides base profile defaults)
  home = {
    username = "vm-user";
    homeDirectory = "/home/vm-user";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Override git configuration with host-specific details
  programs.git = {
    userName = "VM User";
    userEmail = "vm-user@example.com";
  };

  # VM-specific shell customizations (extends base profile)
  programs.bash.shellAliases = {
    # VM-specific aliases (added to base aliases)
    "vm-info" = "echo 'VM: ${config.home.username}@'$(hostname) && uname -a";
    "net-info" = "ip addr show && ip route show";

    # NixOS rebuild shortcuts
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config";

    # Use eza for better file listing (overrides base ls aliases)
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    tree = "eza --tree";
  };

  programs.bash.bashrcExtra = ''
    # VM-friendly prompt with hostname
    export PS1="\[\e[36m\][\[\e[m\]\[\e[32m\]\u\[\e[m\]\[\e[36m\]@\[\e[m\]\[\e[34m\]\h\[\e[m\]\[\e[36m\]]\[\e[m\] \[\e[33m\]\w\[\e[m\]\$ "

    # Show VM info on login
    echo "🖥️  VM Environment: $(hostname)"
    echo "📍 IP: $(hostname -I | awk '{print $1}')"
  '';

  # VM-specific program overrides (profiles provide base configs)
  programs = {
    # Enable additional tools for VM environment
    eza.enable = true;
    bat.enable = true;
    zoxide.enable = true;

    # VM-optimized tmux configuration (overrides server profile defaults)
    tmux.extraConfig = ''
      # VM-friendly tmux configuration
      set -g mouse on
      set -g history-limit 10000
      set -g prefix C-a
      set -g mode-keys vi

      # VM-specific status bar
      set -g status-bg blue
      set -g status-fg white
      set -g status-left '[VM:#{host_short}] '
      set -g status-right '%Y-%m-%d %H:%M'
    '';
  };

  # VM-specific packages (additional to profiles)
  home.packages = with pkgs; [
    # VM-specific tools
    qemu-utils

    # Network diagnostics for VMs
    nmap
    socat

    # System analysis
    lsof
    strace
  ];

  # XDG directories (base profile provides defaults, VM needs minimal set)
  xdg.userDirs = {
    createDirectories = true;
    # Standard VM directories
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
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

  # VM-specific environment variables (extends base profile)
  home.sessionVariables = {
    # Override base profile editor for VM simplicity
    EDITOR = "nano";

    # VM identification
    VM_ENVIRONMENT = "true";
    VM_HOSTNAME = "qemu-vm";
  };
}
