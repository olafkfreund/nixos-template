# Package overlays for custom packages and modifications
{ inputs }:
{
  # Default overlay - modify packages or add custom ones
  default = final: prev: {
    # Example: Override a package version
    # my-package = prev.my-package.overrideAttrs (old: {
    #   version = "custom-version";
    # });
    
    # Example: Add custom packages
    # my-custom-tool = prev.callPackage ../pkgs/my-custom-tool { };
    
    # Example: Patch existing package
    # firefox = prev.firefox.override {
    #   cfg = {
    #     enableTridactylNative = true;
    #   };
    # };
  };
}