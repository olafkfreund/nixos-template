# Advanced System Performance Monitoring Module
# Comprehensive monitoring with Prometheus exporters, alerting, and system health checks

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.services.monitoring;
  
  # Helper function to generate exporter configurations
  mkExporterConfig = name: exporterCfg: {
    enable = true;
    port = exporterCfg.port;
    listenAddress = exporterCfg.listenAddress or "127.0.0.1";
    extraFlags = exporterCfg.extraFlags or [];
  } // (removeAttrs exporterCfg ["port" "listenAddress" "extraFlags"]);

  # Default exporter configurations
  defaultExporters = {
    node = {
      port = 9100;
      listenAddress = "0.0.0.0";
      enabledCollectors = [
        "systemd"
        "processes" 
        "interrupts"
        "buddyinfo"
        "meminfo_numa"
        "netstat"
        "vmstat"
        "filesystem"
        "diskstats"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "time"
        "uname"
        "version"
      ];
      disabledCollectors = [
        "arp"
        "bcache"
        "bonding"
        "btrfs"
        "conntrack"
        "cpufreq"
        "edac"
        "entropy"
        "fibrechannel"
        "hwmon"
        "infiniband"
        "ipvs"
        "ksmd"
        "logind"
        "mdadm"
        "nfs"
        "nfsd"
        "nvme"
        "powersupplyclass"
        "pressure"
        "rapl"
        "schedstat"
        "sockstat"
        "softnet"
        "tapestats"
        "textfile"
        "thermal_zone"
        "udp_queues"
        "wifi"
        "xfs"
        "zfs"
      ];
    };
    
    systemd = {
      port = 9558;
      listenAddress = "127.0.0.1";
    };

    process = {
      port = 9256;
      listenAddress = "127.0.0.1";
      config = {
        process_names = [
          {
            name = "{{.Comm}}";
            cmdline = [ ".+" ];
          }
        ];
      };
    };

    blackbox = {
      port = 9115;
      listenAddress = "127.0.0.1";
      configFile = pkgs.writeText "blackbox.yml" ''
        modules:
          http_2xx:
            prober: http
            http:
              valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
              valid_status_codes: []
              method: GET
          http_post_2xx:
            prober: http
            http:
              method: POST
          tcp_connect:
            prober: tcp
          pop3s_banner:
            prober: tcp
            tcp:
              query_response:
              - expect: "^+OK"
              tls: true
              tls_config:
                insecure_skip_verify: false
          grpc:
            prober: grpc
            grpc:
              tls: true
              preferred_ip_protocol: "ip4"
          grpc_plain:
            prober: grpc
            grpc:
              tls: false
              service: "service1"
          ssh_banner:
            prober: tcp
            tcp:
              query_response:
              - expect: "^SSH-2.0-"
          irc_banner:
            prober: tcp
            tcp:
              query_response:
              - send: "NICK prober"
              - send: "USER prober prober prober :prober"
              - expect: "PING :([^ ]+)"
                send: "PONG :1"
              - expect: "^:[^ ]+ 001"
          icmp:
            prober: icmp
      '';
    };
  };
  
  # Generate alerting rules
  generateAlertRules = {
    groups = [
      {
        name = "system.rules";
        rules = [
          {
            alert = "HighCpuUsage";
            expr = "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80";
            for = "5m";
            labels.severity = "warning";
            annotations = {
              summary = "High CPU usage detected";
              description = "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}";
            };
          }
          {
            alert = "HighMemoryUsage";
            expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90";
            for = "5m";
            labels.severity = "critical";
            annotations = {
              summary = "High memory usage detected";
              description = "Memory usage is above 90% on {{ $labels.instance }}";
            };
          }
          {
            alert = "DiskSpaceLow";
            expr = "(1 - (node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes)) * 100 > 85";
            for = "10m";
            labels.severity = "warning";
            annotations = {
              summary = "Disk space is running low";
              description = "Disk usage is above 85% on {{ $labels.instance }} filesystem {{ $labels.mountpoint }}";
            };
          }
          {
            alert = "SystemdServiceFailed";
            expr = "node_systemd_unit_state{state=\"failed\"} == 1";
            for = "0m";
            labels.severity = "warning";
            annotations = {
              summary = "Systemd service failed";
              description = "Systemd service {{ $labels.name }} has failed on {{ $labels.instance }}";
            };
          }
          {
            alert = "HighLoadAverage";
            expr = "node_load15 > (count(node_cpu_seconds_total{mode=\"idle\"}) by (instance)) * 1.5";
            for = "10m";
            labels.severity = "warning";
            annotations = {
              summary = "High load average";
              description = "Load average is high on {{ $labels.instance }}. Current value: {{ $value }}";
            };
          }
        ];
      }
    ];
  };
