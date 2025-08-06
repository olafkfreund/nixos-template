# GPU Configuration Guide

This NixOS template includes comprehensive GPU support for AMD, NVIDIA, and Intel graphics cards,
with different optimization profiles for desktop/gaming vs AI/compute workloads.

## Overview

The GPU configuration system automatically detects your hardware and provides optimized settings for different use cases:

- **Desktop/Gaming**: Optimized for graphics, gaming, and multimedia
- **AI/Compute**: Optimized for machine learning, CUDA/ROCm, and compute workloads
- **Server**: Headless compute optimizations for AI/ML servers

## Quick Start

### Desktop Configuration

For desktop systems, edit `hosts/your-hostname/configuration.nix`:

```nix
modules.hardware.gpu = {
  # Auto-detect and configure GPUs (recommended)
  autoDetect = true;
  profile = "desktop";  # or "gaming" for gaming-focused optimizations

  # The system will automatically enable the appropriate GPU module
  # based on detected hardware
};
```

### Server Configuration

For AI/compute servers, edit `hosts/your-hostname/configuration.nix`:

```nix
modules.hardware.gpu = {
  autoDetect = true;
  profile = "ai-compute";  # or "server-compute"

  # Manual override example for NVIDIA AI server:
  nvidia = {
    enable = true;
    compute = {
      cuda = true;
      cudnn = true;
      containers = true;  # Docker/Podman NVIDIA support
    };
  };
};
```

## Manual Configuration

### AMD GPU Configuration

For AMD graphics cards (Radeon RX, Vega, RDNA series):

```nix
modules.hardware.gpu = {
  profile = "desktop";  # or "ai-compute"

  amd = {
    enable = true;
    model = "auto";  # auto, rdna3, rdna2, rdna1, vega, polaris

    # Gaming/Desktop features
    gaming = {
      enable = true;
      vulkan = true;      # Vulkan API support
      opengl = true;      # OpenGL optimizations
    };

    # AI/Compute features (for server profile)
    compute = {
      enable = true;      # Enable for AI workloads
      rocm = true;        # ROCm platform
      openCL = true;      # OpenCL support
      hip = true;         # HIP runtime
    };

    powerManagement = {
      enable = true;
      profile = "auto";   # auto, low, high, manual
    };
  };
};
```

**AMD ROCm Support**: AMD's ROCm platform provides CUDA-like functionality for AI/ML workloads on AMD GPUs.

### NVIDIA GPU Configuration

For NVIDIA graphics cards (GeForce, RTX, Quadro, Tesla):

```nix
modules.hardware.gpu = {
  profile = "desktop";  # or "ai-compute"

  nvidia = {
    enable = true;
    driver = "stable";    # stable, beta, production, open, legacy_470

    hardware = {
      model = "auto";     # auto, rtx40, rtx30, rtx20, gtx16, gtx10
      powerLimit = null;  # Set power limit in watts (e.g., 300)
    };

    # Gaming/Desktop features
    gaming = {
      enable = true;
      gsync = true;       # G-SYNC support
      rtx = true;         # RTX features (ray tracing, DLSS)
      nvenc = true;       # Hardware video encoding

      # Laptop hybrid graphics (PRIME)
      prime = {
        enable = true;    # Enable for laptops with Intel + NVIDIA
        offload = true;   # Offload mode (battery friendly)
        sync = false;     # Sync mode (always use NVIDIA)
      };
    };

    # AI/Compute features
    compute = {
      enable = true;      # Enable for AI workloads
      cuda = true;        # CUDA toolkit
      cudnn = true;       # cuDNN deep learning library
      tensorrt = true;    # TensorRT inference optimization
      containers = true;  # NVIDIA container runtime
      mig = false;        # Multi-Instance GPU (A100, H100)
    };

    # Professional features
    professional = {
      enable = true;      # Professional optimizations
      nvv4l2 = true;      # Video4Linux2 support
    };
  };
};
```

**NVIDIA Container Support**: Automatically configures Docker/Podman to use NVIDIA GPUs in containers.

### Intel GPU Configuration

For Intel integrated graphics (UHD, Iris, Arc):

```nix
modules.hardware.gpu = {
  profile = "desktop";

  intel = {
    enable = true;
    generation = "auto";  # auto, arc, xe, iris-xe, iris-plus, uhd, hd

    # Desktop features
    desktop = {
      enable = true;
      vaapi = true;       # Hardware video acceleration
      vulkan = true;      # Vulkan API support
      opengl = true;      # OpenGL optimizations
    };

    # Compute features (Intel Arc/Xe)
    compute = {
      enable = true;      # For Intel Arc GPUs
      oneapi = true;      # Intel OneAPI toolkit
      opencl = true;      # OpenCL support
      level_zero = true;  # Level Zero API
    };

    powerManagement = {
      enable = true;
      rc6 = true;         # RC6 power states
      fbc = true;         # Frame Buffer Compression
      psr = true;         # Panel Self Refresh
    };
  };
};
```

**Intel Arc Support**: Intel's discrete Arc GPUs support AI/compute workloads through OneAPI.

