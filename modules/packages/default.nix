# Package modules directory
# Shared package sets to reduce redundancy in systemPackages

{
  # Import all package modules (Darwin packages are conditional internally)
  imports = [
    ./core-system.nix
    ./development.nix
    ./desktop-apps.nix
    ./gaming.nix
    ./server-admin.nix
    ./server-tools.nix
    ./darwin-packages.nix
  ];
}
