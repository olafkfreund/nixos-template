# Modules Default Import
# Automatically discovers and imports all module directories
{ lib, ... }:

let
  # Function to automatically discover module directories
  discoverModules = dir:
    let
      # Get all entries in the directory
      entries = builtins.readDir dir;

      # Filter for directories and files that should be imported
      moduleEntries = lib.filterAttrs
        (name: type:
          # Include directories (which contain default.nix)
          type == "directory" ||
          # Include .nix files but exclude this default.nix file
          (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
        )
        entries;

      # Convert to list of import paths
      modulePaths = lib.mapAttrsToList
        (name: type:
          if type == "directory" then
            dir + "/${name}"  # Import directory (will use its default.nix)
          else
            dir + "/${name}"  # Import .nix file directly
        )
        moduleEntries;
    in
    modulePaths;

  # Automatically discover all modules in the current directory
  discoveredModules = discoverModules ./.;
in

{
  # Import all discovered modules
  imports = discoveredModules;

  # Debug: Uncomment the line below to see which modules are being imported
  # warnings = [ "Imported modules: ${toString discoveredModules}" ];
}
