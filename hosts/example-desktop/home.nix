{ ... }:
{
  # Use the role-based configuration system to eliminate duplication
  imports = [
    ../../home/roles/developer.nix # Development environment with all tools
    ../../home/profiles/gnome.nix # GNOME desktop environment
  ];

  # User-specific information (required)
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.05";
  };

  # User-specific git configuration (required)
  programs.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  # Host-specific overrides (optional)
  programs.bash.shellAliases = {
    # Custom aliases for this specific host
    rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
    rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config";
    update = "nix flake update ~/nixos-config";
  };
}
