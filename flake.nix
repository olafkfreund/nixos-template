{
  description = "A comprehensive NixOS configuration template";

  # Advanced Nix configuration for optimal performance and caching
  nixConfig = {
    # Enhanced substituters for faster builds
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    # Only substituters are kept here. max-jobs, cores, sandbox, keep-outputs
    # and friends are silently ignored unless the user is a trusted user, so
    # setting them in a flake gives a false sense of configuration. Those belong
    # in the user's own nix.conf.
  };

  inputs = {
    # Tracks the current NixOS stable release. Stable gives near-complete binary
    # cache coverage and matches the `system.stateVersion` used by the hosts here.
    #
    # Want bleeding edge instead? Change both of the following to:
    #   nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    #   home-manager.url = "github:nix-community/home-manager";
    # ...then bump `system.stateVersion` only when you actually upgrade releases.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Declarative disk partitioning. The graphical installer cannot express
    # LUKS, LVM, btrfs subvolumes or ZFS, which is where most first installs
    # get stuck; disko puts the whole layout in the flake instead.
    # See hosts/examples/disko-*.nix and docs/DISK-SETUP.md.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Per-model hardware quirks (Framework, ThinkPad, XPS, Surface, Pi, ...).
    # `follows` matters here: left alone it locks a second full nixpkgs, and
    # evaluating two nixpkgs alongside 25 hosts is what previously exhausted
    # the CI runner's memory.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # niri has no module in nixpkgs or home-manager, so its config would
    # otherwise have to be a hand-written KDL string. This provides both.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agenix,
      treefmt-nix,
      git-hooks,
      nix-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # i686-linux is deliberately absent: git-hooks.nix does not provide
      # `lib.i686-linux`, so `checks.i686-linux.pre-commit-check` fails to
      # evaluate and `nix flake show --all-systems` errors out. Nothing in this
      # template targets 32-bit x86, and nixpkgs support for it is minimal.
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Treefmt configuration
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          # Project root directory
          projectRootFile = "flake.nix";

          # Formatters by language/file type
          programs = {
            # Nix files. nixfmt is the official Nix formatter (RFC 166);
            # nixpkgs-fmt is archived upstream.
            nixfmt.enable = true;

            # Shell scripts
            shfmt.enable = true;

            # Markdown files
            mdformat.enable = true;

            # YAML files
            yamlfmt.enable = true;

            # JSON files
            prettier.enable = true;
          };

          # File patterns and exclusions
          settings = {
            global.excludes = [
              # Git and build artifacts
              ".git/**"
              "site/**"
              "result*"
              "*.png"
              "*.jpg"
              "*.jpeg"
              "*.gif"
              "*.ico"
              "*.tar*"
              "*.zip"
              "*.rar"
              "*.7z"
              # Generated files
              "**/hardware-configuration.nix"
              "flake.lock"
            ];
          };
        }
      );

      # Pre-commit hooks configuration (simplified for now)
      pre-commit-check = forAllSystems (
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style = {
              enable = true;
              # Keep this in step with treefmt's global.excludes above: generated
              # hardware-configuration.nix files are owned by
              # nixos-generate-config, not by us, so neither tool reformats them.
              excludes = [ ".*hardware-configuration\\.nix$" ];
            };
            statix.enable = true;
            shellcheck.enable = true;
          };
        }
      );

      # Helper function for home-manager configurations
      mkHome =
        {
          hostname,
          system ? "x86_64-linux",
        }:
        home-manager.lib.homeManagerConfiguration {
          # `import nixpkgs` rather than `legacyPackages` so that allowUnfree can
          # be set. The profiles here pull in unfree packages such as vscode, and
          # the NixOS-integrated hosts already allow them; without this the
          # standalone `homeConfigurations.*` outputs simply fail to evaluate.
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            inputs.niri.homeModules.niri
            ./hosts/${hostname}/home.nix
          ];
        };

      # Import flake utilities to reduce duplication
      flakeUtils = import ./lib/flake-utils.nix {
        inherit
          inputs
          outputs
          nixpkgs
          self
          home-manager
          agenix
          ;
      };

      # Import deployment images generator
      deploymentImages = import ./lib/deployment-images.nix {
        inherit inputs outputs nixpkgs;
      };

      # Import Darwin configurations generator
      darwinConfigs = import ./lib/darwin-configs.nix {
        inherit
          inputs
          outputs
          nixpkgs
          nix-darwin
          home-manager
          ;
      };
    in
    {
      # Starting points for your OWN repository, rather than a fork of this one.
      #
      #   nix flake init -t github:olafkfreund/nixos-template#minimal
      #   nix flake init -t github:olafkfreund/nixos-template#desktop
      #
      # Each is a self-contained flake of four or five short files. Most people
      # do not want to inherit 25 hosts and a preset system on day one; they
      # want something they can read end to end and then grow.
      templates = {
        minimal = {
          path = ./templates/minimal;
          description = "NixOS + Home Manager in one readable flake";
          welcomeText = ''
            # Minimal NixOS configuration

            Four files. Read them in any order; they are short.

            **1.** Replace the placeholder hardware config, on the target machine:

            ```
            sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
            ```

            **2.** Pick a hostname. It appears twice and the two must match:
            `networking.hostName` in `configuration.nix`, and
            `nixosConfigurations.<name>` in `flake.nix`.

            **3.** Replace the username `me` in `configuration.nix` and `home.nix`.

            **4.** Commit first -- flakes ignore untracked files, so an
            uncommitted file is invisible to the build:

            ```
            git init && git add -A
            sudo nixos-rebuild switch --flake .#my-machine
            ```

            Want a Wayland desktop with an encrypted disk instead?

            ```
            nix flake init -t github:olafkfreund/nixos-template#desktop
            ```
          '';
        };

        desktop = {
          path = ./templates/desktop;
          description = "Wayland GNOME desktop with LUKS-encrypted btrfs (disko)";
          welcomeText = ''
            # NixOS desktop configuration

            **`disko.nix` ERASES the disk it names.** Confirm the device first:

            ```
            lsblk -o NAME,SIZE,MODEL
            ```

            **1.** Set that device in `disko.nix` (it defaults to `/dev/nvme0n1`).

            **2.** Generate your hardware config, then delete the `fileSystems`
            and `swapDevices` blocks it writes -- `disko.nix` owns those, and two
            modules defining `fileSystems."/"` is a conflict, not a merge:

            ```
            sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
            ```

            **3.** Replace the hostname `my-desktop` and the username `me`.

            **4.** Partition and install:

            ```
            git init && git add -A
            sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko.nix
            sudo nixos-install --flake .#my-desktop
            ```

            On a supported laptop? Uncomment the matching `nixos-hardware`
            module in `flake.nix` -- it fixes suspend, function keys and
            firmware quirks that are tedious to work out yourself.
          '';
        };
      };

      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { };

      # Custom packages and deployment images; accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (
        system:
        let
          # Deployment images are NixOS systems, so they only make sense on
          # Linux. Generating them for *-darwin built a nixosSystem with a
          # Darwin pkgs set, which then tried to set the nix-darwin-only option
          # `networking.computerName` on a NixOS configuration and failed to
          # evaluate. `nix flake check` never caught it because it skips the
          # darwin systems; only `nix flake show --all-systems` reaches here.
          images = nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "-linux" system) (
            deploymentImages.mkDeploymentImages { inherit system; }
          );
        in
        # Merge custom packages with generated deployment images
        (import ./pkgs nixpkgs.legacyPackages.${system}) // images
      );
      # Formatter for your nix files, available through 'nix fmt'
      # Uses treefmt for multi-language formatting
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Development shell for working on the template
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Nix development tools
              nixfmt
              nixd # Nix language server: option completion + docs in your editor
              statix
              deadnix
              nh

              # Code quality tools
              treefmt
              pre-commit

              # Shell scripting tools
              shellcheck
              shfmt

              # Documentation tools
              markdownlint-cli

              # Development utilities
              git
              just
              fzf
              jq

              # Hardware detection
              pciutils
              usbutils
              lshw
            ];

            # Environment variables
            NIX_CONFIG = "experimental-features = nix-command flakes";
            LC_ALL = "C.UTF-8";

            # Combined shell hook
            shellHook = ''
              echo "🚀 NixOS Template Development Environment"
              echo ""
              echo "📋 Available commands:"
              echo "  just --list       - Show all available tasks"
              echo "  nix fmt           - Format Nix code"
              echo "  nh --help         - Better NixOS system management"
              echo ""
              echo "🔧 Development tools loaded:"
              echo "  nixfmt, statix, deadnix, shellcheck, pre-commit"
              echo ""

              # Hooks are installed by git-hooks.nix below. There is deliberately
              # no `pre-commit install` here: it read a separate
              # .pre-commit-config.yaml and raced this shellHook for
              # .git/hooks/pre-commit, so the repository had two competing hook
              # sets and the one CI does not check usually won.
              ${pre-commit-check.${system}.shellHook or ""}
            '';
          };
        }
      );

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      # All configurations are now generated using flake-utils.nix to reduce duplication
      nixosConfigurations = flakeUtils.allConfigurations // {

        # ─────────────────────────────────────────────────────────────────────
        #  ADD YOUR OWN HOSTS HERE
        # ─────────────────────────────────────────────────────────────────────
        #  1. cp -r hosts/desktop-template hosts/my-desktop
        #  2. sudo nixos-generate-config --show-hardware-config \
        #       > hosts/my-desktop/hardware-configuration.nix
        #  3. Uncomment and edit one of the lines below.
        #  4. sudo nixos-rebuild switch --flake .#my-desktop
        #
        #  `profile` is metadata used by modules/core/system-identification.nix;
        #  it does not by itself pull in packages. See docs/HOST-TEMPLATES.md.
        #
        # my-desktop = flakeUtils.mkSystem {
        #   hostname = "my-desktop";           # must match the hosts/ directory
        #   profile = "workstation";           # workstation, server, laptop, gaming, development, minimal
        # };
        #
        # my-server = flakeUtils.mkSystem {
        #   hostname = "my-server";
        #   profile = "server";
        #   system = "aarch64-linux";          # defaults to x86_64-linux
        #   extraModules = [ ./hosts/my-server/services.nix ];
        # };
      };

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = darwinConfigs.standardConfigurations;

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # Example home configurations
        "user@laptop-template" = mkHome { hostname = "laptop-template"; };
        "user@desktop-template" = mkHome { hostname = "desktop-template"; };
        "user@server-template" = mkHome { hostname = "server-template"; };
        "vm-user@desktop-test" = mkHome { hostname = "desktop-test"; };
        "nixos@wsl2-template" = mkHome { hostname = "wsl2-template"; };

        # macOS VM home configurations
        "nixos@desktop-macos" = mkHome {
          hostname = "macos-vms/desktop-macos";
          system = "aarch64-linux";
        };
        "laptop-user@laptop-macos" = mkHome {
          hostname = "macos-vms/laptop-macos";
          system = "aarch64-linux";
        };
        "server-admin@server-macos" = mkHome {
          hostname = "macos-vms/server-macos";
          system = "aarch64-linux";
        };

        # Intel Mac variants
        "nixos@desktop-macos-intel" = mkHome {
          hostname = "macos-vms/desktop-macos";
          system = "x86_64-linux";
        };
        "laptop-user@laptop-macos-intel" = mkHome {
          hostname = "macos-vms/laptop-macos";
          system = "x86_64-linux";
        };
        "server-admin@server-macos-intel" = mkHome {
          hostname = "macos-vms/server-macos";
          system = "x86_64-linux";
        };
      };

      # Checks for CI/CD and development
      # Available through 'nix flake check'
      checks = forAllSystems (system: {
        # Pre-commit hooks check
        pre-commit-check = pre-commit-check.${system};

        # Treefmt formatting check
        treefmt = treefmtEval.${system}.config.build.check self;

        # NOTE: there is deliberately no "run `nix flake check` inside a check"
        # derivation here. Nix cannot invoke itself inside the build sandbox
        # (no daemon, no network), so such a check can only ever fail. The
        # per-host evaluation it was meant to provide already happens: `nix flake
        # check` evaluates every entry in `nixosConfigurations` natively.

        # Statix linting
        statix-check = nixpkgs.legacyPackages.${system}.runCommand "statix-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.statix}/bin/statix check .
          touch $out
        '';

        # Deadnix check
        deadnix-check = nixpkgs.legacyPackages.${system}.runCommand "deadnix-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.deadnix}/bin/deadnix --fail .
          touch $out
        '';

        # Shell script validation. `-S warning` keeps real problems failing the
        # build while ignoring info-level notes such as SC2016, which fires on
        # help text that deliberately prints a literal `$USER`.
        shellcheck-check = nixpkgs.legacyPackages.${system}.runCommand "shellcheck-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.shellcheck}/bin/shellcheck scripts/*.sh
          touch $out
        '';

        # The `nix flake init -t` templates are nested flakes, so `nix flake
        # check` never looks inside them -- they would silently rot against a
        # renamed option and only break for the newcomer running the command
        # from the README. Evaluate their modules here instead.
        templates-evaluate =
          let
            inherit (nixpkgs) lib;
            evalTemplate =
              modules:
              (lib.nixosSystem {
                inherit system modules;
              }).config.system.build.toplevel.drvPath;
          in
          nixpkgs.legacyPackages.${system}.runCommand "templates-evaluate" { } ''
            # Referencing each drvPath forces full module evaluation; the
            # `builtins.seq` keeps the store path itself out of $out.
            echo ${
              lib.escapeShellArg (
                builtins.seq (evalTemplate [
                  ./templates/minimal/configuration.nix
                  ./templates/minimal/hardware-configuration.nix
                ]) "ok minimal"
              )
            }
            echo ${
              lib.escapeShellArg (
                builtins.seq (evalTemplate [
                  inputs.disko.nixosModules.disko
                  ./templates/desktop/configuration.nix
                  ./templates/desktop/hardware-configuration.nix
                  ./templates/desktop/disko.nix
                ]) "ok desktop"
              )
            }
            touch $out
          '';

        # Same reasoning as disko-examples: hosts/examples/specialisations.nix
        # is imported by no host, so nothing would notice if an option under it
        # were renamed. Assert the boot entries it promises actually exist.
        specialisation-examples =
          let
            inherit (nixpkgs) lib;
            evaluated =
              (lib.nixosSystem {
                inherit system;
                modules = [
                  ./hosts/examples/specialisations.nix
                  ./templates/minimal/hardware-configuration.nix
                  {
                    boot.loader.systemd-boot.enable = true;
                    system.stateVersion = "26.05";
                    # nvidia-sync flips prime.sync on, which the module only
                    # accepts alongside the bus IDs and the nvidia driver.
                    services.xserver.videoDrivers = [ "nvidia" ];
                    hardware.nvidia = {
                      open = true;
                      prime = {
                        intelBusId = "PCI:0:2:0";
                        nvidiaBusId = "PCI:1:0:0";
                        offload.enable = true;
                        offload.enableOffloadCmd = true;
                      };
                    };
                    nixpkgs.config.allowUnfree = true;
                  }
                ];
              }).config;
            got = lib.attrNames evaluated.specialisation;
            wanted = [
              "nvidia-sync"
              "rescue"
            ];
            missing = lib.subtractLists got wanted;
          in
          nixpkgs.legacyPackages.${system}.runCommand "specialisation-examples" { } ''
            echo ${
              lib.escapeShellArg (
                if missing == [ ] then
                  "ok specialisations: ${toString got}"
                else
                  throw "missing specialisations: ${toString missing}"
              )
            }
            touch $out
          '';

        # The disko layouts in hosts/examples/ are imported by no host, which is
        # exactly how the old vm-test-config/ rotted until it referenced a flake
        # input that no longer existed. So evaluate them here: each layout is
        # built into a throwaway nixosSystem and asserted to produce the mounts
        # it claims. A typo'd option or a renamed disko attribute fails the PR.
        disko-examples =
          let
            inherit (nixpkgs) lib;
            mkDiskoHost =
              layout:
              lib.nixosSystem {
                inherit system;
                specialArgs = { inherit inputs; };
                modules = [
                  inputs.disko.nixosModules.disko
                  layout
                  {
                    boot.loader.systemd-boot.enable = true;
                    system.stateVersion = "26.05";
                  }
                ];
              };
            mountsOf = layout: lib.attrNames (mkDiskoHost layout).config.fileSystems;
            # attrNames are plain strings, so nothing from the evaluated system
            # leaks into this derivation's closure.
            expect =
              name: layout: wanted:
              let
                got = mountsOf layout;
                missing = lib.subtractLists got wanted;
              in
              if missing == [ ] then
                "ok ${name}: ${toString got}"
              else
                throw "disko example ${name} is missing mountpoints: ${toString missing}";
          in
          nixpkgs.legacyPackages.${system}.runCommand "disko-examples" { } ''
            echo ${
              lib.escapeShellArg (
                expect "disko-simple" ./hosts/examples/disko-simple.nix [
                  "/"
                  "/boot"
                ]
              )
            }
            echo ${
              lib.escapeShellArg (
                expect "disko-luks-btrfs" ./hosts/examples/disko-luks-btrfs.nix [
                  "/"
                  "/boot"
                  "/home"
                  "/nix"
                  "/persist"
                ]
              )
            }
            touch $out
          '';

        # VM Integration Tests (minimal configuration to avoid circular dependencies)
        vm-test-desktop = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-desktop-test";
          nodes.machine = { pkgs, ... }: {
            # Minimal test configuration - no complex module imports

            # Basic system setup
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Network
            networking.hostName = "desktop-test";
            networking.networkmanager.enable = true;

            # User for testing
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "networkmanager"
              ];
              password = "test";
            };

            # Essential packages for testing
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
            ];

            # System state version
            system.stateVersion = "26.05";
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test essential services
            machine.succeed("systemctl is-active NetworkManager")

            # Test basic tools are available
            machine.succeed("which git")
            machine.succeed("which vim")

            # Test user exists
            machine.succeed("id nixos")

            machine.shutdown()
          '';
        };

        vm-test-server = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-server-test";
          nodes.machine = { pkgs, ... }: {
            # Minimal server test configuration - no complex module imports

            # Basic system setup
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Network and firewall
            networking = {
              hostName = "server-test";
              firewall = {
                enable = true;
                allowedTCPPorts = [ 22 ];
              };
            };

            # SSH service for server testing
            services.openssh = {
              enable = true;
              settings.PasswordAuthentication = true; # For testing only
            };

            # Test user
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              password = "test";
            };

            # Essential server packages for testing
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              htop
            ];

            # System state version
            system.stateVersion = "26.05";
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test SSH service
            machine.wait_for_unit("sshd.service")
            machine.succeed("systemctl is-active sshd")

            # Test firewall is running
            machine.succeed("systemctl is-active firewall")

            # Test server tools are available
            machine.succeed("which htop")
            machine.succeed("which curl")

            machine.shutdown()
          '';
        };

        # NOTE: `config-syntax-check`, `module-dependency-check` and
        # `security-check` used to live here. Each one ended in an unconditional
        # `echo "✅ ..."; touch $out`, so all three passed no matter what they
        # found — `config-syntax-check` only echoed host names without evaluating
        # anything. A check that cannot fail is worse than no check, because it
        # reads as coverage. Real evaluation coverage comes from `nix flake
        # check` walking `nixosConfigurations`, and real linting from
        # statix/deadnix/shellcheck above.

        # NOTE: the standalone homeConfigurations are deliberately not checks.
        # mkHome calls `import nixpkgs` to set allowUnfree, so each one is a
        # second full nixpkgs evaluation; pulling them into `nix flake check`
        # on top of 25 hosts exhausted the CI runner and nix was killed. CI
        # builds them on their own runners instead -- see the `home` matrix in
        # .github/workflows/ci.yml.
      });
    };
}
