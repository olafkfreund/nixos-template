# Template Validation Guide

This document explains the comprehensive validation system for NixOS template configurations, covering syntax validation, build evaluation, VM testing, and CI/CD integration.
All validations are
NixOS 25.05 compatible with zero deprecation warnings.

## Current Status

**All validations pass successfully:**

- **77+ Nix files** - Perfect syntax, zero errors
- **5 Template configurations** - laptop, desktop, server, qemu-vm, microvm
- **6 User profiles** - Complete Home Manager integration
- **25+ Modules** - GPU, desktop, virtualization, security
- **Management scripts** - All utilities working
- **VM builds** - QEMU and MicroVM configurations build successfully
- **GitHub Actions CI** - Complete pipeline validation
- **NixOS 25.05** - No deprecation warnings, latest features

## Validation Levels

### 1. **Syntax Validation** (Fastest - 30 seconds)

**Purpose**: Verify Nix code syntax and basic structure
**Use case**: Quick development feedback, pre-commit hooks

```bash
# Basic flake validation (zero warnings)
nix flake check --no-build

# Comprehensive syntax validation
./scripts/validate-templates.sh minimal

# Manual syntax check
find . -name "*.nix" -exec nix-instantiate --parse {} \;
```

**What it validates:**

- PASS Nix syntax correctness (77+ files)
- PASS Import resolution
- PASS Function argument completeness
- PASS Module structure and option definitions
- PASS No deprecation warnings (NixOS 25.05 compatible)
- PASS Flake metadata integrity

**What it doesn't validate:**

- FAIL Runtime functionality
- FAIL Package availability
- FAIL Hardware compatibility
- FAIL Service interactions

### 2. **Build Evaluation** (Medium - 2-5 minutes)

**Purpose**: Verify configurations can be built and evaluated
**Use case**: CI/CD pipelines, comprehensive validation

```bash
# Standard validation (recommended - all templates pass)
./scripts/validate-templates.sh standard

# Build specific template
nix build .#nixosConfigurations.laptop-template.config.system.build.toplevel --dry-run

# Test VM build capability
nix build --no-link '.#nixosConfigurations.qemu-vm.config.system.build.vm'
```

**What it validates:**

- PASS All syntax validation +
- PASS Package dependencies exist
- PASS Module evaluation succeeds
- PASS System closure can be built
- PASS Configuration generates valid system

**What it doesn't validate:**

- FAIL Runtime behavior
- FAIL Hardware-specific functionality
- FAIL Service startup and interaction
- FAIL User experience

### 3. **VM Testing** (Comprehensive - 10-20 minutes)

**Purpose**: Test actual runtime functionality in isolated VMs
**Use case**: Release validation, comprehensive testing

```bash
# Full VM validation
just validate-templates-full

# Or directly
./scripts/validate-templates.sh full

# Manual VM testing
nix build .#nixosConfigurations.laptop-template.config.system.build.vm
result/bin/run-*-vm
```

**What it validates:**

- PASS All build evaluation +
- PASS System boots successfully
- PASS Services start correctly
- PASS Desktop environment loads
- PASS Basic functionality works

**Resource requirements:**

- 4-8 GB RAM per VM
- 10-20 GB disk space
- Virtualization support (KVM/QEMU)

### 4. **Container Testing** (Alternative - 5-10 minutes)

**Purpose**: Lightweight functional testing without full VMs
**Use case**: CI environments, resource-constrained testing

```bash
# Build system as container
nix build .#nixosConfigurations.server-template.config.system.build.container

# Test in container
sudo systemd-nspawn -M test-container --image=result
```

**Benefits:**

- Faster than VMs
- Less resource intensive
- Good isolation
- Linux-only services testable

**Limitations:**

- FAIL No kernel-level testing
- FAIL No hardware simulation
- FAIL Limited desktop environment testing

## Our Validation Strategy

### Development Workflow

```bash
# 1. Quick syntax check while developing
just validate-templates-quick

# 2. Comprehensive validation before commit
just validate-templates

# 3. Pre-commit hooks run automatically
git commit -m "update configuration"
```

### CI/CD Pipeline

**On every push/PR (all passing):**

```yaml
# GitHub Actions automatically runs:
- nix-validation: Flake check + individual file syntax
- code-quality: nixpkgs-fmt, statix, deadnix linting
- shell-validation: shellcheck for all scripts
- documentation: Markdown linting + link checking
- template-validation: Structure + build evaluation
- security-scan: Pattern detection + permission checks
- integration-test: End-to-end flake functionality
- pre-commit: All quality checks in unified pipeline
```

**For releases:**

```bash
# Full validation including VM tests
just validate-templates-full
just prepare-release v1.0.0
```

