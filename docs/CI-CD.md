# CI/CD Documentation

This NixOS template includes comprehensive CI/CD workflows for automated code validation, formatting, and release
management. All workflows are fully functional and pass validation for NixOS 25.05 compatibility.

## GitHub Actions Workflows

### 1. Continuous Integration (`ci.yml`)

Runs on every push and pull request to validate code quality and functionality.

**Jobs (All Passing ✅):**

- **Nix Validation**: Validates flake, checks syntax, and tests configurations
  - ✅ Flake check with zero warnings
  - ✅ 77+ individual Nix files validated
  - ✅ Module import resolution
  - ✅ Comprehensive template validation script

- **Code Quality**: Format checking, linting (statix), dead code detection (deadnix)
  - ✅ All files properly formatted with nixpkgs-fmt
  - ✅ Statix linting passes with zero issues
  - ✅ No dead code detected by deadnix
  - ✅ Justfile syntax validation

- **Shell Validation**: Shellcheck for all shell scripts, executable permissions
  - ✅ All scripts pass shellcheck validation
  - ✅ Proper shebang and executable permissions
  - ✅ Help commands functional on all scripts

- **Documentation**: Markdown linting and link validation
  - ✅ Markdown files pass linting rules
  - ✅ Internal links validated
  - ✅ Documentation structure verified

- **Template Validation**: Ensures all templates have required files
  - ✅ All template directories contain required files
  - ✅ Template syntax validation passes
  - ✅ Build evaluation successful for all templates

- **Security Scan**: Basic security checks and file permissions
  - ✅ No dangerous patterns detected
  - ✅ No hardcoded secrets found
  - ✅ File permissions appropriate

- **Integration Test**: End-to-end testing of flake and justfile commands
  - ✅ Flake evaluation successful
  - ✅ Development shell functional
  - ✅ Justfile commands work correctly

- **Pre-commit**: Validates all pre-commit hooks pass
  - ✅ All formatting and linting tools pass
  - ✅ Hooks configuration valid

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

### 2. Auto Format (`format.yml`)

Automatically formats code and commits changes.

**Features:**

- Formats Nix files with `nixpkgs-fmt`
- Removes dead code with `deadnix`
- Formats shell scripts with `shfmt`
- Formats markdown with `prettier`
- Formats JSON files
- Commits changes automatically with `[skip ci]`

**Triggers:**

- Push to `main` or `develop` branches
- Manual workflow dispatch

### 3. Release Management (`release.yml`)

Automates release creation with comprehensive validation.

**Features:**

- Full validation before release
- Automatic changelog generation
- GitHub release creation with assets
- Version tagging and documentation

**Triggers:**

- Git tags matching `v*.*.*`
- Manual workflow dispatch with version input

## Pre-commit Hooks

Automated code quality checks that run before each commit.

### Local Setup

```bash
# Install pre-commit hooks
just install-hooks

# Run hooks manually on all files
just run-hooks

# Update hook versions
just update-hooks
```

### Included Hooks

**Nix Code Quality:**

- `nixpkgs-fmt`: Format Nix files
- `statix`: Lint Nix code for common issues
- `deadnix`: Remove unused Nix code
- `flake-check`: Validate flake configuration

**Shell Scripts:**

- `shellcheck`: Lint shell scripts
- `shfmt`: Format shell scripts

**General:**

- Remove trailing whitespace
- Ensure files end with newline
- Check for merge conflicts
- Validate YAML/JSON/TOML files
- Check executable permissions
- Lint and format Markdown

## Local Development Commands

### Code Quality

```bash
# Run full validation suite
just validate

# Check code formatting without changes
just format-check

# Format all code
just fmt

# Lint Nix code
just lint

# Check for dead code
just dead-code-check

# Fix dead code automatically
just dead-code-fix

# Run security audit
just security-audit

# Full code quality suite
just quality
```

### CI/CD Commands

```bash
# Run full CI validation locally
just ci-validate

# Prepare a release
just prepare-release v1.0.0

# Run security checks
just security-check

# Set up development environment
just dev-setup
```

### Pre-commit Management

```bash
# Install pre-commit hooks
just install-hooks

# Run all pre-commit hooks
just run-hooks

# Test pre-commit hooks
just test-hooks

# Update pre-commit hook versions
just update-hooks
```

## Validation Pipeline

### 1. Pre-commit Stage

- Runs on `git commit`
- Fast feedback loop
- Prevents bad code from entering repository

### 2. CI Stage (GitHub Actions)

- Runs on push/PR
- Comprehensive validation
- Cross-platform testing
- Security scanning

