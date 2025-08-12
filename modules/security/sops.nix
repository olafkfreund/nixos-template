# SOPS-based Secrets Management (DEPRECATED)
# This module is deprecated in favor of agenix
# Please migrate to agenix for new configurations
# See docs/AGENIX-SECRETS.md for migration guide

{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.modules.security.sops;
in

{
  options.modules.security.sops = {
    enable = mkEnableOption "SOPS secrets management";

    defaultSopsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Default SOPS file for secrets";
      example = literalExpression "../secrets/secrets.yaml";
    };

    age = {
      keyFile = mkOption {
        type = types.nullOr types.str;
        default = "/var/lib/sops-nix/key.txt";
        description = "Path to the age private key file";
      };

      generateKey = mkOption {
        type = types.bool;
        default = true;
        description = "Generate age key if it doesn't exist";
      };
    };

    secrets = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          sopsFile = mkOption {
            type = types.nullOr types.path;
            default = cfg.defaultSopsFile;
            description = "SOPS file containing this secret";
          };

          key = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Key in the SOPS file (defaults to secret name)";
          };

          path = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path where secret should be available";
          };

          owner = mkOption {
            type = types.str;
            default = "root";
            description = "Owner of the secret file";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group of the secret file";
          };

          mode = mkOption {
            type = types.str;
            default = "0400";
            description = "Permissions for the secret file";
          };

          restartUnits = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Systemd units to restart when secret changes";
          };

          reloadUnits = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Systemd units to reload when secret changes";
          };
        };
      });
      default = { };
      description = "Secrets to manage with SOPS";
    };

    # Common secret templates
    templates = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          content = mkOption {
            type = types.str;
            description = "Template content with secret references";
          };

          owner = mkOption {
            type = types.str;
            default = "root";
            description = "Owner of the template file";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group of the template file";
          };

          mode = mkOption {
            type = types.str;
            default = "0400";
            description = "Permissions for the template file";
          };

          path = mkOption {
            type = types.str;
            description = "Where to write the template";
          };
        };
      });
      default = { };
      description = "Templates for combining multiple secrets";
    };
  };

  config = mkIf (cfg.enable && options ? sops) {
    # Only configure sops if the sops-nix module is available
    # This prevents errors when sops-nix is not imported
    sops = {
      defaultSopsFile = mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

      age = {
        keyFile = cfg.age.keyFile;
        generateKey = cfg.age.generateKey;
      };

      # Configure secrets
      secrets = mapAttrs
        (_name: secretCfg: {
          sopsFile = mkIf (secretCfg.sopsFile != null) secretCfg.sopsFile;
          key = mkIf (secretCfg.key != null) secretCfg.key;
          path = mkIf (secretCfg.path != null) secretCfg.path;
          owner = secretCfg.owner;
          group = secretCfg.group;
          mode = secretCfg.mode;
          restartUnits = secretCfg.restartUnits;
          reloadUnits = secretCfg.reloadUnits;
        })
        cfg.secrets;

      # Configure templates
      templates = mapAttrs
        (_name: templateCfg: {
          content = templateCfg.content;
          owner = templateCfg.owner;
          group = templateCfg.group;
          mode = templateCfg.mode;
          path = templateCfg.path;
        })
        cfg.templates;
    };

    # SOPS-nix manages users automatically - no manual user creation needed

    # Development tools for secrets management
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age # Convert SSH keys to age keys
    ];

    # System service for key generation
    systemd.services.sops-generate-key = mkIf cfg.age.generateKey {
      description = "Generate SOPS age key if missing";
      wantedBy = [ "multi-user.target" ];
      before = [ "sops-nix.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "generate-sops-key" ''
          KEY_FILE="${cfg.age.keyFile}"
          KEY_DIR=$(dirname "$KEY_FILE")

          if [[ ! -f "$KEY_FILE" ]]; then
            mkdir -p "$KEY_DIR"
            ${pkgs.age}/bin/age-keygen -o "$KEY_FILE"
            chmod 600 "$KEY_FILE"
            echo "Generated new SOPS age key at $KEY_FILE"
            echo "Public key: $(${pkgs.age}/bin/age-keygen -y "$KEY_FILE")"
          fi
        '';
        RemainAfterExit = true;
      };
    };
  };

  # For usage examples, see: examples/expert-improvements-usage.nix
}
