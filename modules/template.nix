# Advanced NixOS Module Template
# Demonstrates best practices for NixOS module development with comprehensive
# validation, assertions, and type safety

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.template;

  # Advanced type definitions
  serviceType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Service name";
        example = "example-service";
      };

      port = mkOption {
        type = types.port;
        description = "Service port";
        example = 8080;
      };

      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this service";
      };

      extraConfig = mkOption {
        type = types.attrs;
        default = { };
        description = "Additional configuration options";
        example = { timeout = 30; };
      };
    };
  };

  # Validation functions
  validatePort = port: port > 1024 && port < 65536;
  validateServiceName = name: builtins.match "^[a-zA-Z0-9][a-zA-Z0-9_-]*$" name != null;

  # Helper functions
  mkService = name: cfg: {
    inherit name;
    systemd.services.${name} = {
      description = "Template service: ${name}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user or "nobody";
        Group = cfg.group or "nobody";
        Restart = "always";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        RestrictSUIDSGID = true;
      };

      script = ''
        echo "Starting ${name} on port ${toString cfg.port}"
        # Service implementation would go here
      '';
    };
  };
in

{
  # Module metadata
  meta = {
    maintainers = with lib.maintainers; [ ]; # Add maintainers here
    # doc = ./template.md; # Documentation file - commented to avoid missing file error
  };

  options.modules.template = {
    enable = mkEnableOption "template module with advanced features";

    package = mkPackageOption pkgs "hello" {
      description = "Package to use for the template service";
      example = "pkgs.hello";
    };

    # Advanced configuration options
    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Configuration settings for the template service";
      example = {
        logLevel = "info";
        timeout = 30;
        retries = 3;
      };
    };

    # Service configuration with validation
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Services to configure";
      example = {
        "web-service" = {
          name = "web-service";
          port = 8080;
          enable = true;
        };
      };
    };

    # Network configuration
    networking = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Default port for template services";
      };

      interface = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Interface to bind to";
      };

      allowedIPs = mkOption {
        type = types.listOf types.str;
        default = [ "127.0.0.1" ];
        description = "IP addresses allowed to connect";
        example = [ "127.0.0.1" "192.168.1.0/24" ];
      };
    };

    # User and security configuration
    user = mkOption {
      type = types.str;
      default = "template";
      description = "User to run template services as";
    };

    group = mkOption {
      type = types.str;
      default = "template";
      description = "Group to run template services as";
    };

    # Logging configuration
    logging = {
      level = mkOption {
        type = types.enum [ "debug" "info" "warn" "error" ];
        default = "info";
        description = "Log level";
      };

      file = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Log file path (null for stdout)";
      };

      rotate = mkOption {
        type = types.bool;
        default = true;
        description = "Enable log rotation";
      };
    };

    # Resource limits
    resources = {
      memory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Memory limit (e.g., '1G', '512M')";
        example = "1G";
      };

      cpu = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "CPU limit (e.g., '50%', '2')";
        example = "50%";
      };
    };

    # Feature flags
    features = {
      metrics = mkEnableOption "Prometheus metrics endpoint";
      healthCheck = mkEnableOption "health check endpoint";
      apiDocs = mkEnableOption "API documentation";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Basic assertions and validations
    {
      assertions = [
        {
          assertion = validatePort cfg.networking.port;
          message = "Template port must be between 1025 and 65535";
        }
        {
          assertion = cfg.settings != { } -> cfg.settings ? logLevel;
          message = "Template settings must include logLevel when specified";
        }
        {
          assertion = all (service: validateServiceName service.name) (attrValues cfg.services);
          message = "Service names must be valid identifiers";
        }
        {
          assertion = all (service: validatePort service.port) (attrValues cfg.services);
          message = "All service ports must be between 1025 and 65535";
        }
        {
          assertion = cfg.resources.memory != null -> builtins.match "^[0-9]+[MGT]?$" cfg.resources.memory != null;
          message = "Memory limit must be in format like '1G', '512M', etc.";
        }
      ];

      warnings = [
        (mkIf (cfg.settings == { }) "Template module enabled but no settings configured")
        (mkIf (!cfg.features.metrics) "Metrics collection disabled - monitoring may be limited")
        (mkIf (cfg.networking.allowedIPs == [ "127.0.0.1" ]) "Template only allows localhost connections")
      ];
    }

    # User and group management
    {
      users = {
        users.${cfg.user} = {
          description = "Template service user";
          inherit (cfg) group;
          isSystemUser = true;
          home = "/var/lib/${cfg.user}";
          createHome = true;
        };

        groups.${cfg.group} = { };
      };

      # Create necessary directories
      systemd.tmpfiles.rules = [
        "d /var/lib/${cfg.user} 0755 ${cfg.user} ${cfg.group} -"
        "d /var/log/${cfg.user} 0755 ${cfg.user} ${cfg.group} -"
      ] ++ optional (cfg.logging.file != null)
        "f ${cfg.logging.file} 0644 ${cfg.user} ${cfg.group} -";
    }

    # Networking and firewall
    {
      networking.firewall = {
        allowedTCPPorts = [ cfg.networking.port ] ++
          (map (service: service.port) (filter (s: s.enable) (attrValues cfg.services)));

        # Advanced firewall rules for IP restrictions
        extraCommands = mkIf (cfg.networking.allowedIPs != [ ]) (
          concatMapStringsSep "\n"
            (ip:
              "iptables -A nixos-fw -p tcp --dport ${toString cfg.networking.port} -s ${ip} -j ACCEPT"
            )
            cfg.networking.allowedIPs
        );
      };
    }

    # Service configuration
    (mkIf (cfg.services != { }) {
      systemd.services = mapAttrs'
        (name: serviceCfg:
          nameValuePair name {
            description = "Template service: ${name}";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
              Type = "simple";
              User = cfg.user;
              Group = cfg.group;
              Restart = "always";
              RestartSec = 5;

              # Apply resource limits if specified
              MemoryMax = mkIf (cfg.resources.memory != null) cfg.resources.memory;
              CPUQuota = mkIf (cfg.resources.cpu != null) cfg.resources.cpu;

              # Security hardening
              NoNewPrivileges = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectKernelTunables = true;
              ProtectControlGroups = true;
              ProtectKernelModules = true;
              RestrictSUIDSGID = true;
              RestrictRealtime = true;
              LockPersonality = true;
              MemoryDenyWriteExecute = true;

              # Namespace isolation
              PrivateDevices = true;
              PrivateNetwork = false; # Set to true if no network needed
              ProtectKernelLogs = true;
              ProtectClock = true;
            };

            script = ''
              echo "Starting ${name} on port ${toString serviceCfg.port}"
              echo "Configuration: ${builtins.toJSON serviceCfg.extraConfig}"
            
              # Start the actual service
              exec ${cfg.package}/bin/hello
            '';

            preStart = ''
              echo "Preparing ${name}..."
              # Pre-start checks and preparations
            '';

            postStart = ''
              # Wait for service to be ready
              timeout 30 bash -c 'until nc -z localhost ${toString serviceCfg.port}; do sleep 1; done'
            '';
          }
        )
        (filterAttrs (_: s: s.enable) cfg.services);
    })

    # Monitoring and metrics
    (mkIf cfg.features.metrics {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" "processes" ];
      };

      # Custom metrics collection script
      systemd.services.template-metrics = {
        description = "Template Metrics Collection";
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
        };
        script = ''
          # Collect custom metrics
          echo "template_services_total $(systemctl list-units --type=service | grep -c template)" > /var/lib/prometheus-node-exporter-text-files/template.prom
        '';
        startAt = "minutely";
      };
    })

    # Health checks
    (mkIf cfg.features.healthCheck {
      systemd.services.template-healthcheck = {
        description = "Template Health Check";
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
        };
        script = ''
          # Perform health checks on all enabled services
          ${concatMapStringsSep "\n" (name: serviceCfg: ''
            if ! nc -z localhost ${toString serviceCfg.port}; then
              echo "Health check failed for ${name}"
              exit 1
            fi
          '') (filterAttrs (_: s: s.enable) cfg.services)}
          
          echo "All services healthy"
        '';
        startAt = "*:0/5"; # Every 5 minutes
      };
    })

    # Log rotation
    (mkIf cfg.logging.rotate {
      services.logrotate = {
        enable = true;
        settings."${cfg.user}" = {
          files = [ "/var/log/${cfg.user}/*.log" ];
          frequency = "weekly";
          rotate = 4;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
          create = "644 ${cfg.user} ${cfg.group}";
        };
      };
    })

    # Environment and packages
    {
      environment.systemPackages = with pkgs; [
        cfg.package

        # Debugging and monitoring tools
        netcat
        lsof
        strace

        # Configuration tools
        jq
        yq
      ];

      # Environment variables for template services
      environment.variables = {
        TEMPLATE_USER = cfg.user;
        TEMPLATE_GROUP = cfg.group;
        TEMPLATE_PORT = toString cfg.networking.port;
        TEMPLATE_LOG_LEVEL = cfg.logging.level;
      };
    }

    # Development and testing support
    (mkIf config.modules.development.enable or false {
      # Additional development packages when dev mode is enabled
      environment.systemPackages = with pkgs; [
        curl
        httpie
        wrk # HTTP benchmarking
      ];

      # Development-specific configuration
      systemd.services.template-dev-server = {
        description = "Template Development Server";
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Restart = "no"; # Don't restart in dev mode
        };
        script = ''
          echo "Development mode - additional debugging enabled"
          # Development server implementation
        '';
        wantedBy = mkForce [ ]; # Don't auto-start in dev mode
      };
    })
  ]);
}
