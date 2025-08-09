# System Identification Module
# Standardizes hostname, profile, and metadata patterns across all configurations
{ config, lib, pkgs, inputs ? null, outputs ? null, flakeMeta ? null, ... }:

with lib;

let
  cfg = config.systemId;

  # Derive profile from hostname if not explicitly set
  deriveProfile = hostname:
    if hasInfix "server" hostname then "server"
    else if hasInfix "laptop" hostname then "laptop"
    else if hasInfix "desktop" hostname then "workstation"
    else if hasInfix "gaming" hostname then "gaming"
    else if hasInfix "vm" hostname then "workstation"
    else if hasInfix "test" hostname then "workstation"
    else "workstation"; # Default fallback

  # System type detection
  systemType =
    if config.wsl.enable or false then "wsl"
    else if config.virtualisation.vmware.guest.enable or false then "vm"
    else if config.virtualisation.virtualbox.guest.enable or false then "vm"
    else if config.virtualisation.qemu.guest.enable or false then "vm"
    else if config.hardware.vmware.guest.enable or false then "vm"
    else if pkgs.stdenv.hostPlatform.isDarwin then "darwin"
    else "physical";

  # Standard naming patterns
  standardizedHostname =
    if cfg.useSystemTypePrefix then
      if systemType == "vm" then "nixos-vm-${cfg.baseName}"
      else if systemType == "wsl" then "nixos-wsl-${cfg.baseName}"
      else if systemType == "darwin" then "nix-darwin-${cfg.baseName}"
      else cfg.baseName
    else cfg.baseName;

  # Computer/display name for Darwin systems
  darwinComputerName =
    if cfg.profile == "server" then "nix-darwin Server"
    else if cfg.profile == "laptop" then "nix-darwin Laptop"
    else if cfg.profile == "workstation" then "nix-darwin Desktop"
    else "nix-darwin System";

  # Standard state version based on system type
  standardStateVersion =
    if pkgs.stdenv.hostPlatform.isDarwin then 5
    else "25.05";

in
{
  options.systemId = {
    baseName = mkOption {
      type = types.str;
      default = "nixos-system";
      description = "Base name for the system (without type prefixes)";
      example = "workstation-01";
    };

    profile = mkOption {
      type = types.enum [ "workstation" "server" "laptop" "gaming" "development" "minimal" ];
      description = "System profile type";
      default = deriveProfile (if flakeMeta != null then flakeMeta.hostname or cfg.baseName else cfg.baseName);
    };

    useSystemTypePrefix = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add system type prefixes to hostnames";
    };

    useFlakeMetadata = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to integrate with flake metadata system";
    };

    description = mkOption {
      type = types.str;
      description = "Human-readable system description";
      default = "${cfg.profile} system";
    };

    location = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Physical or logical location of the system";
      example = "Datacenter-A";
    };

    environment = mkOption {
      type = types.enum [ "production" "staging" "development" "testing" ];
      default = "production";
      description = "Environment classification";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Custom tags for system classification";
      example = [ "gpu-enabled" "high-memory" ];
    };
  };

  config = {
    # Standard hostname configuration (lowest priority for deployment images)
    networking = {
      hostName = lib.mkOverride 2000 standardizedHostname;
    } // optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Darwin-specific naming
      localHostName = mkDefault standardizedHostname;
      computerName = mkDefault darwinComputerName;
    };

    # Standard state version
    system.stateVersion = mkDefault standardStateVersion;

    # Environment configuration
    environment = {
      # Environment variables for system identification
      variables = mkIf (cfg.useFlakeMetadata && (flakeMeta != null)) ({
        SYSTEM_ID_PROFILE = cfg.profile;
        SYSTEM_ID_TYPE = systemType;
        SYSTEM_ID_ENVIRONMENT = cfg.environment;
      } // optionalAttrs (cfg.location != null) {
        SYSTEM_ID_LOCATION = cfg.location;
      });

      # Enhanced system info command
      systemPackages = [
        (pkgs.writeShellScriptBin "system-id" ''
          echo "🏗️  System Identification"
          echo "========================"
          echo ""
          echo "📋 Basic Information:"
          echo "  Hostname: ${config.networking.hostName}"
          echo "  Profile: ${cfg.profile}"
          echo "  Type: ${systemType}"
          echo "  Environment: ${cfg.environment}"
          ${optionalString (cfg.location != null) ''
          echo "  Location: ${cfg.location}"
          ''}
          echo "  Description: ${cfg.description}"
          echo ""
          echo "🏷️  Tags: ${concatStringsSep ", " cfg.tags}"
          echo ""
          echo "🖥️  Platform:"
          echo "  Architecture: $(uname -m)"
          ${if pkgs.stdenv.hostPlatform.isDarwin then ''
          echo "  macOS: $(sw_vers -productVersion)"
          echo "  Darwin State Version: ${toString config.system.stateVersion}"
          '' else ''
          echo "  Kernel: $(uname -r)"
          echo "  NixOS State Version: ${config.system.stateVersion}"
          ''}
          echo ""
          ${optionalString (cfg.useFlakeMetadata && (flakeMeta != null)) ''
          echo "🔧 Flake Metadata:"
          echo "  Build Date: ${flakeMeta.buildDate or "unknown"}"
          echo "  Flake Rev: ${flakeMeta.flakeShortRev or "unknown"}"
          echo "  Nixpkgs Rev: ${flakeMeta.nixpkgsShortRev or "unknown"}"
          echo ""
          ''}
          echo "⚙️  Configuration:"
          echo "  Config Path: ${if flakeMeta != null then flakeMeta.configPath or "Unknown" else "Unknown"}"
          echo "  System Type Prefix: ${if cfg.useSystemTypePrefix then "enabled" else "disabled"}"
          echo "  Flake Integration: ${if cfg.useFlakeMetadata then "enabled" else "disabled"}"
        '')

        (pkgs.writeShellScriptBin "system-tags" ''
          echo "🏷️  System Tags Management"
          echo "========================="
          echo ""
          echo "Current tags: ${concatStringsSep ", " cfg.tags}"
          echo ""
          echo "Common tag patterns:"
          echo "  Hardware: gpu-enabled, high-memory, ssd-storage"
          echo "  Purpose: build-server, database, web-frontend"
          echo "  Network: dmz, internal, management"
          echo "  Compliance: pci-compliant, hipaa, gdpr"
          echo ""
          echo "Note: Tags are configured in configuration.nix"
          echo "Add tags with: systemId.tags = [ \"tag1\" \"tag2\" ];"
        '')
      ];
    };

    # System description for nixos-version
    system.nixos.tags = mkDefault ([ cfg.profile systemType cfg.environment ] ++ cfg.tags);

    # Assertions for validation
    assertions = [
      {
        assertion = cfg.baseName != "";
        message = "systemId.baseName cannot be empty";
      }
      {
        assertion = !(hasInfix " " cfg.baseName);
        message = "systemId.baseName cannot contain spaces";
      }
      {
        assertion = stringLength cfg.baseName <= 63;
        message = "systemId.baseName must be 63 characters or less (hostname limit)";
      }
    ];

    # Warnings for common issues
    warnings =
      optional (cfg.baseName == "nixos")
        "Using default baseName 'nixos'. Consider setting a more specific systemId.baseName."
      ++
      optional (cfg.profile == "workstation" && systemType == "vm")
        "VM systems might be better suited for 'development' or 'testing' profile instead of 'workstation'."
      ++
      optional (!cfg.useFlakeMetadata && (flakeMeta != null))
        "Flake metadata is available but systemId.useFlakeMetadata is disabled.";
  };
}
