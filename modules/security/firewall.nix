# Advanced Firewall Configuration with nftables
# Provides modern, high-performance firewall rules with advanced features

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.security.firewall;
in

{
  options.modules.security.firewall = {
    enable = mkEnableOption "Advanced nftables-based firewall";

    profile = mkOption {
      type = types.enum [ "desktop" "server" "gaming" "development" ];
      default = "desktop";
      description = "Firewall profile with preset rules";
    };

    # Enhanced logging
    logging = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable firewall logging";
      };

      level = mkOption {
        type = types.enum [ "emerg" "alert" "crit" "err" "warn" "notice" "info" "debug" ];
        default = "warn";
        description = "Log level for firewall events";
      };

      rateLimit = mkOption {
        type = types.str;
        default = "10/minute";
        description = "Rate limit for firewall logs";
      };
    };

    # Advanced protection
    protection = {
      enableDDoSProtection = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DDoS protection rules";
      };

      enablePortScanning = mkOption {
        type = types.bool;
        default = true;
        description = "Enable port scanning detection";
      };

      enableBruteForceProtection = mkOption {
        type = types.bool;
        default = true;
        description = "Enable brute force protection for SSH";
      };

      maxConnections = mkOption {
        type = types.int;
        default = 25;
        description = "Maximum concurrent connections per IP";
      };
    };

    # Custom rules
    customRules = {
      input = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Custom input chain rules";
      };

      output = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Custom output chain rules";
      };

      forward = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Custom forward chain rules";
      };
    };

    # Allowed services by profile
    allowedPorts = {
      tcp = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "TCP ports to allow";
      };

      udp = mkOption {
        type = types.listOf types.port;
        default = [ ];
        description = "UDP ports to allow";
      };
    };

    # Trusted networks
    trustedNetworks = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.0/8" "::1/128" ];
      description = "Networks to trust completely";
    };

    # Banned IPs/networks
    blacklist = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "IPs or networks to block completely";
    };
  };

  config = mkIf cfg.enable {
    # Disable legacy iptables firewall
    networking.firewall.enable = false;

    # Enable nftables
    networking.nftables = {
      enable = true;

      ruleset =
        let
          # Profile-specific ports
          profilePorts = {
            desktop = {
              tcp = [ 22 ] ++ cfg.allowedPorts.tcp;
              udp = [ 53 ] ++ cfg.allowedPorts.udp;
            };
            server = {
              tcp = [ 22 80 443 ] ++ cfg.allowedPorts.tcp;
              udp = [ 53 ] ++ cfg.allowedPorts.udp;
            };
            gaming = {
              tcp = [ 22 ] ++ cfg.allowedPorts.tcp;
              udp = [ 53 7777 27015 ] ++ cfg.allowedPorts.udp; # Common gaming ports
            };
            development = {
              tcp = [ 22 3000 8000 8080 8443 9000 ] ++ cfg.allowedPorts.tcp;
              udp = [ 53 ] ++ cfg.allowedPorts.udp;
            };
          };

          currentPorts = profilePorts.${cfg.profile};

          # Helper functions
          portList = ports: concatStringsSep ", " (map toString ports);

          # Logging rules
          logRule =
            if cfg.logging.enable then
              "log level ${cfg.logging.level} flags all limit rate ${cfg.logging.rateLimit}"
            else "";

          # Blacklist rules
          blacklistRules = concatStringsSep "\n        "
            (map (ip: "ip saddr ${ip} ${logRule} drop") cfg.blacklist);

          # Trusted network rules
          trustedRules = concatStringsSep "\n        "
            (map (net: "ip saddr ${net} accept") cfg.trustedNetworks);

        in
        ''
          # Clear all existing rules
          flush ruleset

          table inet filter {
            # Rate limiting sets
            set ratelimit_ssh {
              type ipv4_addr
              timeout 10m
              flags dynamic
            }

            set ratelimit_conn {
              type ipv4_addr . inet_service
              timeout 5m
              flags dynamic
            }

            # Port scanning detection
            set portscan_detect {
              type ipv4_addr
              timeout 24h
              flags dynamic
            }

            # Main input chain
            chain input {
              type filter hook input priority filter; policy drop;

              # Basic connection tracking
              ct state invalid ${logRule} drop
              ct state established,related accept

              # Loopback interface
              iifname "lo" accept

              # Blacklist
              ${optionalString (cfg.blacklist != []) blacklistRules}

              # Trusted networks
              ${optionalString (cfg.trustedNetworks != []) trustedRules}

              ${optionalString cfg.protection.enableDDoSProtection ''
              # DDoS protection
              # SYN flood protection
              tcp flags syn tcp option maxseg size 1-535 ${logRule} drop

              # Limit new connections per source
              ct state new add @ratelimit_conn { ip saddr . tcp dport } { 1 }
              ct state new @ratelimit_conn { ip saddr . tcp dport } > ${toString cfg.protection.maxConnections} ${logRule} drop
              ''}

              ${optionalString cfg.protection.enablePortScanning ''
              # Port scanning detection
              ct state new tcp flags syn tcp dport 1-1024 add @portscan_detect { ip saddr timeout 24h } { 1 }
              @portscan_detect { ip saddr } > 10 ${logRule} drop comment "Port scan detected"
              ''}

              ${optionalString cfg.protection.enableBruteForceProtection ''
              # SSH brute force protection
              tcp dport 22 ct state new add @ratelimit_ssh { ip saddr timeout 10m } { 1 }
              tcp dport 22 ct state new @ratelimit_ssh { ip saddr } > 5 ${logRule} drop
              ''}

              # ICMP (ping) with rate limiting
              icmp type echo-request limit rate 5/second accept
              icmpv6 type echo-request limit rate 5/second accept

              # Allow configured TCP ports
              ${optionalString (currentPorts.tcp != [])
                "tcp dport { ${portList currentPorts.tcp} } ct state new accept"}

              # Allow configured UDP ports
              ${optionalString (currentPorts.udp != [])
                "udp dport { ${portList currentPorts.udp} } accept"}

              # Custom input rules
              ${concatStringsSep "\n            " cfg.customRules.input}

              # Log and drop everything else
              ${logRule} drop
            }

            # Output chain (generally permissive but logged)
            chain output {
              type filter hook output priority filter; policy accept;

              # Custom output rules
              ${concatStringsSep "\n            " cfg.customRules.output}
            }

            # Forward chain (for routing/NAT)
            chain forward {
              type filter hook forward priority filter; policy drop;

              # Connection tracking
              ct state established,related accept

              # Custom forward rules
              ${concatStringsSep "\n            " cfg.customRules.forward}
            }

            ${optionalString cfg.protection.enableDDoSProtection ''
            # Additional DDoS protection chain
            chain ddos_protection {
              # Limit concurrent connections
              ct count over ${toString (cfg.protection.maxConnections * 2)} ${logRule} drop

              # Rate limit new connections
              ct state new limit rate 100/second burst 150 packets accept
              ${logRule} drop
            }
            ''}
          }

          ${optionalString cfg.logging.enable ''
          # Logging table for monitoring
          table inet logging {
            chain log_input {
              type filter hook input priority filter + 1;
              meta nfproto ipv4 meta l4proto tcp log prefix "NFT-INPUT-TCP: " level ${cfg.logging.level}
              meta nfproto ipv4 meta l4proto udp log prefix "NFT-INPUT-UDP: " level ${cfg.logging.level}
              meta nfproto ipv4 meta l4proto icmp log prefix "NFT-INPUT-ICMP: " level ${cfg.logging.level}
            }
          }
          ''}
        '';
    };

    # Firewall management tools
    environment.systemPackages = with pkgs; [
      nftables # nft command

      # Firewall status script
      (writeShellScriptBin "firewall-status" ''
        echo "🔥 Advanced Firewall Status"
        echo "=========================="
        echo "Profile: ${cfg.profile}"
        echo "Protection: DDoS=${boolToString cfg.protection.enableDDoSProtection}, BruteForce=${boolToString cfg.protection.enableBruteForceProtection}"
        echo ""
        echo "📊 Current Rules:"
        nft list ruleset
        echo ""
        echo "📈 Rate Limiting Sets:"
        nft list sets | grep -E "(ratelimit|portscan)"
        echo ""
        echo "🚫 Active Drops (last 100):"
        journalctl -n 100 | grep -E "(NFT-|nft)" | tail -10
      '')

      # Firewall management script
      (writeShellScriptBin "firewall-manage" ''
        case "$1" in
          block)
            echo "Blocking IP: $2"
            nft add element inet filter blacklist { $2 }
            ;;
          unblock)
            echo "Unblocking IP: $2"
            nft delete element inet filter blacklist { $2 }
            ;;
          stats)
            firewall-status
            ;;
          reload)
            echo "Reloading firewall rules..."
            systemctl reload nftables
            ;;
          *)
            echo "Usage: firewall-manage {block|unblock|stats|reload} [IP]"
            ;;
        esac
      '')
    ];

    # System integration
    systemd.services.nftables-monitor = mkIf cfg.logging.enable {
      description = "Monitor nftables events";
      wantedBy = [ "multi-user.target" ];
      after = [ "nftables.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/journalctl -f -u nftables.service";
        Restart = "always";
        RestartSec = "10s";
      };
    };

    # Ensure proper ordering
    systemd.services.nftables = {
      before = [ "network-online.target" ];
      wants = [ "network-pre.target" ];
      after = [ "network-pre.target" ];
    };
  };

  # Usage examples in comments:
  /*
    # Example configuration:
    modules.security.firewall = {
    enable = true;
    profile = "server";

    protection = {
      enableDDoSProtection = true;
      enableBruteForceProtection = true;
      maxConnections = 25;
    };

    allowedPorts = {
      tcp = [ 8080 9000 ];  # Custom application ports
      udp = [ 51820 ];      # WireGuard
    };

    trustedNetworks = [
      "10.0.0.0/8"
      "192.168.0.0/16"
    ];

    customRules.input = [
      "tcp dport 8443 ip saddr 10.0.0.0/8 accept"  # Internal HTTPS
    ];
    };
  */
}
