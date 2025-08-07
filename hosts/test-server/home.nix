# test-server Home Configuration  
# Server administration setup without GUI
{ ... }:

{
  imports = [
    ../../home/roles/server-admin.nix # Server administration tools
    ../../home/profiles/headless.nix # No GUI configuration
  ];

  # User-specific information
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # User-specific git configuration
  programs.git = {
    userName = "Test Server Admin";
    userEmail = "admin@test-server.local";
  };

  # Server-specific shell aliases
  programs.bash = {
    shellAliases = {
      server-status = "systemctl status nginx postgresql";
      check-load = "uptime && free -h && df -h";
      server-logs = "journalctl -f -u nginx -u postgresql";
    };
  };
}
