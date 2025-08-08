# Advanced NixOS Features

This document describes the expert-level features implemented in this NixOS template, designed for production-grade deployments and advanced users.

## Overview

The template now includes several advanced modules that provide enterprise-grade functionality:

- **Advanced Hardware Detection** - Automatic hardware profiling and optimization
- **Performance Monitoring** - Comprehensive system monitoring with Prometheus and Grafana
- **Enhanced Nix Optimization** - Advanced Nix store management and build optimization
- **Secrets Management** - SOPS-nix integration for secure configuration management
- **Comprehensive Testing** - VM-based integration testing and validation
- **Module Template** - Production-ready module development patterns

## Features

### 🔍 Hardware Detection (`modules.hardware.detection`)

Automatically detects and optimizes for your hardware configuration:

```nix
modules.hardware.detection = {
  enable = true;
  autoOptimize = true;  # Apply hardware-specific optimizations
  profile = null;       # Auto-detect: "minimal", "balanced", "high-performance"
  
  reporting = {
    enable = true;
    logLevel = "info";
  };
};
```

**Detects:**
- CPU vendor (Intel/AMD/ARM) and features (AVX, AES, etc.)
- Memory configuration and capacity
- Storage type (NVMe/SSD/HDD)
- GPU vendors (NVIDIA/AMD/Intel)
- Virtualization environment (QEMU, VMware, WSL, etc.)

**Optimizes:**
- CPU governors and kernel parameters
- Memory management settings
- I/O schedulers for storage type
- Virtualization-specific settings
- Graphics drivers and acceleration

### 📊 Performance Monitoring (`modules.services.monitoring`)

Enterprise-grade monitoring with Prometheus ecosystem:

```nix
modules.services.monitoring = {
  enable = true;
  
  prometheus = {
    enable = true;
    retention = "30d";
    alerting.enable = true;
  };
  
  exporters = {
    node.enable = true;      # System metrics
    systemd.enable = true;   # Service metrics
    process.enable = true;   # Process metrics
    blackbox.enable = true;  # Network probes
  };
  
  grafana = {
    enable = true;
    port = 3000;
  };
  
  systemHealth = {
    enable = true;
    checks = [
      "disk-space"
      "memory-usage"
      "cpu-temperature"
      "service-status"
      "network-connectivity"
    ];
  };
};
```

**Includes:**
- Prometheus server with alerting rules
- Grafana dashboards
- Multiple exporters (node, systemd, process, blackbox)
- System health checks
- Log aggregation with Loki (optional)
- Notification system (webhook/email)

### ⚡ Nix Optimization (`modules.core.nixOptimization`)

Advanced Nix store and build optimization:

```nix
modules.core.nixOptimization = {
  enable = true;
  
  tmpfs = {
    enable = true;
    size = "50%";  # Use 50% of RAM for /tmp
  };
  
  store = {
    autoOptimise = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
  
  performance = {
    maxJobs = "auto";
    cores = 0;  # Use all cores
    keepOutputs = true;
    keepDerivations = true;
    useCgroups = true;
  };
};
```

**Features:**
- Automatic store optimization and garbage collection
- tmpfs for `/tmp` with configurable size
- Advanced build performance tuning
- Experimental features management
- Resource limits for build isolation

### 🔐 Secrets Management (SOPS-nix Integration)

Secure configuration management with age encryption:

```nix
# In your configuration
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";
  
  secrets = {
    "database/password" = {
      owner = "postgres";
      group = "postgres";
    };
    "api/secret-key" = {
      owner = "webapp";
      mode = "0400";
    };
  };
};
```

### 🧪 Comprehensive Testing

VM-based integration testing with multiple test scenarios:

```bash
# Run all tests
nix flake check

# Run specific VM tests
nix build .#checks.x86_64-linux.vm-test-desktop
nix build .#checks.x86_64-linux.vm-test-server

# Configuration validation
nix build .#checks.x86_64-linux.config-syntax-check
nix build .#checks.x86_64-linux.security-check
```

**Test Categories:**
- VM integration tests (desktop/server)
- Configuration syntax validation
- Module dependency checking
- Security validation
- Performance benchmarking

### 📝 Advanced Module Template

Production-ready module development pattern with comprehensive validation:

```nix
modules.template = {
  enable = true;
  
  services = {
    web-api = {
      name = "web-api";
      port = 8080;
      enable = true;
    };
  };
  
  networking = {
    allowedIPs = [ "127.0.0.1" "192.168.1.0/24" ];
  };
  
  resources = {
    memory = "2G";
    cpu = "50%";
  };
  
  features = {
    metrics = true;
    healthCheck = true;
  };
};
```

