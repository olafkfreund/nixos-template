# Changelog

All notable changes to this NixOS configuration template will be documented in this file.

## [Unreleased]

### Added

- **Deployment Factory Architecture** - Unified deployment image generation system
  - Centralized configuration in `lib/deployment-images.nix`
  - Reduced code duplication by ~400 lines
  - Consistent security and optimization across all deployment targets
  - New lightweight `development-minimal` image for resource-constrained environments
  - Docker VM builder image for cross-platform NixOS VM creation

- **Windows VM Builder** - Docker-based NixOS VM builder for Windows users
  - Pre-built VM images available via GitHub releases
  - 5 specialized templates: Desktop, Server, Gaming, Minimal, Development
  - Support for VirtualBox, Hyper-V, VMware, and QEMU formats
  - Comprehensive Windows user documentation
  - Automated GitHub Actions build pipeline
  - No local Nix installation required for Windows users

### Changed

- **Major Architecture Refactor**: Profile-based system eliminating massive code duplication
  - Flake.nix reduced from 1057 to 496 lines (53% reduction)
  - Host configurations reduced by 50-80% through profile system
  - Darwin configuration generator for multi-architecture support
  - Deployment images factory pattern replacing repetitive configurations

- **NixOS 25.05+ Compatibility**: Fixed all deprecation warnings and modernized
  configurations
  - Updated `isoImage.isoName` to `image.fileName` in macOS ISOs
  - Resolved user password precedence conflicts
  - Fixed option conflicts in deployment images
  - Removed deprecated `environment.noXlibs` option

- **Disk Space Optimizations**: Aggressive space-saving measures for deployment
  images
  - Development images optimized with aggressive garbage collection
  - Documentation disabled in deployment images to reduce size
  - Minimal journaling configuration (50-100MB limits)
  - Automatic Nix store optimization enabled

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

**Note**: This template provides cutting-edge NixOS features while maintaining stability and
security. All changes are validated through comprehensive CI/CD testing.

For detailed information about any feature, see the corresponding documentation in the `docs/` directory.
