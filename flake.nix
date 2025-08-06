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
        laptop-template = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/laptop-template/configuration.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
              # Dummy location for template validation
              location.latitude = 40.7128;
              location.longitude = -74.0060;
              # Allow unfree packages for template validation
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for template validation
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };

        desktop-template = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/desktop-template/configuration.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
              # Dummy location for template validation
              location.latitude = 40.7128;
              location.longitude = -74.0060;
              # Allow unfree packages for template validation
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for template validation
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };

        server-template = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/server-template/configuration.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            {
              # Dummy location for template validation
              location.latitude = 40.7128;
              location.longitude = -74.0060;
              # Allow unfree packages for template validation
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for template validation
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };

        # Example VM configurations
        qemu-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/qemu-vm/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };

        microvm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/microvm/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };

        desktop-test = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/desktop-test/configuration.nix
            home-manager.nixosModules.home-manager
            {
              # VM testing configuration
              location.latitude = 40.7128;
              location.longitude = -74.0060;
              # Allow unfree packages for testing
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };

        # Custom installer ISO configurations
        # Build with: nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage
        installer-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/minimal-installer.nix
            {
              # Allow unfree packages in installer
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for compatibility
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };

        installer-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/desktop-installer.nix
            {
              # Allow unfree packages in installer
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for compatibility
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };

        installer-preconfigured = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/preconfigured-installer.nix
            {
              # Allow unfree packages in installer
              nixpkgs.config.allowUnfree = true;
              # Allow insecure packages for compatibility
              nixpkgs.config.permittedInsecurePackages = [
                "libsoup-2.74.3"
              ];
            }
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # Example home configurations
        "user@laptop-template" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/laptop-template/home.nix ];
        };

        "user@desktop-template" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/desktop-template/home.nix ];
        };

        "user@server-template" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/server-template/home.nix ];
        };

        "vm-user@desktop-test" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/desktop-test/home.nix ];
        };
      };
    };
}