in

{
  options.modules.services.monitoring = {
    enable = mkEnableOption "comprehensive system monitoring";

    prometheus = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus server";
      };

      port = mkOption {
        type = types.port;
        default = 9090;
        description = "Prometheus server port";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Prometheus server listen address";
      };

      retention = mkOption {
        type = types.str;
        default = "30d";
        description = "Prometheus data retention period";
      };

      scrapeInterval = mkOption {
        type = types.str;
        default = "15s";
        description = "Global scrape interval";
      };

      evaluationInterval = mkOption {
        type = types.str;
        default = "15s";
        description = "Rule evaluation interval";
      };

      alerting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable built-in alerting rules";
        };

        customRules = mkOption {
          type = types.lines;
          default = "";
          description = "Custom Prometheus alerting rules in YAML format";
        };
      };

      remoteWrite = mkOption {
        type = types.listOf (types.submodule {
          options = {
            url = mkOption {
              type = types.str;
              description = "Remote write URL";
            };
            
            basicAuth = mkOption {
              type = types.nullOr (types.submodule {
                options = {
                  username = mkOption {
                    type = types.str;
                    description = "Basic auth username";
                  };
                  password = mkOption {
                    type = types.str;
                    description = "Basic auth password";
                  };
                };
              });
              default = null;
              description = "Basic authentication configuration";
            };
          };
        });
        default = [];
        description = "Remote write configurations";
      };
    };

    exporters = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable this exporter";
          };

          port = mkOption {
            type = types.port;
            description = "Exporter port";
          };

          listenAddress = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Exporter listen address";
          };

          extraFlags = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Additional command line flags";
          };

          extraConfig = mkOption {
            type = types.attrs;
            default = {};
            description = "Additional exporter-specific configuration";
          };
        };
      });
      default = {};
      description = "Prometheus exporters configuration";
    };

    grafana = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Grafana dashboard";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Grafana server port";
      };

      domain = mkOption {
        type = types.str;
        default = "localhost";
        description = "Grafana domain";
      };

      adminPassword = mkOption {
        type = types.str;
        default = "admin";
        description = "Grafana admin password";
      };
    };

    systemHealth = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system health monitoring";
      };

      checkInterval = mkOption {
        type = types.str;
        default = "1m";
        description = "System health check interval";
      };

      checks = mkOption {
        type = types.listOf (types.enum [
          "disk-space"
          "memory-usage" 
          "cpu-temperature"
          "service-status"
          "network-connectivity"
          "certificate-expiry"
        ]);
        default = [ "disk-space" "memory-usage" "service-status" ];
        description = "System health checks to perform";
      };
    };

    logAggregation = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable log aggregation with Loki";
      };

      retention = mkOption {
        type = types.str;
        default = "7d";
        description = "Log retention period";
      };
    };

    notification = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable notification system";
      };

      webhook = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Webhook URL for notifications";
      };

      email = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            to = mkOption {
              type = types.listOf types.str;
              description = "Email recipients";
            };
            from = mkOption {
              type = types.str;
              description = "Sender email address";
            };
            smtpHost = mkOption {
              type = types.str;
              description = "SMTP server host";
            };
            smtpPort = mkOption {
              type = types.port;
              default = 587;
              description = "SMTP server port";
            };
          };
        });
        default = null;
        description = "Email notification configuration";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Prometheus server configuration
    (mkIf cfg.prometheus.enable {
      services.prometheus = {
        enable = true;
        port = cfg.prometheus.port;
        listenAddress = cfg.prometheus.listenAddress;
        retentionTime = cfg.prometheus.retention;

        globalConfig = {
          scrape_interval = cfg.prometheus.scrapeInterval;
          evaluation_interval = cfg.prometheus.evaluationInterval;
        };

        # Remote write configuration
        remoteWrite = cfg.prometheus.remoteWrite;

        # Scrape configurations
        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [{
              targets = [ "${cfg.prometheus.listenAddress}:${toString cfg.prometheus.port}" ];
            }];
          }
        ] ++ (mapAttrsToList (name: exporterCfg: {
          job_name = "exporter-${name}";
          static_configs = [{
            targets = [ "${exporterCfg.listenAddress}:${toString exporterCfg.port}" ];
          }];
          scrape_interval = "30s";
        }) (filterAttrs (_: exp: exp.enable) cfg.exporters));

        # Alerting rules
        ruleFiles = mkIf cfg.prometheus.alerting.enable [
          (pkgs.writeText "monitoring-rules.yml" (builtins.toJSON generateAlertRules))
        ] ++ optionals (cfg.prometheus.alerting.customRules != "") [
          (pkgs.writeText "custom-rules.yml" cfg.prometheus.alerting.customRules)
        ];
      };

      # Open firewall for Prometheus
      networking.firewall.allowedTCPPorts = [ cfg.prometheus.port ];
    })

    # Exporters configuration
    {
      services.prometheus.exporters = mkMerge (mapAttrsToList (name: exporterCfg:
        mkIf exporterCfg.enable {
          ${name} = mkExporterConfig name (defaultExporters.${name} or {} // exporterCfg.extraConfig // {
            inherit (exporterCfg) port listenAddress;
          });
        }
      ) cfg.exporters);

      # Open firewall ports for enabled exporters
      networking.firewall.allowedTCPPorts = 
        map (exp: exp.port) (filter (exp: exp.enable) (attrValues cfg.exporters));
    }

    # Grafana configuration
    (mkIf cfg.grafana.enable {
      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_port = cfg.grafana.port;
            domain = cfg.grafana.domain;
          };
          security = {
            admin_password = cfg.grafana.adminPassword;
          };
          analytics = {
            reporting_enabled = false;
            check_for_updates = false;
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [{
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://${cfg.prometheus.listenAddress}:${toString cfg.prometheus.port}";
            isDefault = true;
          }];

          dashboards.settings.providers = [{
            name = "System Monitoring";
            type = "file";
            folder = "System";
            options.path = pkgs.writeTextDir "dashboards/system.json" (builtins.toJSON {
              dashboard = {
                id = null;
                title = "System Monitoring";
                tags = [ "system" "monitoring" ];
                timezone = "browser";
                panels = [
                  {
                    id = 1;
                    title = "CPU Usage";
                    type = "stat";
                    targets = [{
                      expr = "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
                      refId = "A";
                    }];
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        min = 0;
                        max = 100;
                      };
                    };
                    gridPos = { h = 8; w = 12; x = 0; y = 0; };
                  }
                  {
                    id = 2;
                    title = "Memory Usage";
                    type = "stat";
                    targets = [{
                      expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100";
                      refId = "A";
                    }];
                    fieldConfig = {
                      defaults = {
                        unit = "percent";
                        min = 0;
                        max = 100;
                      };
                    };
                    gridPos = { h = 8; w = 12; x = 12; y = 0; };
                  }
                ];
                time = {
                  from = "now-1h";
                  to = "now";
                };
                refresh = "30s";
              };
            });
          }];
        };
      };

      # Open firewall for Grafana
      networking.firewall.allowedTCPPorts = [ cfg.grafana.port ];
    })

    # System health monitoring
    (mkIf cfg.systemHealth.enable {
      systemd.services.system-health-monitor = {
        description = "System Health Monitor";
        serviceConfig = {
          Type = "oneshot";
          User = "nobody";
          Group = "nobody";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          NoNewPrivileges = true;
        };

        script = let
          healthScript = pkgs.writeShellScript "system-health-check" ''
            #!/bin/bash
            set -euo pipefail
            
            log_metric() {
              echo "$1" | systemd-cat -t system-health -p info
            }
            
            log_alert() {
              echo "ALERT: $1" | systemd-cat -t system-health -p warning
            }
            
            ${optionalString (elem "disk-space" cfg.systemHealth.checks) ''
            # Check disk space
            while read -r filesystem blocks used available capacity mountpoint; do
              if [[ "$capacity" =~ ^([0-9]+)% ]] && [ "''${BASH_REMATCH[1]}" -gt 85 ]; then
                log_alert "Disk space low on $mountpoint: $capacity used"
              fi
            done < <(df -h | tail -n +2 | grep -E '^/dev/')
            ''}
            
            ${optionalString (elem "memory-usage" cfg.systemHealth.checks) ''
            # Check memory usage
            memory_percent=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
            if [ "$memory_percent" -gt 90 ]; then
              log_alert "High memory usage: $memory_percent%"
            fi
            log_metric "memory_usage_percent=$memory_percent"
            ''}
            
            ${optionalString (elem "service-status" cfg.systemHealth.checks) ''
            # Check critical service status
            failed_services=$(systemctl list-units --failed --no-legend | wc -l)
            if [ "$failed_services" -gt 0 ]; then
              log_alert "$failed_services systemd services have failed"
              systemctl list-units --failed --no-legend | while read -r unit _; do
                log_alert "Failed service: $unit"
              done
            fi
            log_metric "failed_services_count=$failed_services"
            ''}
            
            ${optionalString (elem "cpu-temperature" cfg.systemHealth.checks) ''
            # Check CPU temperature (if sensors available)
            if command -v sensors >/dev/null; then
              max_temp=$(sensors | grep -E 'Core|Package' | grep -oE '\+[0-9]+\.[0-9]+°C' | sed 's/+\([0-9]*\).*/\1/' | sort -n | tail -1)
              if [ -n "$max_temp" ] && [ "$max_temp" -gt 80 ]; then
                log_alert "High CPU temperature: $max_temp°C"
              fi
              log_metric "cpu_max_temp_celsius=$max_temp"
            fi
            ''}
            
            ${optionalString (elem "network-connectivity" cfg.systemHealth.checks) ''
            # Check network connectivity
            if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
              log_alert "Network connectivity check failed"
              log_metric "network_connectivity=0"
            else
              log_metric "network_connectivity=1"
            fi
            ''}
            
            log_metric "health_check_completed=1"
          '';
        in "${healthScript}";

        startAt = cfg.systemHealth.checkInterval;
      };

      # Install lm-sensors if temperature monitoring is enabled
      environment.systemPackages = mkIf (elem "cpu-temperature" cfg.systemHealth.checks) [
        pkgs.lm_sensors
      ];
    })

    # Log aggregation with Loki
    (mkIf cfg.logAggregation.enable {
      services.loki = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 3100;
            grpc_listen_port = 9096;
          };
          
          ingester = {
            lifecycler = {
              address = "127.0.0.1";
              ring = {
                kvstore = {
                  store = "inmemory";
                };
                replication_factor = 1;
              };
            };
            chunk_idle_period = "1h";
            max_chunk_age = "1h";
            chunk_target_size = 999999;
            chunk_retain_period = "30s";
          };
          
          schema_config = {
            configs = [{
              from = "2020-10-24";
              store = "boltdb-shipper";
              object_store = "filesystem";
              schema = "v11";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }];
          };
          
          storage_config = {
            boltdb_shipper = {
              active_index_directory = "/var/lib/loki/boltdb-shipper-active";
              cache_location = "/var/lib/loki/boltdb-shipper-cache";
              cache_ttl = "24h";
              shared_store = "filesystem";
            };
            
            filesystem = {
              directory = "/var/lib/loki/chunks";
            };
          };
          
          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
            retention_period = cfg.logAggregation.retention;
          };
          
          chunk_store_config = {
            max_look_back_period = "0s";
          };
          
          table_manager = {
            retention_deletes_enabled = true;
            retention_period = cfg.logAggregation.retention;
          };
        };
      };

      services.promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 3031;
            grpc_listen_port = 3032;
          };
          
          positions = {
            filename = "/tmp/positions.yaml";
          };
          
          clients = [{
            url = "http://localhost:3100/loki/api/v1/push";
          }];
          
          scrape_configs = [{
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [{
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }];
          }];
        };
      };
    })

    # Basic monitoring packages
    {
      environment.systemPackages = with pkgs; [
        # Monitoring tools
        htop
        iotop
        nethogs
        iftop
        nload
        
        # System information
        neofetch
        lscpu
        lsblk
        lsusb
        lspci
        
        # Performance testing
        stress-ng
        sysbench
        iperf3
        
        # Network diagnostics
        mtr
        nmap
        tcpdump
        wireshark-cli
      ];
    }

    # Enable default exporters based on system type
    {
      modules.services.monitoring.exporters = {
        node = {
          enable = mkDefault true;
          port = mkDefault 9100;
          listenAddress = mkDefault "0.0.0.0";
        };
        
        systemd = {
          enable = mkDefault true;
          port = mkDefault 9558;
        };

        # Enable additional exporters based on hardware profile if available
        process = mkIf (config.modules.hardware.detection.enable or false) {
          enable = mkDefault true;
          port = mkDefault 9256;
        };
      };
    }
  ]);
}