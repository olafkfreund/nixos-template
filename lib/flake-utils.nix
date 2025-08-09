# Flake Configuration Utilities
# Reduces duplication in flake.nix by providing reusable builders
{ inputs, outputs, nixpkgs, self, home-manager, sops-nix }:

let
  inherit (nixpkgs) lib;

  # Common template validation config (matches original flake.nix)
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

  # Core system builder - matches the existing mkSystem with full flakeMeta support
  mkSystem =
    { hostname
    , system ? "x86_64-linux"
    , profile ? "workstation"
    , extraModules ? [ ]
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs outputs;
        # Home Manager profile paths (absolute from flake root)
        homeProfiles = {
          base = self + "/home/profiles/base.nix";
          desktop = self + "/home/profiles/desktop.nix";
          development = self + "/home/profiles/development.nix";
          server = self + "/home/profiles/server.nix";
          gnome = self + "/home/profiles/gnome.nix";
          kde = self + "/home/profiles/kde.nix";
          hyprland = self + "/home/profiles/hyprland.nix";
          niri = self + "/home/profiles/niri.nix";
          headless = self + "/home/profiles/headless.nix";
        };
        # Add comprehensive flake metadata
        flakeMeta = {
          inherit hostname profile system;
          # Build information
          buildTime = self.lastModified or 0;
          buildDate = "build-${toString (self.lastModified or 0)}";
          flakeRev = self.rev or "dirty";
          flakeShortRev =
            if (self.rev or null) != null
            then builtins.substring 0 7 self.rev
            else "unknown";
          # Nixpkgs information
          nixpkgsRev = inputs.nixpkgs.rev or "unknown";
          nixpkgsShortRev =
            if (inputs.nixpkgs.rev or null) != null
            then builtins.substring 0 7 inputs.nixpkgs.rev
            else "unknown";
          # System identification
          configPath = toString ../.;
          hostPath = toString (../. + "/hosts/${hostname}");
        };
      };
      modules = [
        ../hosts/${hostname}/configuration.nix
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.default # Use agenix (passed as sops-nix)

        # Add Home Manager base configuration
        ({ lib, ... }: {
          # Set up Home Manager defaults
          home-manager = {
            useGlobalPkgs = lib.mkDefault true;
            useUserPackages = lib.mkDefault true;
            # Pass inputs to Home Manager modules
            extraSpecialArgs = { inherit inputs; };
          };
        })

        # Add flake metadata module
        ({ pkgs, flakeMeta, ... }: {
          # Make flake metadata available system-wide
          environment.etc."nixos/flake-metadata.json".text = builtins.toJSON flakeMeta;

          # Add metadata to system info
          environment.variables = {
            NIXOS_FLAKE_REV = flakeMeta.flakeShortRev;
            NIXOS_BUILD_DATE = flakeMeta.buildDate;
            NIXOS_HOSTNAME = flakeMeta.hostname;
            NIXOS_PROFILE = flakeMeta.profile;
          };

          # Create system info command
          environment.systemPackages = with pkgs; [
            (writeShellScriptBin "nixos-info" ''
              echo "🏗️  NixOS System Information"
              echo "=========================="
              echo "Hostname: ${flakeMeta.hostname}"
              echo "Profile: ${flakeMeta.profile}"
              echo "System: ${flakeMeta.system}"
              echo "Build Date: ${flakeMeta.buildDate}"
              echo "Flake Revision: ${flakeMeta.flakeShortRev}"
              echo "Nixpkgs Revision: ${flakeMeta.nixpkgsShortRev}"
              echo "Config Path: ${flakeMeta.configPath}"
              echo ""
              echo "📊 System Stats:"
              echo "Uptime: $(uptime -p)"
              echo "Kernel: $(uname -r)"
              echo "NixOS Version: $(nixos-version)"
              echo ""
              echo "🔧 Quick Commands:"
              echo "• nixos-rebuild switch --flake ${flakeMeta.configPath}#${flakeMeta.hostname}"
              echo "• nix flake update ${flakeMeta.configPath}"
              echo "• systemctl status"
            '')
          ];

          # Add to system description
          system.nixos.tags = [ flakeMeta.profile flakeMeta.flakeShortRev ];
        })
      ] ++ extraModules;
    };

  # WSL2 system builder (special case without flakeMeta to match original)
  mkWSLSystem =
    { hostname
    , system ? "x86_64-linux"
    , extraModules ? [ ]
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../hosts/${hostname}/configuration.nix
        inputs.nixos-wsl.nixosModules.wsl
        home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default
        templateConfig
      ] ++ extraModules;
    };

  # Installer ISO builder (simpler, no flakeMeta like original)
  mkInstaller =
    { name
    , system ? "x86_64-linux"
    , extraModules ? [ ]
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../hosts/installer-isos/${name}.nix
        templateConfig
      ] ++ extraModules;
    };

  # macOS ISO builder (simpler, no flakeMeta like original)
  mkMacOSInstaller =
    { name
    , system ? "x86_64-linux"
    , extraModules ? [ ]
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../hosts/macos-isos/${name}.nix
        templateConfig
      ] ++ extraModules;
    };

  # Generate template configurations (laptop, desktop, server)
  mkTemplates = lib.genAttrs [ "laptop-template" "desktop-template" "server-template" ] (name:
    mkSystem {
      hostname = name;
      extraModules = [ templateConfig ];
    }
  );

  # Generate VM test configurations
  mkTestConfigs = lib.genAttrs [
    "qemu-vm"
    "microvm"
    "desktop-test"
    "test-workstation"
    "test-gaming"
    "test-server"
  ]
    (name:
      mkSystem {
        hostname = name;
        extraModules = lib.optionals (lib.hasInfix "test" name) [ templateConfig ];
      }
    );

  # Generate installer configurations for multiple architectures
  mkInstallers = {
    # x86_64 installers
    installer-minimal = mkInstaller { name = "minimal-installer"; };
    installer-desktop = mkInstaller { name = "desktop-installer"; };
    installer-preconfigured = mkInstaller { name = "preconfigured-installer"; };

    # macOS installers (typically x86_64 for compatibility)
    installer-desktop-macos = mkMacOSInstaller { name = "desktop-iso-macos"; };
    installer-minimal-macos = mkMacOSInstaller { name = "minimal-iso-macos"; };

    # aarch64 macOS installers
    installer-desktop-macos-aarch64 = mkMacOSInstaller {
      name = "desktop-iso-macos";
      system = "aarch64-linux";
    };
    installer-minimal-macos-aarch64 = mkMacOSInstaller {
      name = "minimal-iso-macos";
      system = "aarch64-linux";
    };
  };

  # Generate macOS VM configurations (both architectures)
  mkMacOSVMs =
    # Apple Silicon (aarch64) VMs
    (lib.genAttrs [ "desktop-macos" "laptop-macos" "server-macos" ] (name:
      mkSystem {
        hostname = "macos-vms/${name}";
        system = "aarch64-linux";
        extraModules = [ templateConfig ];
      }
    )) //
    # Intel (x86_64) VMs - create separate entries with -intel suffix
    (lib.genAttrs [ "desktop-macos-intel" "laptop-macos-intel" "server-macos-intel" ] (name:
      let
        baseName = lib.removeSuffix "-intel" name;
      in
      mkSystem {
        hostname = "macos-vms/${baseName}";
        system = "x86_64-linux";
        extraModules = [ templateConfig ];
      }
    ));

  # WSL2 configuration
  mkWSLConfigs = {
    wsl2-template = mkWSLSystem {
      hostname = "wsl2-template";
    };
  };

in
{
  # Export all builders
  inherit mkSystem mkWSLSystem mkInstaller mkMacOSInstaller;

  # Export pre-built configuration sets
  templates = mkTemplates;
  testConfigs = mkTestConfigs;
  installers = mkInstallers;
  macosVMs = mkMacOSVMs;
  wslConfigs = mkWSLConfigs;

  # Utility function to merge all configurations
  allConfigurations =
    mkTemplates //
    mkTestConfigs //
    mkInstallers //
    mkMacOSVMs //
    mkWSLConfigs;
}
