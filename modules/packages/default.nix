# Package modules directory
# Shared package sets to reduce redundancy in systemPackages

{
  # Import all package modules
  imports = [
    ./core-system.nix
    ./development.nix
    ./desktop-apps.nix
    ./gaming.nix
    ./server-admin.nix
  ];
}
