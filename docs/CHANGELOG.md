# Changelog

All notable changes to this NixOS configuration template will be documented in this file.

## [Unreleased]

### Added

- **Windows VM Builder** - Docker-based NixOS VM builder for Windows users
  - Pre-built VM images available via GitHub releases
  - 5 specialized templates: Desktop, Server, Gaming, Minimal, Development
  - Support for VirtualBox, Hyper-V, VMware, and QEMU formats
  - Comprehensive Windows user documentation
  - Automated GitHub Actions build pipeline
  - No local Nix installation required for Windows users

### Changed

- Updated README.md to include Windows VM builder section
- Enhanced project structure documentation with Docker components
- Added Windows-specific quick start instructions

### Documentation

- Added `docs/WINDOWS-HOWTO.md` - Complete step-by-step guide for Windows users
- Added `docs/WINDOWS-VM-BUILDER.md` - Technical Docker implementation details
- Added `docker/README.md` - Docker-specific documentation
- Updated main README with Windows VM builder features and commands

### Infrastructure

- Added GitHub Actions workflow for automated VM image builds
- Added Docker image publishing to GitHub Container Registry
- Added automated release creation with downloadable VM images
- Added comprehensive VM build matrix for all template/format combinations

## Previous Releases

### Security & Stability Improvements

- Fixed critical NOPASSWD sudo vulnerability in desktop template
- Standardized secrets management on agenix (age encryption)
- Implemented comprehensive security hardening module
- Enhanced hardware detection with robust fallbacks
- Applied performance optimizations with automatic hardware tuning

### Expert-Level Features

- Zero-configuration hardware optimization
- Professional security assessment and implementation
- Advanced monitoring and system identification
- Multi-platform deployment image generation
- Comprehensive Home Manager profile system

---

**Note**: This template provides cutting-edge NixOS features while maintaining stability and security. All changes are validated through comprehensive CI/CD testing.

For detailed information about any feature, see the corresponding documentation in the `docs/` directory.