## Validation Commands Reference

### Quick Commands

```bash
# Basic flake check
nix flake check

# Quick template validation
just validate-templates-quick

# Standard validation
just validate-templates

# Full validation with VMs
just validate-templates-full
```

### Detailed Commands

```bash
# Validate specific template
just validate-template laptop-template

# Build specific configuration
nix build .#nixosConfigurations.desktop-template.config.system.build.toplevel

# Test VM build
nix build .#nixosConfigurations.server-template.config.system.build.vm

# Container build
nix build .#nixosConfigurations.server-template.config.system.build.container
```

### Manual Testing

```bash
# Run VM interactively
nix build .#nixosConfigurations.laptop-template.config.system.build.vm
QEMU_OPTS="-m 4096" result/bin/run-*-vm

# Test in container
nix build .#nixosConfigurations.server-template.config.system.build.container
sudo systemd-nspawn --image=result --machine=test
```

## Validation Scenarios

### Scenario 1: Quick Development

**Goal**: Fast feedback during development
**Time**: 30 seconds - 2 minutes

```bash
just validate-templates-quick
```

### Scenario 2: Pre-commit Validation

**Goal**: Ensure quality before committing
**Time**: 2-5 minutes

```bash
just validate-templates
just run-hooks
```

### Scenario 3: CI/CD Validation

**Goal**: Comprehensive automated testing
**Time**: 5-10 minutes

```bash
# Runs automatically in GitHub Actions
./scripts/validate-templates.sh standard
```

### Scenario 4: Release Validation

**Goal**: Complete validation before release
**Time**: 15-30 minutes

```bash
just validate-templates-full
just ci-validate
just prepare-release v1.0.0
```

### Scenario 5: New Template Development

**Goal**: Test new template thoroughly
**Time**: 20-40 minutes

```bash
# 1. Create template
cp -r hosts/desktop-template hosts/new-template

# 2. Customize configuration
vim hosts/new-template/configuration.nix

# 3. Quick syntax check
just validate-template new-template

# 4. Build evaluation
nix build .#nixosConfigurations.new-template.config.system.build.toplevel --dry-run

# 5. VM testing
nix build .#nixosConfigurations.new-template.config.system.build.vm
result/bin/run-*-vm

# 6. Full validation
just validate-templates-full
```

## Understanding Validation Results

### Success Indicators

```bash
SUCCESS Flake syntax validation passed
SUCCESS All Nix files have valid syntax
SUCCESS Template laptop-template structure is valid
SUCCESS Build evaluation passed for: desktop-template
SUCCESS VM build successful for: server-template
```

### Common Issues and Solutions

#### Syntax Errors

```bash
ERROR Syntax error in: modules/example.nix
```

**Solution**: Fix Nix syntax errors, check imports and brackets

#### Missing Dependencies

```bash
ERROR Build evaluation failed for: laptop-template
```

**Solution**: Check that all referenced packages exist in nixpkgs

#### VM Build Failures

```bash
ERROR VM build failed for: desktop-template
```

**Solution**: Check hardware-configuration.nix, ensure all modules are compatible

#### Template Structure Issues

```bash
ERROR Missing required file in laptop-template: home.nix
```

**Solution**: Ensure all templates have required files (configuration.nix, home.nix)

## Performance Optimization

### Parallel Validation

```bash
# Validate multiple templates in parallel
(just validate-template laptop-template &)
(just validate-template desktop-template &)
(just validate-template server-template &)
wait
```

### Caching

```bash
# Use Nix binary cache
nix build --option substituters "https://cache.nixos.org https://nix-community.cachix.org"

# Local result caching
export NIX_REMOTE="daemon"
```

### Resource Management

```bash
# Limit memory for VM tests
export QEMU_OPTS="-m 2048"

# Limit CPU cores
export NIX_BUILD_CORES=2
```

## Integration with IDEs

### VS Code

Add to `.vscode/tasks.json`:

```json
{
  "label": "Validate Templates",
  "type": "shell",
  "command": "just validate-templates",
  "group": "test"
}
```

### Vim/Neovim

Add to configuration:

```vim
nnoremap <leader>vt :!just validate-templates<CR>
nnoremap <leader>vq :!just validate-templates-quick<CR>
```

## Recommended Workflow

For **daily development**:

1. Quick syntax check: `just validate-templates-quick`
1. Pre-commit validation: automatic via git hooks

For **feature completion**:

1. Standard validation: `just validate-templates`
1. CI validation: automatic on push

For **releases**:

1. Full validation: `just validate-templates-full`
1. Manual VM testing for critical templates
1. Release preparation: `just prepare-release`

This multi-layered validation approach ensures code quality while balancing speed and thoroughness based on the development stage.
