# Code Quality and Validation Guide

This NixOS template includes comprehensive code quality tools and validation processes to ensure clean,
secure, and maintainable configurations.

## Quick Start

```bash
# Enter development environment
nix develop

# Set up complete development environment (recommended for new users)
just dev-setup

# Run basic validation
just validate

# Run comprehensive quality checks
just quality
```

## Available Tools

### Core Validation Tools

| Tool                | Purpose                         | Command                |
| ------------------- | ------------------------------- | ---------------------- |
| **nixpkgs-fmt**     | Format Nix files                | `just fmt`             |
| **statix**          | Lint and analyze Nix code       | `just lint`            |
| **deadnix**         | Detect unused code              | `just dead-code-check` |
| **vulnix**          | Security vulnerability scanning | `just security-audit`  |
| **nix flake check** | Validate flake syntax and build | `just check`           |

### Development Utilities

| Tool           | Purpose                  | Usage                |
| -------------- | ------------------------ | -------------------- |
| **pre-commit** | Git hooks automation     | `just install-hooks` |
| **fd**         | Better file finding      | `fd pattern`         |
| **ripgrep**    | Better text searching    | `rg pattern`         |
| **bat**        | Better file viewing      | `bat file.nix`       |
| **eza**        | Better directory listing | `eza -la`            |
| **fzf**        | Fuzzy finding            | `history \| fzf`     |

## Validation Commands

### Basic Validation

```bash
# Format all Nix files
just fmt

# Check flake validity
just check

# Comprehensive validation (format-check, lint, dead-code)
just validate
```

### Advanced Quality Checks

```bash
# Full code quality suite
just quality

# Individual checks
just lint                # Nix code analysis
just dead-code-check     # Unused code detection
just security-audit      # Vulnerability scanning
just outdated-check      # Dependency freshness

# Format validation (non-destructive)
just format-check        # Check if files need formatting
```

### Targeted Validation

```bash
# Check specific file or directory
just check-path modules/desktop/

# Fix dead code automatically
just dead-code-fix
```

## Git Hooks Integration

### Setup

```bash
# Install pre-commit hooks (one-time setup)
just install-hooks

# Complete development environment setup
just dev-setup
```

### Pre-commit Hook Features

The pre-commit configuration automatically runs these checks:

- **File Formatting**: `nixpkgs-fmt` formats Nix files
- **Code Linting**: `statix` analyzes code quality
- **Dead Code Detection**: `deadnix` finds unused code
- **Flake Validation**: Ensures flake builds correctly
- **General Checks**: Trailing whitespace, file endings, JSON/YAML syntax
- **Documentation**: Markdown linting
- **Security**: Basic vulnerability checks

### Managing Hooks

```bash
# Run hooks on all files manually
just run-hooks

# Test hooks without committing
just test-hooks

# Update hook versions
just update-hooks

# Skip hooks for a commit (not recommended)
git commit --no-verify -m "commit message"
```

## Configuration Files

### Pre-commit Configuration

- **`.pre-commit-config.yaml`** - Hook definitions and settings
- **`.markdownlint.yaml`** - Markdown linting rules

### Tool Behavior

**Statix (Linter)**:

- Checks for common Nix anti-patterns
- Suggests improvements and best practices
- Reports unused variables and imports

**Deadnix (Dead Code Detection)**:

- Finds unused function parameters
- Detects unreferenced variables
- Identifies unused imports

**Vulnix (Security)**:

- Scans for known vulnerabilities in dependencies
- Cross-references with NixOS security database
- Provides remediation suggestions

## Development Workflow

### Recommended Workflow

1. **Initial Setup**:

   ```bash
   nix develop
   just dev-setup
   ```

2. **During Development**:

   ```bash
   # Make changes to Nix files
   just validate          # Quick validation
   just test host         # Test configuration
   ```

