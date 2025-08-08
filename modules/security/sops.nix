# SOPS-based Secrets Management
# Provides centralized, declarative secret management using sops-nix

{ config, lib, pkgs, ... }:

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

  config = mkIf cfg.enable {
    # SOPS configuration
    sops = {
      defaultSopsFile = mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;

      age = {
        keyFile = cfg.age.keyFile;
        generateKey = cfg.age.generateKey;
      };

      # Configure secrets
      secrets = mapAttrs
        (name: secretCfg: {
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
        (name: templateCfg: {
          content = templateCfg.content;
          owner = templateCfg.owner;
          group = templateCfg.group;
          mode = templateCfg.mode;
          path = templateCfg.path;
        })
        cfg.templates;
    };

    # Ensure sops user exists
    users.users.sops-nix = {
      isSystemUser = true;
      group = "sops-nix";
    };
    users.groups.sops-nix = { };

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

  # Usage examples in comments:
  /*
    # Example configuration:
    modules.security.sops = {
    enable = true;
    defaultSopsFile = ./secrets/secrets.yaml;

    secrets = {
      "database/password" = {
        owner = "postgresql";
        group = "postgresql";
        mode = "0440";
        restartUnits = [ "postgresql.service" ];
      };

      "api/keys/github" = {
        path = "/run/secrets/github-token";
        owner = "git";
        mode = "0400";
      };
    };

    templates = {
      "app-config" = {
        content = ''
          database_url=postgresql://user:${config.sops.placeholder."database/password"}@localhost/db
          github_token=${config.sops.placeholder."api/keys/github"}
        '';
        path = "/run/secrets/app.env";
        owner = "app";
        mode = "0440";
      };
    };
    };
  */
}
