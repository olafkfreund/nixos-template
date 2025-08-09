# Example: Server Administrator Home Configuration
# This shows a clean server admin setup
{ ... }:

{
  # Import role and profile
  imports = [
    ../roles/server-admin.nix # Server administration tools
    ../profiles/headless.nix # No GUI configuration
  ];

  # User-specific information
  home = {
    username = "admin";
    homeDirectory = "/home/admin";
  };

  # User-specific git configuration
  programs.git = {
    userName = "System Administrator";
    userEmail = "admin@example.com";
  };

  # Server-specific aliases
  programs.bash = {
    shellAliases = {
      # Server-specific shortcuts
      webapp-logs = "tail -f /var/log/webapp/error.log";
      backup-db = "sudo -u postgres pg_dump myapp > ~/backups/myapp-$(date +%Y%m%d).sql";
      check-services = "systemctl status nginx postgresql redis";

      # Monitoring shortcuts
      load = "uptime";
      disk = "df -h | grep -E '^/dev/'";
      mem = "free -h";

      # Network shortcuts
      firewall = "sudo iptables -L";
      connections = "ss -tuln";
    };
  };

  # Server-specific directories
  xdg.userDirs = {
    extraConfig = {
      XDG_BACKUPS_DIR = "$HOME/backups";
      XDG_SCRIPTS_DIR = "$HOME/scripts";
      XDG_CONFIGS_DIR = "$HOME/configs";
    };
  };
}
