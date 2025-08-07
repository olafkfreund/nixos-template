{
  description = "A comprehensive NixOS configuration template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agenix, ... }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Helper function to reduce duplication in nixosSystem configurations
      mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
          ] ++ extraModules;
        };

      # Helper function for home-manager configurations
      mkHome = { hostname, system ? "x86_64-linux" }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/${hostname}/home.nix ];
        };

      # Common template validation config
      templateConfig = {
        # Set timezone for templates
        time.timeZone = "Europe/London";
        # Location for geoclue2 (needed by laptop template)
        location = {
          latitude = 51.5074;
          longitude = -0.1278;
        };
        # Allow unfree packages for template validation
        nixpkgs.config.allowUnfree = true;
        # Allow insecure packages for template validation
        nixpkgs.config.permittedInsecurePackages = [ "libsoup-2.74.3" ];
      };
    in
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages; acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

      # Formatter for your nix files, available through 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # Development shell for working on the template
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Nix tools
              nixpkgs-fmt
              statix
              deadnix

              # Shell scripting
              shellcheck
              shfmt

              # Documentation
              markdownlint-cli

              # Development tools
              git
              just
              pre-commit

              # Hardware detection dependencies
              pciutils
              usbutils
              lshw
            ];

            shellHook = ''
              echo "NixOS Template Development Environment"
              echo "Available commands:"
              echo "  just --list    - Show available commands"
              echo "  just validate  - Run validation suite"
              echo "  just dev-setup - Setup development environment"
            '';
          };
        });

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # Template configurations (examples, not directly usable)
        laptop-template = mkSystem {
          hostname = "laptop-template";
          extraModules = [ templateConfig ];
        };

        desktop-template = mkSystem {
          hostname = "desktop-template";
          extraModules = [ templateConfig ];
        };

        server-template = mkSystem {
          hostname = "server-template";
          extraModules = [ templateConfig ];
        };

        # Example VM configurations  
        qemu-vm = mkSystem { hostname = "qemu-vm"; };
        microvm = mkSystem { hostname = "microvm"; };
        desktop-test = mkSystem {
          hostname = "desktop-test";
          extraModules = [ templateConfig ];
        };

        # Preset system test configurations
        test-workstation = mkSystem { hostname = "test-workstation"; };
        test-gaming = mkSystem { hostname = "test-gaming"; };
        test-server = mkSystem { hostname = "test-server"; };

        # Custom installer ISO configurations
        # Build with: nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage
        installer-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/minimal-installer.nix
            templateConfig
          ];
        };

        installer-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/desktop-installer.nix
            templateConfig
          ];
        };

        installer-preconfigured = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/preconfigured-installer.nix
            templateConfig
          ];
        };

      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # Example home configurations
        "user@laptop-template" = mkHome { username = "user"; hostname = "laptop-template"; };
        "user@desktop-template" = mkHome { username = "user"; hostname = "desktop-template"; };
        "user@server-template" = mkHome { username = "user"; hostname = "server-template"; };
        "vm-user@desktop-test" = mkHome { username = "vm-user"; hostname = "desktop-test"; };
      };
    };
}
