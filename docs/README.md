# Documentation Index

All extended documentation for the NixOS template lives here. The [main README](../README.md) covers the quick-start happy path; these files cover everything else.

---

## Getting Started

| File | Description |
|---|---|
| [SETUP.md](SETUP.md) | Detailed first-time setup walkthrough |
| [HOST-TEMPLATES.md](HOST-TEMPLATES.md) | All host types (desktop/server/laptop/VM/gaming) and flake.nix registration |
| [USER-TEMPLATES.md](USER-TEMPLATES.md) | Home Manager user profiles and customisation |
| [NON-NIXOS-USAGE.md](NON-NIXOS-USAGE.md) | Using the template on Windows or macOS without a native NixOS install |
| [FEATURES-OVERVIEW.md](FEATURES-OVERVIEW.md) | High-level summary of template features |

## Platforms

| File | Description |
|---|---|
| [WINDOWS-HOWTO.md](WINDOWS-HOWTO.md) | End-to-end guide for Windows users (WSL2 and Docker) |
| [WINDOWS-QUICK-REFERENCE.md](WINDOWS-QUICK-REFERENCE.md) | Quick command reference for Windows/WSL2 workflows |
| [WINDOWS-VM-BUILDER.md](WINDOWS-VM-BUILDER.md) | Docker-based NixOS VM builder for Windows |
| [WSL2-CONFIGURATION.md](WSL2-CONFIGURATION.md) | NixOS configuration inside WSL2 |
| [MACOS-NIXOS-GUIDE.md](MACOS-NIXOS-GUIDE.md) | Running NixOS VMs on macOS for testing |
| [NIX-DARWIN-GUIDE.md](NIX-DARWIN-GUIDE.md) | nix-darwin (native macOS management) reference |

## Hardware & GPU

| File | Description |
|---|---|
| [GPU-CONFIGURATION.md](GPU-CONFIGURATION.md) | GPU driver setup for AMD, NVIDIA, and Intel |
| [HARDWARE-AUTO-OPTIMIZATION.md](HARDWARE-AUTO-OPTIMIZATION.md) | Automatic hardware detection and tuning |
| [ZERO-CONFIGURATION.md](ZERO-CONFIGURATION.md) | How zero-config hardware optimisation works |
| [POWER-MANAGEMENT.md](POWER-MANAGEMENT.md) | Power profiles, TLP, and battery configuration |
| [SYSTEM-IDENTIFICATION.md](SYSTEM-IDENTIFICATION.md) | How the template identifies and classifies hardware |

## Advanced & Secrets

| File | Description |
|---|---|
| [AGENIX-SECRETS.md](AGENIX-SECRETS.md) | Age-encrypted secrets management with agenix |
| [DEPLOYMENT-IMAGES.md](DEPLOYMENT-IMAGES.md) | Generating cloud/VM images (AWS, Azure, GCE, VMware, etc.) |
| [ISO-CREATION.md](ISO-CREATION.md) | Building custom NixOS installer ISOs |
| [VM-SUPPORT.md](VM-SUPPORT.md) | VM guest optimisation and testing configurations |
| [DESKTOP-ENVIRONMENTS.md](DESKTOP-ENVIRONMENTS.md) | Desktop environment options and configuration |
| [ADVANCED-FEATURES.md](ADVANCED-FEATURES.md) | Overlays, custom packages, and advanced Nix patterns |

## CI/CD

| File | Description |
|---|---|
| [CI-CD.md](CI-CD.md) | GitHub Actions pipeline setup and configuration |

## Reference

| File | Description |
|---|---|
| [NIXOS-ANTI-PATTERNS.md](NIXOS-ANTI-PATTERNS.md) | Common NixOS mistakes and how to avoid them |
| [researched-antipatterns.md](researched-antipatterns.md) | Comprehensive Nix/NixOS anti-pattern research reference |
| [CODE-QUALITY.md](CODE-QUALITY.md) | Linting, formatting, and code quality tools (statix, deadnix, nixfmt) |
| [VALIDATION.md](VALIDATION.md) | Configuration validation workflow |
| [CHANGELOG.md](CHANGELOG.md) | Release history and notable changes |