### 3. Release Stage

- Runs on version tags
- Full validation suite
- Automated changelog
- Asset packaging

## Configuration Files

### `.pre-commit-config.yaml`

Pre-commit hook configuration with all quality checks.

### `.markdownlint.json`

Markdown linting rules for documentation consistency.

### `.gitignore`

Excludes build artifacts, secrets, and local configuration files.

### Workflow Configuration Files

- `.github/workflows/ci.yml` - Main CI pipeline
- `.github/workflows/format.yml` - Auto-formatting
- `.github/workflows/release.yml` - Release management

## Recent Improvements

### 🎉 NixOS 25.05 Compatibility (Latest Update)

**All deprecation warnings resolved:**

- ✅ Updated `services.gpg-agent.pinentryPackage` → `pinentry.package`
- ✅ Updated `programs.vscode.extensions/userSettings` → `profiles.default.*`
- ✅ Updated `hardware.pulseaudio` → `services.pulseaudio`
- ✅ Updated `systemd.watchdog.*` → `settings.Manager.*`

**Syntax Error Fixes:**

- ✅ Fixed missing function arguments in all Nix files
- ✅ Resolved duplicate `environment.systemPackages` declarations
- ✅ Fixed GPU module configuration conflicts
- ✅ Corrected authentication configuration for templates

**Enhanced Validation:**

- ✅ All 77+ Nix files pass syntax validation
- ✅ Zero flake check warnings or errors
- ✅ Complete GitHub Actions pipeline functional
- ✅ VM building capabilities verified
- ✅ Template validation script enhanced

## Quality Standards

### Code Formatting

- **Nix**: `nixpkgs-fmt` for consistent formatting
- **Shell**: `shfmt` with 2-space indentation
- **Markdown**: `prettier` with 120 character lines
- **JSON/YAML**: `prettier` formatting

### Linting Rules

- **Nix**: `statix` for best practices and common issues
- **Shell**: `shellcheck` for script correctness
- **Markdown**: `markdownlint` for documentation consistency

### Security Checks

- No hardcoded secrets or passwords
- No dangerous shell commands (`rm -rf /`)
- Proper file permissions
- Executable script validation

## Integration with IDEs

### VS Code

Install recommended extensions:

- `jnoortheen.nix-ide` - Nix language support
- `timonwong.shellcheck` - Shell script linting
- `davidanson.vscode-markdownlint` - Markdown linting

### Vim/Neovim

Configure with appropriate language servers:

- `nil` or `nixd` for Nix
- `bash-language-server` for shell scripts

## Troubleshooting

### Pre-commit Hook Failures

```bash
# Skip hooks for emergency commits (use sparingly)
git commit --no-verify -m "emergency fix"

# Fix formatting issues
just fmt

# Check what failed
pre-commit run --all-files
```

### CI Failures

```bash
# Run CI validation locally
just ci-validate

# Check specific validation
just validate
just lint
just security-check
```

### Release Issues

```bash
# Validate before creating release
just prepare-release v1.0.0

# Check tag format
git tag --list | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$'
```

## Best Practices

### Development Workflow

1. **Start Development**

   ```bash
   just dev-setup
   ```

2. **Make Changes**
   - Edit configuration files
   - Add new features
   - Update documentation

3. **Validate Changes**

   ```bash
   just validate
   just test
   ```

4. **Commit Changes**

   ```bash
   git add .
   git commit -m "feature: add new functionality"
   # Pre-commit hooks run automatically
   ```

5. **Push Changes**

   ```bash
   git push origin feature-branch
   # CI runs automatically on PR
   ```

### Release Process

1. **Prepare Release**

   ```bash
   just prepare-release v1.0.0
   ```

2. **Push Tag**

   ```bash
   git push origin v1.0.0
   ```

3. **Automated Release**
   - GitHub Actions creates release
   - Changelog generated automatically
   - Documentation assets included

### Code Review Guidelines

- All PRs must pass CI validation
- Pre-commit hooks must be satisfied
- Security checks must pass
- Documentation updates required for new features
- Template changes require validation

## Monitoring and Metrics

### CI Metrics

- Build success rate
- Average build time
- Test coverage trends
- Security scan results

### Code Quality Metrics

- Formatting compliance
- Linting violations
- Dead code detection
- Documentation coverage

### Release Metrics

- Release frequency
- Time to release
- Release success rate
- Issue resolution time

This comprehensive CI/CD system ensures high code quality, security, and reliability for the NixOS template
while providing excellent developer experience.