**Features:**
- Comprehensive input validation with assertions
- Security hardening by default
- Resource limits and monitoring
- Health checks and metrics
- Structured logging and rotation

## Flake Enhancements

### Advanced Caching

The flake now includes optimized caching configuration:

```nix
nixConfig = {
  extra-substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://devenv.cachix.org"
  ];
  max-jobs = "auto";
  cores = 0;
  auto-optimise-store = true;
  experimental-features = [
    "nix-command"
    "flakes"
    "ca-derivations"
    "recursive-nix"
  ];
};
```

### Testing Infrastructure

Comprehensive test suite with multiple validation levels:

- **VM Tests**: Full system testing in isolated VMs
- **Syntax Validation**: Configuration parsing and validation
- **Security Checks**: Vulnerability scanning and best practices
- **Performance Tests**: Resource usage and optimization validation

## Usage Examples

### Basic Setup

Enable core optimizations in any configuration:

```nix
{
  imports = [ ./path/to/template ];
  
  modules = {
    core.nixOptimization.enable = true;
    hardware.detection.enable = true;
  };
}
```

### Production Server

Full monitoring and optimization for production:

```nix
{
  modules = {
    core.nixOptimization.enable = true;
    hardware.detection.enable = true;
    services.monitoring = {
      enable = true;
      grafana.enable = true;
      systemHealth.enable = true;
    };
  };
}
```

### Development Workstation

High-performance development environment:

```nix
{
  modules = {
    core.nixOptimization = {
      enable = true;
      performance.maxJobs = "auto";
      store.gc.dates = "daily";
    };
    
    hardware.detection = {
      enable = true;
      profile = "high-performance";
    };
    
    services.monitoring.enable = true;
  };
}
```

## Performance Profiles

The system automatically detects and applies performance profiles:

### High Performance
- **Criteria**: ≥8 cores, ≥32GB RAM, NVMe storage
- **Optimizations**: Performance CPU governor, aggressive caching, parallel builds
- **Use Cases**: Development workstations, build servers

### Balanced  
- **Criteria**: ≥4 cores, ≥8GB RAM, SSD storage
- **Optimizations**: Ondemand governor, balanced cache settings
- **Use Cases**: General workstations, small servers

### Resource Constrained
- **Criteria**: <4GB RAM or slow storage
- **Optimizations**: Conservative settings, reduced services
- **Use Cases**: VMs, embedded systems, older hardware

### Minimal
- **Criteria**: <2GB RAM
- **Optimizations**: Aggressive memory management, minimal services
- **Use Cases**: Containers, IoT devices

## Best Practices

### Security
- Enable AppArmor and fail2ban for enhanced security
- Use SOPS for secrets management
- Regular security updates through automated testing
- Network segmentation and firewall rules

### Performance
- Enable hardware detection for automatic optimization
- Use appropriate performance profiles
- Monitor system resources with built-in monitoring
- Regular garbage collection and store optimization

### Reliability
- Comprehensive testing before deployment
- Health monitoring and alerting
- Backup strategies for critical data
- Rollback capabilities with NixOS generations

### Development
- Use the module template for new modules
- Follow validation and testing patterns
- Document configuration decisions
- Version control all configuration changes

## Troubleshooting

### Common Issues

**Hardware Detection Not Working**
```bash
# Check detection service
journalctl -u hardware-detection

# Manual detection
nix-shell -p dmidecode lshw --run "lshw -short"
```

**Monitoring Services Failing**
```bash
# Check Prometheus
systemctl status prometheus
journalctl -u prometheus

# Check exporters
systemctl status prometheus-node-exporter
curl localhost:9100/metrics
```

**Build Performance Issues**
```bash
# Check Nix settings
nix show-config | grep -E "(max-jobs|cores)"

# Monitor build resources
htop # During builds
```

### Debug Mode

Enable debug logging for detailed information:

```nix
modules = {
  hardware.detection.reporting.logLevel = "debug";
  services.monitoring.prometheus.extraFlags = [ "--log.level=debug" ];
};
```

## Migration Guide

### From Basic Template

1. Update your flake inputs to include sops-nix
2. Import new modules in your configuration
3. Enable desired features gradually
4. Test in VM before deploying to production

### From Existing NixOS

1. Backup current configuration
2. Import template modules
3. Migrate existing settings to new module structure
4. Test thoroughly in development environment
5. Deploy with rollback capability

## Contributing

When adding new features:

1. Follow the module template pattern
2. Include comprehensive validation
3. Add appropriate tests
4. Document configuration options
5. Update this documentation

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review module documentation
3. Test in isolated VM environment
4. Create detailed issue reports with system information

---

*This template represents production-grade NixOS patterns and should be thoroughly tested before production deployment.*