{ ... }:

{
  # Available user templates
  #
  # To use a user template:
  # 1. Copy the desired template to your hostname directory
  # 2. Import it in your Home Manager configuration
  # 3. Customize as needed
  #
  # Example:
  #   cp home/users/developer.nix hosts/my-host/home.nix
  #   # Then edit hosts/my-host/home.nix to customize

  imports = [
    # Default user configuration (referenced by flake)
    ./user.nix
  ];
}
