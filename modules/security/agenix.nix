{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.lists;

let
  cfg = config.modules.security.agenix;
in
{
  options.modules.security.agenix = {
    enable = mkEnableOption "Age-based secret management with agenix" // {
      description = ''
        Enable agenix for declarative secrets management using age encryption.
        
        Agenix provides secure, version-controlled secret management that integrates
        seamlessly with NixOS configurations. Secrets are encrypted with age keys
        and automatically decrypted at boot time to specified locations.
        
        Features:
        - Age-based encryption (modern alternative to GPG)
        - Declarative secret configuration in Nix
        - Automatic secret decryption and placement
        - Support for multiple recipients per secret
        - Integration with systemd services and user accounts
        
        See docs/AGENIX-SECRETS.md for setup and usage instructions.
      '';
    };

    secretsPath = mkOption {
      type = types.str;
      default = "/run/agenix";
      description = ''
        Base path where decrypted secrets will be stored at runtime.
        
        Secrets are decrypted to tmpfs (in-memory filesystem) for security.
        Individual secrets can override this location with the 'path' option.
      '';
    };

    secretsMode = mkOption {
      type = types.str;
      default = "0400";
      description = ''
        Default file permissions for decrypted secrets (octal notation).
        
        - "0400": Read-only for owner (recommended for most secrets)
        - "0440": Read-only for owner and group
        - "0444": World-readable (only for public certificates)
        
        Individual secrets can override this with their own mode setting.
      '';
      example = "0440";
    };

    secretsOwner = mkOption {
      type = types.str;
      default = "root";
      description = ''
        Default owner for decrypted secrets.
        
        Should match the user that needs to read the secret. For service-specific
        secrets, set this to the service user (e.g., "postgres", "nginx").
        Individual secrets can override this setting.
      '';
      example = "postgres";
    };

    secretsGroup = mkOption {
      type = types.str;
      default = "root";
      description = ''
        Default group for decrypted secrets.
        
        Useful for sharing secrets between multiple services or users.
        Individual secrets can override this setting.
      '';
      example = "nginx";
    };

    identityPaths = mkOption {
      type = types.listOf types.str;
      default = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_rsa_key"
      ];
      description = ''
        List of private key files used for decrypting secrets.
        
        These keys correspond to the public keys listed in secrets/secrets.nix.
        Default uses SSH host keys, but you can also use dedicated age keys:
        
        - SSH host keys: Available on all systems, rotated less frequently
        - Dedicated age keys: More secure, can be per-user or per-purpose
        
        Keys are tried in order until decryption succeeds.
      '';
      example = [
        "/etc/ssh/ssh_host_ed25519_key" 
        "/root/.config/age/key.txt"
      ];
    };

    secrets = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          file = mkOption {
            type = types.path;
            description = "Path to the encrypted secret file";
          };

          path = mkOption {
            type = types.str;
            default = "${cfg.secretsPath}/${name}";
            description = "Path where the decrypted secret will be installed";
          };

          mode = mkOption {
            type = types.str;
            default = cfg.secretsMode;
            description = "File mode for this secret";
          };

          owner = mkOption {
            type = types.str;
            default = cfg.secretsOwner;
            description = "Owner of this secret file";
          };

          group = mkOption {
            type = types.str;
            default = cfg.secretsGroup;
            description = "Group of this secret file";
          };

          symlink = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to create a symlink at the specified path";
          };
        };
      }));
      default = { };
      description = "Attribute set of secrets to decrypt";
      example = literalExpression ''
        {
          "wifi-password" = {
            file = ../secrets/wifi-password.age;
            owner = "networkmanager";
            group = "networkmanager";
            mode = "0440";
          };

          "user-password" = {
            file = ../secrets/user-password.age;
            path = "/run/agenix/user-password";
            mode = "0400";
          };
        }
      '';
    };

    installationType = mkOption {
      type = types.enum [ "activation" "system" ];
      default = "activation";
      description = ''
        Installation type for secrets:
        - activation: Install secrets during system activation
        - system: Install secrets as systemd services
      '';
    };
  };

  # Import agenix conditionally (only if input is available)
  imports = optionals (inputs ? agenix) [
    inputs.agenix.nixosModules.default
  ];

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = inputs ? agenix;
        message = "agenix input is required. Add agenix to your flake inputs.";
      }
      {
        assertion = cfg.identityPaths != [ ];
        message = "At least one identity path must be specified for agenix";
      }
    ];

    # Configure agenix
    age = {
      secrets = mapAttrs
        (_name: secretConfig: {
          file = secretConfig.file;
          path = secretConfig.path;
          mode = secretConfig.mode;
          owner = secretConfig.owner;
          group = secretConfig.group;
          symlink = secretConfig.symlink;
        })
        cfg.secrets;

      identityPaths = cfg.identityPaths;
    };

    # System packages for secret management
    environment.systemPackages = with pkgs; [
      age # Age encryption tool
      rage # Rust implementation of age
      ssh-to-age # Convert SSH keys to age keys
    ] ++ optionals (inputs ? agenix) [
      inputs.agenix.packages.${pkgs.system}.default # agenix CLI tool
    ];

    # Ensure secrets directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.secretsPath} 0755 root root -"
    ];

    # Additional security configurations
    security = {
      # Ensure proper permissions for SSH host keys used by agenix
      sudo.extraRules = [
        {
          users = [ "agenix" ];
          commands = [
            {
              command = "${pkgs.systemd}/bin/systemctl reload agenix-*";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    # Create agenix user for secret management
    users.users.agenix = {
      isSystemUser = true;
      group = "agenix";
      home = cfg.secretsPath;
    };

    users.groups.agenix = { };

    # Systemd services for secret management
    systemd.services = mkMerge [
      # General agenix secrets service
      {
        agenix-install-secrets = {
          description = "Install agenix secrets";
          wantedBy = [ "multi-user.target" ];
          after = [ "local-fs.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "root";
            Group = "root";
          };

          script = ''
            # Ensure secrets directory exists
            mkdir -p ${cfg.secretsPath}
            chmod 755 ${cfg.secretsPath}

            # Set proper ownership
            chown root:root ${cfg.secretsPath}

            echo "Agenix secrets installation completed"
          '';
        };
      }

      # Per-secret reload services (if using system installation)
      (mkIf (cfg.installationType == "system") (
        mapAttrs'
          (name: secretConfig: {
            name = "agenix-${name}";
            value = {
              description = "Agenix secret: ${name}";
              after = [ "agenix-install-secrets.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                User = "root";
                Group = "root";
              };

              script = ''
                # Verify secret file exists and has correct permissions
                if [ -f "${secretConfig.path}" ]; then
                  chmod ${secretConfig.mode} "${secretConfig.path}"
                  chown ${secretConfig.owner}:${secretConfig.group} "${secretConfig.path}"
                  echo "Secret ${name} installed successfully"
                else
                  echo "Warning: Secret ${name} not found at ${secretConfig.path}"
                  exit 1
                fi
              '';

              # Reload service when secret file changes
              restartTriggers = [ secretConfig.file ];
            };
          })
          cfg.secrets
      ))
    ];

    # Environment variables for agenix
    environment.variables = {
      AGENIX_SECRETS_PATH = cfg.secretsPath;
    };

    # Shell aliases for easier secret management
    environment.shellAliases = {
      agenix-edit = "agenix -e";
      agenix-rekey = "agenix -r";
      agenix-list = "ls -la ${cfg.secretsPath}";
    };
  };
}
