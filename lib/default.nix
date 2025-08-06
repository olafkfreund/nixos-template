{ lib }:

rec {
  # Utility function to create NixOS configurations with common patterns
  mkHost = import ./mkHost.nix { inherit lib; };
  
  # Helper to enable/disable features based on conditions
  mkIf = condition: config: lib.mkIf condition config;
  
  # Helper to merge configurations conditionally  
  mkMerge = lib.mkMerge;
  
  # Helper for creating users with home-manager
  mkUser = { username, description ? "", groups ? [ "wheel" ], shell ? null }:
    {
      users.users.${username} = {
        isNormalUser = true;
        inherit description;
        extraGroups = groups;
        shell = shell;
      };
    };
    
  # Helper for enabling services with common patterns
  mkService = { name, enable ? true, config ? {} }:
    lib.mkIf enable {
      services.${name} = lib.mkMerge [
        { enable = true; }
        config
      ];
    };
}