## Multi-GPU Configuration

For systems with multiple GPUs:

```nix
modules.hardware.gpu = {
  profile = "gaming";  # or "ai-compute"

  # Enable multiple GPU types
  amd.enable = true;
  nvidia.enable = true;

  # Multi-GPU configuration
  multiGpu = {
    enable = true;
    primary = "nvidia";  # Which GPU handles display: amd, nvidia, intel
  };
};
```

## Profile Optimizations

### Desktop Profile

- Gaming optimizations (high performance, low latency)
- Multimedia acceleration (video decode/encode)
- Display optimizations (G-SYNC, FreeSync)
- User-friendly tools and monitoring

### Gaming Profile

- Maximum performance settings
- Gaming-specific optimizations (GameMode, MangoHud)
- Low-latency configurations
- Overclocking support

### AI-Compute Profile

- CUDA/ROCm/OneAPI support
- Machine learning libraries
- Container runtime support
- Compute-optimized power management
- Development tools and profilers

### Server-Compute Profile

- Headless optimizations
- Maximum compute throughput
- Container and orchestration support
- Monitoring and management tools
- Power efficiency optimizations

## Common Use Cases

### Gaming Desktop with NVIDIA RTX

```nix
modules.hardware.gpu = {
  profile = "gaming";
  nvidia = {
    enable = true;
    gaming = {
      enable = true;
      gsync = true;
      rtx = true;
    };
  };
};
```

### AI Development Server with AMD GPU

```nix
modules.hardware.gpu = {
  profile = "ai-compute";
  amd = {
    enable = true;
    compute = {
      enable = true;
      rocm = true;
      hip = true;
    };
  };
};
```

### Laptop with Intel + NVIDIA Hybrid Graphics

```nix
modules.hardware.gpu = {
  profile = "desktop";
  intel.enable = true;
  nvidia = {
    enable = true;
    gaming.prime = {
      enable = true;
      offload = true;  # Battery-friendly
    };
  };
  multiGpu = {
    enable = true;
    primary = "intel";  # Intel for display, NVIDIA for compute
  };
};
```

### Multi-GPU AI Server

```nix
modules.hardware.gpu = {
  profile = "server-compute";
  nvidia = {
    enable = true;
    compute = {
      enable = true;
      cuda = true;
      cudnn = true;
      containers = true;
      mig = true;  # For A100/H100 GPUs
    };
    hardware.powerLimit = 400;  # Power limit per GPU
  };
  multiGpu.enable = true;
};
```

## Hardware Detection

The system automatically detects GPUs using:

- PCI device enumeration
- Driver availability checks
- Hardware capability detection

Detection results are logged and available at `/run/gpu-info/detected`.

## Troubleshooting

### Check GPU Detection

```bash
# View detected GPUs
cat /run/gpu-info/detected

# Check PCI devices
lspci | grep -i vga
lspci | grep -i 3d

# Check loaded drivers
lsmod | grep -E "(nvidia|amdgpu|i915)"
```

### NVIDIA Issues

```bash
# Check NVIDIA driver
nvidia-smi

# Check CUDA
nvcc --version

# Container support
docker run --rm --gpus all nvidia/cuda:11.0-base-ubuntu20.04 nvidia-smi
```

### AMD Issues

```bash
# Check AMD GPU
radeontop -d -

# Check ROCm
rocm-smi

# Check OpenCL
clinfo
```

### Intel Issues

```bash
# Check Intel GPU
intel_gpu_top

# Check VA-API
vainfo
```

## Performance Tuning

### Gaming Optimizations

- G-SYNC/FreeSync enabled automatically
- Game mode optimizations
- Shader caching configured
- Low-latency settings

### AI/Compute Optimizations

- Memory management tuned for large datasets
- Compute-focused power profiles
- Container runtime optimizations
- Development tool integration

### Power Management

- Automatic GPU power states
- Temperature monitoring
- Configurable power limits
- Thermal throttling protection

## Container Support

NVIDIA Container Runtime is automatically configured for:

- Docker with `--gpus all` flag
- Podman with NVIDIA support
- Kubernetes GPU scheduling
- AI/ML container workflows

Example usage:

```bash
# Docker with GPU
docker run --rm --gpus all tensorflow/tensorflow:latest-gpu python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"

# Podman with GPU
podman run --rm --device nvidia.com/gpu=all pytorch/pytorch:latest python -c "import torch; print(torch.cuda.is_available())"
```

## Monitoring Tools

Automatically installed based on GPU type:

- **nvtop**: Universal GPU monitoring (NVIDIA, AMD, Intel)
- **nvidia-smi**: NVIDIA management
- **radeontop**: AMD monitoring
- **intel_gpu_top**: Intel monitoring
- **MangoHud**: Gaming overlay

## Getting Help

1. Check system logs: `journalctl -u gpu-detection`
2. Verify hardware detection: `lspci | grep -i gpu`
3. Test GPU functionality with appropriate tools
4. Review module configuration in your host config
5. Check NixOS hardware database for your specific GPU
