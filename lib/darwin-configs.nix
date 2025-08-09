# Darwin Configuration Generator
# Eliminates duplication in Darwin configurations across architectures
{ inputs, outputs, nixpkgs, nix-darwin, home-manager }:

let
  inherit (nixpkgs) lib;

  # Helper function for nix-darwin configurations
  mkDarwin = { hostname, system ? "aarch64-darwin" }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../hosts/${hostname}/configuration.nix
        home-manager.darwinModules.home-manager
      ];
    };

  # Generate Darwin configurations for multiple architectures
  mkDarwinConfigurations = hostnames:
    let
      # Darwin systems we support
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];

      # Generate configurations for each hostname and architecture
      generateForHost = hostname:
        lib.listToAttrs (map
          (system:
            let
              # Create config name based on architecture
              configName =
                if system == "aarch64-darwin"
                then hostname
                else "${hostname}-intel";
            in
            {
              name = configName;
              value = mkDarwin { inherit hostname system; };
            }
          )
          darwinSystems);
    in
    lib.foldl' (acc: hostname: acc // (generateForHost hostname)) { } hostnames;

in
{
  # Export the builder functions
  inherit mkDarwin mkDarwinConfigurations;

  # Pre-built Darwin configurations for common host types
  standardConfigurations = mkDarwinConfigurations [
    "darwin-desktop"
    "darwin-laptop"
    "darwin-server"
  ];
}