3. **Before Committing**:

   ```bash
   just quality           # Comprehensive checks
   git add .
   git commit             # Hooks run automatically
   ```

4. **Regular Maintenance**:

   ```bash
   just update            # Update dependencies
   just outdated-check    # Check for newer versions
   just security-audit    # Security review
   ```

## Common Issues and Solutions

### Formatting Issues

```bash
# Problem: Files not properly formatted
ERROR: Some files need formatting. Run 'just fmt' to fix.

# Solution: Format files
just fmt
```

### Linting Warnings

```bash
# Problem: Statix reports code issues
WARNING: Unused binding 'pkgs'

# Solutions:
1. Remove unused variables
2. Prefix with underscore: _pkgs
3. Add to function signature if needed
```

### Dead Code Detection

```bash
# Problem: deadnix finds unused code
ERROR: Unused binding at line 42

# Solutions:
just dead-code-fix      # Automatic removal
# Or manually remove unused code
```

### Hook Failures

```bash
# Problem: Pre-commit hooks fail
ERROR: pre-commit hook failed

# Solutions:
1. Run individual checks: just lint
2. Fix issues manually
3. Re-run: just run-hooks
4. Skip hooks if necessary: git commit --no-verify
```

## Best Practices

### Code Quality

1. **Format Early and Often**: Run `just fmt` frequently
2. **Validate Before Committing**: Use `just validate`
3. **Regular Security Audits**: Run `just security-audit` weekly
4. **Keep Dependencies Updated**: Use `just update` regularly

### Development Environment

1. **Use Development Shell**: Always work in `nix develop`
2. **Install Hooks**: Set up pre-commit hooks early
3. **Test Configurations**: Use `just test` before switching
4. **Document Changes**: Update relevant documentation

### Git Workflow

1. **Small, Focused Commits**: Easier to validate and review
2. **Meaningful Messages**: Describe what and why
3. **Clean History**: Use interactive rebase to clean up
4. **Pre-push Validation**: Run `just quality` before pushing

## Continuous Integration

### GitHub Actions Integration

```yaml
# .github/workflows/validation.yml
name: Validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - run: nix develop --command just validate
      - run: nix develop --command just security-audit
```

### Local CI Simulation

```bash
# Simulate CI environment locally
just quality              # Run all quality checks
just check               # Validate flake
just build example-desktop  # Test build
```

## Customization

### Adding Custom Checks

Edit `.pre-commit-config.yaml` to add new hooks:

```yaml
- repo: local
  hooks:
    - id: custom-check
      name: Custom validation
      entry: your-command
      language: system
      files: '\.nix$'
```

### Tool Configuration

- **Statix**: Create `statix.toml` for custom rules
- **Deadnix**: Use command-line flags in justfile
- **Pre-commit**: Modify `.pre-commit-config.yaml`

## Resources

### Documentation

- [Statix Documentation](https://github.com/nerdypepper/statix)
- [Deadnix Documentation](https://github.com/astro/deadnix)
- [Pre-commit Documentation](https://pre-commit.com/)
- [NixOS Manual - Code Quality](https://nixos.org/manual/nixos/stable/#sec-nix-syntax-summary)

### Learning Resources

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive into Nix
- [NixOS Wiki](https://nixos.wiki/) - Community knowledge base
- [Nix Reference Manual](https://nixos.org/manual/nix/stable/) - Complete reference

## Contributing

When contributing to this template:

1. **Follow the Quality Standards**: All code must pass `just quality`
2. **Update Documentation**: Keep docs in sync with changes
3. **Test Thoroughly**: Validate on multiple configurations
4. **Use Conventional Commits**: Follow commit message conventions

## Getting Help

1. **Check Documentation**: Start with this guide and tool docs
2. **Run Diagnostics**: Use `just --list` to see all commands
3. **Validate Environment**: Ensure `nix develop` works correctly
4. **Community Resources**: NixOS Discord, Reddit, and Discourse
