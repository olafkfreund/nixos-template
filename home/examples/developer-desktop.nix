# Example: Developer Desktop Home Configuration
# This shows how host-specific home.nix files should look with the new structure
{ ... }:

{
  # Import role and profile
  imports = [
    ../roles/developer.nix      # Development tools and environment
    ../profiles/gnome.nix       # GNOME desktop environment
  ];

  # User-specific information (the only thing that should vary per host)
  home = {
    username = "developer";
    homeDirectory = "/home/developer";
  };

  # User-specific git configuration
  programs.git = {
    userName = "Jane Developer";
    userEmail = "jane.developer@company.com";
    
    # Add any host-specific git settings
    extraConfig = {
      # Use different signing key per host
      user.signingkey = "ABC123DEF456";
      commit.gpgsign = true;
    };
  };

  # Host-specific overrides (minimal - most config comes from role/profile)
  programs.zsh = {
    shellAliases = {
      # Company-specific shortcuts
      work = "cd ~/Work";
      company-vpn = "sudo openvpn ~/Work/company.ovpn";
    };
  };

  # Host-specific XDG directories
  xdg.userDirs = {
    extraConfig = {
      XDG_WORK_DIR = "$HOME/Work";
      XDG_COMPANY_DIR = "$HOME/Work/Company";
    };
  };
}