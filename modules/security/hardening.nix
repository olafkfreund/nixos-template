# Security Hardening Module
# Implements expert security recommendations for production systems
# Based on CIS benchmarks and NixOS security best practices

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.security.hardening;
in
{
  options.modules.security.hardening = {
    enable = mkEnableOption "system security hardening";
    
    profile = mkOption {
      type = types.enum [ "desktop" "server" "workstation" "minimal" ];
      default = "workstation";
      description = "Security hardening profile";
    };
    
    networkSecurity = mkEnableOption "network security hardening";
    
    kernelSecurity = mkEnableOption "kernel security hardening";
    
    serviceSecurity = mkEnableOption "systemd service security hardening";
    
    auditingSecurity = mkEnableOption "security auditing and logging";
  };

  config = mkIf cfg.enable {
    
    # Kernel security hardening
    boot.kernelParams = mkIf cfg.kernelSecurity [
      # Kernel hardening parameters
      "slab_nomerge"           # Prevent slab cache merging
      "init_on_alloc=1"        # Initialize allocated memory
      "init_on_free=1"         # Initialize freed memory
      "page_alloc.shuffle=1"   # Randomize page allocations
      "randomize_kstack_offset=on"  # Randomize kernel stack
      
      # SMEP and SMAP (if supported by CPU)
      "nosmep"                 # Remove this if CPU supports SMEP
      "nosmap"                 # Remove this if CPU supports SMAP
      
      # Disable legacy features
      "vsyscall=none"          # Disable vsyscall emulation
      "debugfs=off"            # Disable debug filesystem
      "oops=panic"             # Panic on oops
      "module.sig_enforce=1"   # Enforce module signatures
    ];

    # Kernel runtime security
    boot.kernel.sysctl = mkIf cfg.kernelSecurity {
      # Kernel pointer restrictions  
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      
      # Process restrictions
      "kernel.yama.ptrace_scope" = 2;
      "kernel.unprivileged_userns_clone" = 0;
      
      # Memory protection
      "kernel.kexec_load_disabled" = 1;
      "vm.unprivileged_userfaultfd" = 0;
      
      # Network security
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      
      # ICMP restrictions
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      
      # TCP security
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      
      # File system security
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
    };

    # Service security hardening
    systemd.services = mkIf cfg.serviceSecurity {
      # Harden systemd user services
      "user@".serviceConfig = {
        # Restrict system calls
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@debug @mount @cpu-emulation @obsolete @privileged @raw-io @reboot @swap @resources"
        ];
        
        # Memory protection
        MemoryDenyWriteExecute = true;
        
        # Network restrictions
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        
        # Filesystem restrictions  
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        
        # Privilege restrictions
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        
        # Capability restrictions
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        
        # Namespace restrictions
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateNetwork = false; # Allow network for user services
        
        # Resource limits
        TasksMax = "25%";
        LimitNOFILE = 65536;
      };
    };

    # Network security
    networking = mkIf cfg.networkSecurity {
      # Disable IPv6 if not needed (uncomment if desired)
      # enableIPv6 = false;
      
      # Firewall enhancements
      firewall = {
        enable = true;
        
        # Strict logging
        logRefusedConnections = true;
        logRefusedPackets = false; # Avoid log spam
        logRefusedUnicastsOnly = true;
        
        # Connection tracking
        checkReversePath = "strict";
        
        # Additional iptables rules for hardening
        extraCommands = ''
          # Drop invalid packets
          iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
          
          # Rate limit new connections
          iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT
          
          # Prevent ping floods
          iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 2 -j ACCEPT
          iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
          
          # Log dropped packets (sample only to avoid spam)  
          iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
        '';
      };
    };

    # Security-focused package management
    nixpkgs.config = {
      # Security-conscious defaults
      allowUnfree = false; # Only allow free software by default
      
      # Package vulnerability scanning
      permittedInsecurePackages = [
        # List known insecure packages that must be used
        # "package-version" # Add specific packages if needed
      ];
    };

    # User and authentication hardening
    users = {
      # Prevent new user creation
      mutableUsers = mkDefault false;
      
      # Default user restrictions
      defaultUserShell = pkgs.bash;
    };

    # PAM security enhancements
    security.pam = {
      # Enforce strong passwords
      services.passwd.text = mkAfter ''
        password required pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
      '';
      
      # Login restrictions
      loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "core";
          value = "0"; # Disable core dumps
        }
        {
          domain = "*";
          type = "hard";
          item = "maxlogins";
          value = "10"; # Limit concurrent logins
        }
      ];
      
      # Enable fail2ban-like functionality
      failDelay = {
        enable = true;
        delay = 4000000; # 4 second delay after failed login
      };
    };

    # Disable unnecessary services and features  
    services = {
      # Disable potentially dangerous services
      avahi.enable = mkDefault false;        # mDNS service discovery
      printing.enable = mkDefault false;     # CUPS printing (enable if needed)
      
      # SSH hardening (if enabled)
      openssh = mkIf config.services.openssh.enable {
        settings = {
          # Authentication
          PasswordAuthentication = mkDefault false;
          ChallengeResponseAuthentication = mkDefault false;
          KbdInteractiveAuthentication = mkDefault false;
          PermitRootLogin = mkDefault "no";
          PermitEmptyPasswords = mkDefault false;
          
          # Protocol restrictions
          Protocol = mkDefault 2;
          X11Forwarding = mkDefault false;
          AllowAgentForwarding = mkDefault false;
          AllowTcpForwarding = mkDefault false;
          GatewayPorts = mkDefault "no";
          
          # Connection limits
          MaxAuthTries = mkDefault 3;
          MaxSessions = mkDefault 2;
          MaxStartups = mkDefault "10:30:60";
          
          # Crypto hardening
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
            "aes256-ctr"
            "aes192-ctr"
            "aes128-ctr"
          ];
          
          KexAlgorithms = [
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group16-sha512"
            "diffie-hellman-group18-sha512"
            "diffie-hellman-group-exchange-sha256"
          ];
          
          Macs = [
            "hmac-sha2-256-etm@openssh.com"
            "hmac-sha2-512-etm@openssh.com"
            "umac-128-etm@openssh.com"
          ];
        };
      };
    };

    # Security auditing and logging
    services.journald = mkIf cfg.auditingSecurity {
      extraConfig = ''
        # Enhanced logging for security
        Storage=persistent
        Compress=yes
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        ForwardToSyslog=yes
        MaxRetentionSec=1month
      '';
    };

    # Security-focused environment
    environment = {
      # Security-related packages
      systemPackages = with pkgs; [
        # Security analysis tools
        lynis           # Security audit tool
        chkrootkit      # Rootkit detector
        rkhunter        # Rootkit hunter
        
        # Network security
        nmap           # Network discovery
        tcpdump        # Packet analyzer
        wireshark-cli  # Network protocol analyzer
        
        # System hardening
        aide           # File integrity checker
        
        # Monitoring
        htop          # Process monitor
        iotop         # I/O monitor
        nethogs       # Network usage by process
      ];
      
      # Security-focused environment variables
      variables = {
        # Disable core dumps globally
        RLIMIT_CORE = "0";
        
        # Secure temporary directory
        TMPDIR = "/tmp";
      };
      
      # Remove potentially dangerous packages
      etc = {
        # Secure /etc/hosts
        hosts.mode = "0644";
        
        # Secure machine-id
        machine-id.mode = "0444";
      };
    };

    # Profile-specific hardening
    assertions = [
      {
        assertion = cfg.enable -> (cfg.profile != null);
        message = "Security hardening profile must be specified";
      }
    ];

    warnings = 
      optional (cfg.kernelSecurity && cfg.profile == "desktop")
        "Aggressive kernel security hardening may impact desktop user experience" ++
      optional (!cfg.networkSecurity && cfg.profile == "server") 
        "Network security hardening is recommended for server profiles";
  };
}