# Server administration package collection
# Monitoring, networking, security, and system administration tools
{ pkgs, lib, config, ... }:

{
  options.modules.packages.server-tools = {
    enable = lib.mkEnableOption "server administration tools package collection";

    includeMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include system and network monitoring tools";
    };

    includeSecurity = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include security and audit tools";
    };

    includeBackup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include backup and recovery tools";
    };

    includeContainers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include container management tools";
    };
  };

  config = lib.mkIf config.modules.packages.server-tools.enable {
    environment.systemPackages = with pkgs; [
      # Essential system tools
      vim
      nano
      curl
      wget

      # File transfer and sync
      rsync
      openssh # provides scp, ssh

      # Process and system analysis
      htop
      lsof
      strace
      ltrace
      sysstat # iostat, mpstat, sar

      # Network utilities
      iproute2 # ss, ip commands
      net-tools # netstat, ifconfig (legacy)
      netcat
      socat
      nmap
      traceroute

      # Text processing
      ripgrep
      fd
      jq
      yq

      # Archive tools
      p7zip
      unrar

      # Terminal multiplexers
      tmux
      screen

      # Log management
      logrotate
      multitail

    ] ++ lib.optionals config.modules.packages.server-tools.includeMonitoring [
      # Advanced monitoring
      btop
      iotop
      nethogs
      iftop
      bandwhich
      ncdu # Disk usage analyzer

      # Network monitoring
      tcpdump
      wireshark-cli # tshark

    ] ++ lib.optionals config.modules.packages.server-tools.includeSecurity [
      # Security tools
      nftables
      fail2ban

      # Certificate management
      certbot

    ] ++ lib.optionals config.modules.packages.server-tools.includeBackup [
      # Backup solutions
      restic
      borgbackup
      rclone

    ] ++ lib.optionals config.modules.packages.server-tools.includeContainers [
      # Container tools
      docker
      docker-compose
      podman
      kubernetes
      kubectl
    ];

    # Server-optimized services
    services.openssh = {
      enable = lib.mkDefault true;

      settings = {
        PasswordAuthentication = lib.mkDefault false;
        PermitRootLogin = lib.mkDefault "no";
        PubkeyAuthentication = lib.mkDefault true;
        UseDNS = lib.mkDefault false;
      };
    };

    # Security configuration
    security.sudo.enable = lib.mkDefault true;

    # Firewall configuration
    networking.firewall = {
      enable = lib.mkDefault true;
      allowedTCPPorts = [ 22 ]; # SSH
    };
  };
}
