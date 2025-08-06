{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization.podman;
in
{
  options.modules.virtualization.podman = {
    enable = mkEnableOption "Podman containerization with rootless support";
    
    dockerCompat = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker compatibility layer";
    };
    
    rootless = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable rootless podman for regular users";
      };
      
      setSocketVariable = mkOption {
        type = types.bool;
        default = true;
        description = "Set DOCKER_HOST socket variable for rootless podman";
      };
    };
    
    networking = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable container networking";
      };
      
      defaultNetwork = mkOption {
        type = types.str;
        default = "podman";
        description = "Default network name for containers";
      };
      
      dns = mkOption {
        type = types.listOf types.str;
        default = [ "1.1.1.1" "8.8.8.8" ];
        description = "DNS servers for containers";
      };
    };
    
    storage = {
      driver = mkOption {
        type = types.str;
        default = "overlay";
        description = "Storage driver for containers";
      };
      
      runRoot = mkOption {
        type = types.str;
        default = "/run/containers/storage";
        description = "Directory for container runtime files";
      };
      
      graphRoot = mkOption {
        type = types.str;
        default = "/var/lib/containers/storage";
        description = "Directory for container storage";
      };
    };
    
    registries = {
      search = mkOption {
        type = types.listOf types.str;
        default = [
          "registry.fedoraproject.org"
          "registry.access.redhat.com"
          "docker.io"
          "quay.io"
        ];
        description = "Container registries to search for images";
      };
      
      insecure = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Insecure registries (HTTP instead of HTTPS)";
      };
      
      block = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Blocked registries";
      };
    };
    
    additionalTools = {
      buildah = mkOption {
        type = types.bool;
        default = true;
        description = "Install Buildah for building container images";
      };
      
      skopeo = mkOption {
        type = types.bool;
        default = true;
        description = "Install Skopeo for working with container images and repositories";
      };
      
      podman-compose = mkOption {
        type = types.bool;
        default = true;
        description = "Install podman-compose for Docker Compose compatibility";
      };
      
      podman-tui = mkOption {
        type = types.bool;
        default = true;
        description = "Install Podman TUI for terminal user interface";
      };
      
      dive = mkOption {
        type = types.bool;
        default = false;
        description = "Install dive for exploring container images";
      };
      
      ctop = mkOption {
        type = types.bool;
        default = false;
        description = "Install ctop for container monitoring";
      };
    };
    
    autoUpdate = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic container updates";
      };
      
      onCalendar = mkOption {
        type = types.str;
        default = "daily";
        description = "Systemd calendar expression for auto-updates";
      };
    };
    
    quadlet = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Quadlet for systemd integration";
      };
    };
    
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages for container development";
      example = literalExpression ''
        with pkgs; [
          distrobox
          toolbox
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable Podman
    virtualisation.podman = {
      enable = true;
      
      # Docker compatibility
      dockerCompat = cfg.dockerCompat;
      dockerSocket.enable = cfg.dockerCompat;
      
      # Default network settings
      defaultNetwork.settings = mkIf cfg.networking.enable {
        dns_enabled = true;
        driver = "bridge";
        name = cfg.networking.defaultNetwork;
      };
      
      # Rootless configuration
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    # Enable rootless podman
    virtualisation.containers = {
      enable = true;
      
      # Rootless configuration
      # Note: Users must be manually added to extraGroups in host configuration
      # to enable rootless access: extraGroups = [ "podman" ];
      
      # Container storage configuration
      storage.settings = {
        storage = {
          driver = cfg.storage.driver;
          runroot = cfg.storage.runRoot;
          graphroot = cfg.storage.graphRoot;
          
          options = {
            overlay = {
              mountopt = "nodev,metacopy=on";
            };
          };
        };
      };
      
      # Registry configuration
      registries = {
        search = cfg.registries.search;
        insecure = cfg.registries.insecure;
        block = cfg.registries.block;
      };
      
      # Policy configuration for image verification
      policy = {
        default = [{ type = "insecureAcceptAnything"; }];
        transports = {
          docker-daemon = {
            "" = [{ type = "insecureAcceptAnything"; }];
          };
        };
      };
    };

    # System packages for containers
    environment.systemPackages = with pkgs; [
      podman
      
      # Additional container tools
      (mkIf cfg.additionalTools.buildah buildah)
      (mkIf cfg.additionalTools.skopeo skopeo)
      (mkIf cfg.additionalTools.podman-compose podman-compose)
      (mkIf cfg.additionalTools.podman-tui podman-tui)
      (mkIf cfg.additionalTools.dive dive)
      (mkIf cfg.additionalTools.ctop ctop)
      
      # Container development tools
      conmon
      crun
      fuse-overlayfs
      slirp4netns
      
      # Extra packages specified by user
    ] ++ cfg.extraPackages;

    # User groups for container access
    users.groups.podman = {};
    
    # Note: Users need to be manually added to 'podman' group for rootless access
    # This avoids circular dependencies in the module system
    # Add users to the podman group manually in host configuration:

    # Systemd services
    systemd.services = {
      # Podman auto-update service
      podman-auto-update = mkIf cfg.autoUpdate.enable {
        description = "Podman auto-update service";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.podman}/bin/podman auto-update";
          ExecStartPost = "${pkgs.podman}/bin/podman image prune -f";
        };
      };
    };

    # Systemd timers
    systemd.timers = {
      podman-auto-update = mkIf cfg.autoUpdate.enable {
        description = "Podman auto-update timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.autoUpdate.onCalendar;
          Persistent = true;
        };
      };
    };

    # Quadlet support (systemd integration for containers)
    systemd.packages = mkIf cfg.quadlet.enable [ pkgs.podman ];

    # Environment variables for container tools
    environment.sessionVariables = mkMerge [
      {
        # Podman configuration
        CONTAINERS_CONF = "/etc/containers/containers.conf";
        CONTAINERS_STORAGE_CONF = "/etc/containers/storage.conf";
        CONTAINERS_REGISTRIES_CONF = "/etc/containers/registries.conf";
        CONTAINERS_POLICY_JSON = "/etc/containers/policy.json";
        
        # Buildah configuration
        BUILDAH_FORMAT = "docker";
        BUILDAH_ISOLATION = "chroot";
        
        # Default container runtime
        CONTAINER_RUNTIME = "podman";
      }
      
      # Docker socket compatibility for rootless
      (mkIf (cfg.rootless.enable && cfg.rootless.setSocketVariable) {
        DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock";
      })
    ];

    # Container configuration files
    environment.etc = {
      # Main containers configuration (use mkForce to override system default)
      "containers/containers.conf" = mkForce {
        text = ''
          [containers]
          # Default logging driver
          log_driver = "journald"
          
          # Network backend
          network_backend = "${if cfg.networking.enable then "netavark" else "cni"}"
          
          # Default capabilities
          default_capabilities = [
            "CHOWN",
            "DAC_OVERRIDE", 
            "FOWNER",
            "FSETID",
            "KILL",
            "NET_BIND_SERVICE",
            "SETFCAP",
            "SETGID",
            "SETPCAP",
            "SETUID",
            "SYS_CHROOT"
          ]
          
          # Security settings
          seccomp_profile = "/usr/share/containers/seccomp.json"
          apparmor_profile = "containers-default-0.46.0"
          
          # Resource limits
          pids_limit = 2048
          log_size_max = -1
          
          # DNS configuration
          ${optionalString cfg.networking.enable ''
          dns_servers = [${concatMapStringsSep ", " (dns: ''"${dns}"'') cfg.networking.dns}]
          ''}
          
          # Timezone handling
          tz = "local"
          
          # Umask for container files
          umask = "0022"
          
          [secrets]
          driver = "file"
          
          [machine]
          # Machine configuration for podman machine (if used)
          image = "registry.fedoraproject.org/fedora-coreos:stable"
          user = "core"
          
          [engine]
          # Container engine configuration
          cgroup_manager = "systemd"
          events_logger = "journald"
          runtime = "crun"
          
          # Image configuration
          image_default_transport = "docker://"
          
          # Network configuration
          network_cmd_path = "${pkgs.netavark}/bin/netavark"
          
          [network]
          # Default network configuration
          network_backend = "${if cfg.networking.enable then "netavark" else "cni"}"
          
          ${optionalString cfg.networking.enable ''
          default_network = "${cfg.networking.defaultNetwork}"
          default_subnet = "10.89.0.0/24"
          ''}
        '';
      };
      
      # Mounts configuration for better security
      "containers/mounts.conf" = {
        text = ''
          # Additional mount points for containers
          /usr/share/rhel/secrets:/run/secrets
        '';
      };
      
      # Seccomp profile for container security  
      "containers/seccomp.json" = mkForce {
        text = ''
          {
            "defaultAction": "SCMP_ACT_ERRNO",
            "archMap": [
              {
                "architecture": "SCMP_ARCH_X86_64",
                "subArchitectures": [
                  "SCMP_ARCH_X86",
                  "SCMP_ARCH_X32"
                ]
              }
            ],
            "syscalls": [
              {
                "names": [
                  "accept",
                  "accept4",
                  "access",
                  "adjtimex",
                  "alarm",
                  "bind",
                  "brk",
                  "capget",
                  "capset",
                  "chdir",
                  "chmod",
                  "chown",
                  "chown32",
                  "clock_getres",
                  "clock_gettime",
                  "clock_nanosleep",
                  "close",
                  "connect",
                  "copy_file_range",
                  "creat",
                  "dup",
                  "dup2",
                  "dup3",
                  "epoll_create",
                  "epoll_create1",
                  "epoll_ctl",
                  "epoll_pwait",
                  "epoll_wait",
                  "eventfd",
                  "eventfd2",
                  "execve",
                  "execveat",
                  "exit",
                  "exit_group",
                  "faccessat",
                  "fadvise64",
                  "fallocate",
                  "fanotify_mark",
                  "fchdir",
                  "fchmod",
                  "fchmodat",
                  "fchown",
                  "fchown32",
                  "fchownat",
                  "fcntl",
                  "fcntl64",
                  "fdatasync",
                  "fgetxattr",
                  "flistxattr",
                  "flock",
                  "fork",
                  "fremovexattr",
                  "fsetxattr",
                  "fstat",
                  "fstat64",
                  "fstatat64",
                  "fstatfs",
                  "fstatfs64",
                  "fsync",
                  "ftruncate",
                  "ftruncate64",
                  "futex",
                  "getcpu",
                  "getcwd",
                  "getdents",
                  "getdents64",
                  "getegid",
                  "getegid32",
                  "geteuid",
                  "geteuid32",
                  "getgid",
                  "getgid32",
                  "getgroups",
                  "getgroups32",
                  "getitimer",
                  "getpgid",
                  "getpgrp",
                  "getpid",
                  "getppid",
                  "getpriority",
                  "getrandom",
                  "getresgid",
                  "getresgid32",
                  "getresuid",
                  "getresuid32",
                  "getrlimit",
                  "get_robust_list",
                  "getrusage",
                  "getsid",
                  "getsockname",
                  "getsockopt",
                  "get_thread_area",
                  "gettid",
                  "gettimeofday",
                  "getuid",
                  "getuid32",
                  "getxattr",
                  "inotify_add_watch",
                  "inotify_init",
                  "inotify_init1",
                  "inotify_rm_watch",
                  "io_cancel",
                  "ioctl",
                  "io_destroy",
                  "io_getevents",
                  "ioprio_get",
                  "ioprio_set",
                  "io_setup",
                  "io_submit",
                  "ipc",
                  "kill",
                  "lchown",
                  "lchown32",
                  "lgetxattr",
                  "link",
                  "linkat",
                  "listen",
                  "listxattr",
                  "llistxattr",
                  "lremovexattr",
                  "lseek",
                  "lsetxattr",
                  "lstat",
                  "lstat64",
                  "madvise",
                  "memfd_create",
                  "mincore",
                  "mkdir",
                  "mkdirat",
                  "mknod",
                  "mknodat",
                  "mlock",
                  "mlock2",
                  "mlockall",
                  "mmap",
                  "mmap2",
                  "mprotect",
                  "mq_getsetattr",
                  "mq_notify",
                  "mq_open",
                  "mq_timedreceive",
                  "mq_timedsend",
                  "mq_unlink",
                  "mremap",
                  "msgctl",
                  "msgget",
                  "msgrcv",
                  "msgsnd",
                  "msync",
                  "munlock",
                  "munlockall",
                  "munmap",
                  "nanosleep",
                  "newfstatat",
                  "_newselect",
                  "open",
                  "openat",
                  "pause",
                  "pipe",
                  "pipe2",
                  "poll",
                  "ppoll",
                  "prctl",
                  "pread64",
                  "preadv",
                  "prlimit64",
                  "pselect6",
                  "ptrace",
                  "pwrite64",
                  "pwritev",
                  "read",
                  "readahead",
                  "readlink",
                  "readlinkat",
                  "readv",
                  "recv",
                  "recvfrom",
                  "recvmmsg",
                  "recvmsg",
                  "remap_file_pages",
                  "removexattr",
                  "rename",
                  "renameat",
                  "renameat2",
                  "restart_syscall",
                  "rmdir",
                  "rt_sigaction",
                  "rt_sigpending",
                  "rt_sigprocmask",
                  "rt_sigqueueinfo",
                  "rt_sigreturn",
                  "rt_sigsuspend",
                  "rt_sigtimedwait",
                  "rt_tgsigqueueinfo",
                  "sched_getaffinity",
                  "sched_getattr",
                  "sched_getparam",
                  "sched_get_priority_max",
                  "sched_get_priority_min",
                  "sched_getscheduler",
                  "sched_rr_get_interval",
                  "sched_setaffinity",
                  "sched_setattr",
                  "sched_setparam",
                  "sched_setscheduler",
                  "sched_yield",
                  "seccomp",
                  "select",
                  "semctl",
                  "semget",
                  "semop",
                  "semtimedop",
                  "send",
                  "sendfile",
                  "sendfile64",
                  "sendmmsg",
                  "sendmsg",
                  "sendto",
                  "setfsgid",
                  "setfsgid32",
                  "setfsuid",
                  "setfsuid32",
                  "setgid",
                  "setgid32",
                  "setgroups",
                  "setgroups32",
                  "setitimer",
                  "setpgid",
                  "setpriority",
                  "setregid",
                  "setregid32",
                  "setresgid",
                  "setresgid32",
                  "setresuid",
                  "setresuid32",
                  "setreuid",
                  "setreuid32",
                  "setrlimit",
                  "set_robust_list",
                  "setsid",
                  "setsockopt",
                  "set_thread_area",
                  "set_tid_address",
                  "setuid",
                  "setuid32",
                  "setxattr",
                  "shmat",
                  "shmctl",
                  "shmdt",
                  "shmget",
                  "shutdown",
                  "sigaltstack",
                  "signalfd",
                  "signalfd4",
                  "sigreturn",
                  "socket",
                  "socketcall",
                  "socketpair",
                  "splice",
                  "stat",
                  "stat64",
                  "statfs",
                  "statfs64",
                  "statx",
                  "symlink",
                  "symlinkat",
                  "sync",
                  "sync_file_range",
                  "syncfs",
                  "sysinfo",
                  "syslog",
                  "tee",
                  "tgkill",
                  "time",
                  "timer_create",
                  "timer_delete",
                  "timerfd_create",
                  "timerfd_gettime",
                  "timerfd_settime",
                  "timer_getoverrun",
                  "timer_gettime",
                  "timer_settime",
                  "times",
                  "tkill",
                  "truncate",
                  "truncate64",
                  "ugetrlimit",
                  "umask",
                  "uname",
                  "unlink",
                  "unlinkat",
                  "utime",
                  "utimensat",
                  "utimes",
                  "vfork",
                  "vmsplice",
                  "wait4",
                  "waitid",
                  "waitpid",
                  "write",
                  "writev"
                ],
                "action": "SCMP_ACT_ALLOW"
              }
            ]
          }
        '';
      };
    };

    # Kernel modules needed for containers
    boot.kernelModules = [ "overlay" "br_netfilter" ];

    # Sysctl settings for containers
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = mkDefault 1;
      "net.bridge.bridge-nf-call-ip6tables" = mkDefault 1;
      "net.ipv4.ip_forward" = mkDefault 1;
      "user.max_user_namespaces" = mkDefault 28633;
    };

    # Enable cgroups v2 for better resource management
    # Note: systemd.enableUnifiedCgroupHierarchy is deprecated - cgroups v2 is now default

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d /var/lib/containers 0755 root root -"
      "d /var/lib/containers/storage 0755 root root -"
      "d /run/containers 0755 root root -"
      "d /run/containers/storage 0755 root root -"
    ];

    # Security configuration
    security.unprivilegedUsernsClone = mkIf cfg.rootless.enable true;

    # Firewall rules for container networking
    networking.firewall = mkIf cfg.networking.enable {
      # Allow container-to-container communication
      trustedInterfaces = [ "podman+" "cni+" ];
    };

    # Additional networking configuration
    networking.networkmanager = mkIf config.networking.networkmanager.enable {
      unmanaged = [ "interface-name:veth*" "interface-name:podman*" "interface-name:cni*" ];
    };
  };
}