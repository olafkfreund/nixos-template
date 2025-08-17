# Comprehensive Nix and NixOS Anti-Pattern Reference Guide

## Introduction

This document serves as a comprehensive reference for identifying and avoiding anti-patterns in Nix and NixOS configurations. It covers language-level mistakes, system configuration issues, package management problems, development environment pitfalls, performance bottlenecks, and Home Manager misconfigurations. Each anti-pattern includes descriptions, explanations of why it's problematic, correct alternatives, and code examples.

---

## 1. Nix Language Anti-patterns

### 1.1 Syntax and Type Anti-patterns

#### **Unquoted URLs (Deprecated)**

**Problem:** Using bare URLs without quotes is deprecated and causes parsing ambiguities.

```nix
# ❌ BAD - Unquoted URL
fetchurl {
  url = https://example.com/file.tar.gz;
  sha256 = "...";
}

# ✅ GOOD - Always quote URLs
fetchurl {
  url = "https://example.com/file.tar.gz";
  sha256 = "...";
}
```

**Why problematic:** RFC 45 deprecated unquoted URLs due to parsing ambiguities and static analysis difficulties.

#### **Path Division Confusion**

**Problem:** Nix interprets `6/3` as a path, not division.

```nix
# ❌ BAD - Parsed as relative path
result = 6/3;  # Creates path "./6/3"

# ✅ GOOD - Use spacing for arithmetic
result = 6 / 3;  # Returns 2
# OR
result = builtins.div 6 3;
```

#### **Type Coercion in String Interpolation**

**Problem:** Not all types can be directly interpolated into strings.

```nix
# ❌ BAD - Type coercion failures
let
  number = 42;
  boolean = true;
in {
  badNumber = "${number}";    # Error: cannot coerce integer
  badBoolean = "${boolean}";  # Error: cannot coerce boolean
}

# ✅ GOOD - Explicit conversion
let
  number = 42;
  boolean = true;
in {
  goodNumber = "${toString number}";    # "42"
  goodBoolean = "${toString boolean}";  # "1" or ""
}
```

### 1.2 Scoping and Variable Anti-patterns

#### **Excessive `with` Usage**

**Problem:** `with` at top level makes code hard to analyze and debug.

```nix
# ❌ BAD - Unclear variable origins
with (import <nixpkgs> {});
with lib;
with stdenv;

mkDerivation {
  name = "example";
  buildInputs = [ curl jq ];  # Where do these come from?
}

# ✅ GOOD - Explicit imports
let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib stdenv;
in
stdenv.mkDerivation {
  name = "example";
  buildInputs = with pkgs; [ curl jq ];  # Limited, clear scope
}
```

**Why problematic:** Static analysis tools can't determine variable sources, makes refactoring difficult, and creates ambiguity for newcomers.

#### **Manual Assignment Instead of `inherit`**

**Problem:** Verbose, repetitive, and error-prone.

```nix
# ❌ BAD - Manual repetitive assignment
let
  pkgs = import <nixpkgs> {};
in {
  curl = pkgs.curl;
  jq = pkgs.jq;
  git = pkgs.git;
}

# ✅ GOOD - Use inherit
let
  pkgs = import <nixpkgs> {};
in {
  inherit (pkgs) curl jq git;
}
```

### 1.3 Dangerous Builtins Usage

#### **Import From Derivation (IFD)**

**Problem:** Forces sequential evaluation, blocking the evaluator.

```nix
# ❌ BAD - IFD blocks evaluation
let
  generatedConfig = pkgs.runCommand "config" {} ''
    echo "some_value = 42" > $out
  '';
  configValue = builtins.readFile generatedConfig;  # Forces build!
in
pkgs.writeText "app-config" configValue

# ✅ GOOD - Keep evaluation and building separate
let
  generatedConfig = pkgs.runCommand "config" {} ''
    echo "some_value = 42" > $out
  '';
in
pkgs.runCommand "app-config" { inherit generatedConfig; } ''
  cp $generatedConfig $out
''
```

**Performance impact:** Can increase evaluation time from seconds to hours for complex projects.

#### **Reading Secrets During Evaluation**

**Problem:** Secrets get copied to the world-readable Nix store.

```nix
# ❌ BAD - Exposes password in store
services.myservice = {
  password = builtins.readFile "/secrets/password";  # INSECURE!
}

# ✅ GOOD - Reference paths for runtime loading
services.myservice = {
  passwordFile = "/secrets/password";  # Read at runtime
}

# ✅ BETTER - Use secret management
age.secrets.myservice-password.file = ../secrets/password.age;
services.myservice.passwordFile = config.age.secrets.myservice-password.path;
```

### 1.4 `rec` and `let` Anti-patterns

#### **Dangerous `rec` Usage**

**Problem:** Easy to create infinite recursion with shadowing.

```nix
# ❌ BAD - Infinite recursion
rec {
  a = 1;
  b = let a = a + 1; in a;  # Infinite recursion!
}

# ✅ GOOD - Explicit self-reference
let
  attrset = {
    a = 1;
    b = attrset.a + 1;
  };
in attrset
```

#### **Empty or Collapsible `let` Expressions**

**Problem:** Adds unnecessary visual clutter.

```nix
# ❌ BAD - Empty let
let
in {
  name = "example";
}

# ✅ GOOD - Remove unnecessary let
{
  name = "example";
}
```

---

## 2. NixOS Configuration Anti-patterns

### 2.1 Package Management Anti-patterns

#### **Using `nix-env` for System Packages**

**Problem:** Breaks declarative configuration and reproducibility.

```bash
# ❌ BAD - Imperative installation
nix-env -i firefox vim git
```

```nix
# ✅ GOOD - Declarative in configuration.nix
environment.systemPackages = with pkgs; [
  firefox
  vim
  git
];
```

**Why problematic:** Packages installed via `nix-env` aren't tracked in configuration, persist across rebuilds unexpectedly, and make rollbacks incomplete.

#### **Misusing `environment.systemPackages`**

**Problem:** Installing user-specific packages system-wide.

```nix
# ❌ BAD - Everything system-wide
environment.systemPackages = with pkgs; [
  firefox      # Should be user-specific
  vscode       # Development tool
  spotify      # Personal application
];

# ✅ GOOD - Proper separation
environment.systemPackages = with pkgs; [
  wget curl git vim  # System essentials only
];

users.users.alice.packages = with pkgs; [
  firefox vscode spotify  # User-specific
];
```

### 2.2 Security Anti-patterns

#### **Running Services as Root Unnecessarily**

**Problem:** Violates principle of least privilege.

```nix
# ❌ BAD - Service runs as root by default
systemd.services.myservice = {
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    # No User specified - runs as root!
  };
};

# ✅ GOOD - Dedicated user with hardening
users.users.myservice = {
  isSystemUser = true;
  group = "myservice";
};
users.groups.myservice = {};

systemd.services.myservice = {
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    User = "myservice";
    Group = "myservice";

    # Process isolation
    DynamicUser = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;

    # Capabilities restrictions
    NoNewPrivileges = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;

    # Memory protections
    MemoryDenyWriteExecute = true;
    RestrictRealtime = true;
    LockPersonality = true;
  };
};
```

#### **Poor Firewall Configuration**

**Problem:** Disabling firewall or opening unnecessary ports.

```nix
# ❌ BAD - Security nightmare
networking.firewall.enable = false;
# OR
networking.firewall.allowedTCPPorts = [ 1-65535 ];

# ✅ GOOD - Minimal port opening
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 80 443 ];  # Only what's needed

  # Interface-specific rules
  interfaces."enp3s0" = {
    allowedTCPPorts = [ 5432 ];  # PostgreSQL on internal only
  };
};
```

### 2.3 Module Organization Anti-patterns

#### **Monolithic Configuration File**

**Problem:** Everything in one large `configuration.nix`.

```nix
# ❌ BAD - 500+ line configuration.nix
{ config, pkgs, ... }: {
  boot.loader.grub.enable = true;
  networking.hostName = "myhost";
  services.nginx.enable = true;
  # ... hundreds more lines
}
```

```
# ✅ GOOD - Modular structure
/etc/nixos/
├── configuration.nix        # Main entry point
├── hardware-configuration.nix
├── modules/
│   ├── networking.nix
│   ├── security.nix
│   └── users.nix
└── services/
    ├── nginx.nix
    └── postgresql.nix
```

---

## 3. Package Management Anti-patterns

### 3.1 Overlay Anti-patterns

#### **Incorrect `final` vs `prev` Usage**

**Problem:** Causes infinite recursion or broken dependencies.

```nix
# ❌ BAD - Infinite recursion
final: prev: {
  hello = final.hello.overrideAttrs (oldAttrs: {
    postPatch = "...";
  });
}

# ✅ GOOD - Use prev for overriding
final: prev: {
  hello = prev.hello.overrideAttrs (oldAttrs: {
    postPatch = "...";
  });
}
```

#### **Using `rec` in Overlays**

**Problem:** Breaks composability and prevents later overrides.

```nix
# ❌ BAD - rec breaks composability
final: prev: rec {
  pkg-a = prev.callPackage ./a { };
  pkg-b = prev.callPackage ./b { dependency-a = pkg-a; }
}

# ✅ GOOD - Reference through final
final: prev: {
  pkg-a = prev.callPackage ./a { };
  pkg-b = prev.callPackage ./b { dependency-a = final.pkg-a; };
}
```

### 3.2 Derivation Anti-patterns

#### **Impure Derivations**

**Problem:** Accessing network or filesystem during build.

```nix
# ❌ BAD - Network access during build
stdenv.mkDerivation {
  name = "impure-build";
  buildPhase = ''
    curl -O https://example.com/dependency.tar.gz  # WRONG!
  '';
}

# ✅ GOOD - Pure build with fixed-output derivation
stdenv.mkDerivation {
  name = "pure-build";
  src = fetchurl {
    url = "https://example.com/dependency.tar.gz";
    sha256 = "...";  # Fixed output hash
  };
}
```

#### **Missing Phase Hooks**

**Problem:** Breaking extensibility by not calling hooks.

```nix
# ❌ BAD - No hooks
installPhase = ''
  mkdir -p $out/bin
  cp myprogram $out/bin/
'';

# ✅ GOOD - Include hooks
installPhase = ''
  runHook preInstall
  mkdir -p $out/bin
  cp myprogram $out/bin/
  runHook postInstall
'';
```

#### **Wrong Dependency Types**

**Problem:** Confusing build-time and runtime dependencies.

```nix
# ❌ BAD - Wrong dependency placement
stdenv.mkDerivation {
  buildInputs = [ gcc cmake ];  # Should be nativeBuildInputs!
}

# ✅ GOOD - Correct categorization
stdenv.mkDerivation {
  nativeBuildInputs = [ gcc cmake ];           # Build tools
  buildInputs = [ openssl zlib ];              # Runtime libraries
  propagatedBuildInputs = [ essential-lib ];   # Propagated to consumers
}
```

---

## 4. Development Environment Anti-patterns

### 4.1 Flake Anti-patterns

#### **Everything in flake.nix**

**Problem:** Creates unmaintainable rightward drift.

```nix
# ❌ BAD - All code in flake.nix
{
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation {
      # 100+ lines of derivation code
    };
  };
}

# ✅ GOOD - Modular structure
{
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./package.nix { };
  };
}
```

#### **Cross-compilation Incompatible Outputs**

**Problem:** Hardcoding system prevents cross-compilation.

```nix
# ❌ BAD - System-specific
packages.${system}.myPackage = pkgs.stdenv.mkDerivation { ... };

# ✅ GOOD - Use overlays
overlays.default = final: prev: {
  myPackage = final.callPackage ./package.nix { };
};
```

### 4.2 Shell Environment Anti-patterns

#### **Mixing Build and Runtime Dependencies**

**Problem:** Wrong categorization breaks cross-compilation.

```nix
# ❌ BAD - gcc in buildInputs
mkShell {
  buildInputs = [ gcc nodejs ];  # gcc should be nativeBuildInputs
}

# ✅ GOOD - Proper categorization
mkShell {
  nativeBuildInputs = [ gcc cmake pkg-config ];  # Build tools
  buildInputs = [ openssl postgresql ];           # Runtime libraries
}
```

#### **Blocking direnv Operations**

**Problem:** Slow `.envrc` freezes shells and editors.

```bash
# ❌ BAD - Blocks for 5+ seconds
nix-shell --run 'direnv dump > .envrc.cache'

# ✅ GOOD - Use nix-direnv
use flake  # With nix-direnv installed
```

**Rule:** `.envrc` should execute in <500ms.

### 4.3 CI/CD Anti-patterns

#### **No Binary Cache Usage**

**Problem:** Rebuilding everything from scratch.

```yaml
# ❌ BAD - No caching
- name: Build
  run: nix build

# ✅ GOOD - With caching
- uses: DeterminateSystems/nix-installer-action@main
- uses: DeterminateSystems/magic-nix-cache-action@main
- name: Build
  run: nix build
```

**Performance impact:** Can reduce CI times by 20-40%.

---

## 5. Performance and Maintenance Anti-patterns

### 5.1 Evaluation Performance

#### **Import From Derivation (IFD)**

**Problem:** Blocks parallel evaluation.

```nix
# ❌ BAD - Sequential evaluation
let
  generated = pkgs.runCommand "gen" {} "echo 'data' > $out";
in
  import generated  # Blocks here!

# ✅ GOOD - Pre-generate or use flakes
# Generate files outside of evaluation
```

**Impact:** Can increase evaluation from seconds to hours.

#### **Excessive Thunk Creation**

**Problem:** Memory usage and stack overflow risks.

```nix
# ❌ BAD - Thunk per iteration
let
  values = map (x: let y = 1 + 1; in x) [1 2 3];
in values

# ✅ GOOD - Extract computations
let
  y = 1 + 1;
  values = map (x: x) [1 2 3];
in values
```

### 5.2 Store Management

#### **Never Running Garbage Collection**

**Problem:** Store grows unbounded (100GB+).

```nix
# ❌ BAD - No automated cleanup

# ✅ GOOD - Automated management
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};

nix.optimise = {
  automatic = true;
  dates = [ "03:45" ];
};
```

#### **Poor Binary Cache Configuration**

**Problem:** Missing or misconfigured caches cause rebuilds.

```nix
# ❌ BAD - Wrong public key
nix.settings = {
  substituters = [ "https://cache.example.org" ];
  trusted-public-keys = [ "wrong-key" ];  # Breaks everything!
};

# ✅ GOOD - Proper cache setup
nix.settings = {
  substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
```

### 5.3 Update Strategies

#### **Unsafe System Updates**

**Problem:** Direct production updates without testing.

```bash
# ❌ BAD - Risky
nixos-rebuild switch --upgrade

# ✅ GOOD - Test first
nixos-rebuild build       # Build only
nixos-rebuild test        # Test without making permanent
nixos-rebuild build-vm    # Test in VM
nixos-rebuild switch      # Apply when confident
```

---

## 6. Home Manager Anti-patterns

### 6.1 Integration Issues

#### **Duplicate Package Management**

**Problem:** Same packages in system and Home Manager.

```nix
# ❌ BAD - Duplication
# /etc/nixos/configuration.nix
environment.systemPackages = with pkgs; [ neovim git ];

# ~/.config/home-manager/home.nix
home.packages = with pkgs; [ neovim git ];  # Conflict!

# ✅ GOOD - Clear separation
# System: only system-wide essentials
# Home Manager: user-specific packages
```

#### **Missing stateVersion**

**Problem:** Most common Home Manager error.

```nix
# ❌ BAD - No stateVersion
{
  programs.git.enable = true;
  # Error: The option 'home.stateVersion' is used but not defined
}

# ✅ GOOD - Set once, don't change
{
  home.stateVersion = "24.05";  # Set to current version when starting
  programs.git.enable = true;
}
```

### 6.2 Dotfile Management

#### **Mixing Managed and Unmanaged Configs**

**Problem:** Partial adoption creates conflicts.

```nix
# ❌ BAD - Some files managed, some not
# Creates "file in the way" errors

# ✅ GOOD - Gradual migration
programs.bash = {
  enable = true;
  # Start by importing existing config
  bashrcExtra = builtins.readFile ./bashrc.backup;
  # Gradually migrate to native options
};
```

#### **Improper mkOutOfStoreSymlink Usage**

**Problem:** Breaks flake purity.

```nix
# ❌ BAD - Impure reference
home.file.".vimrc".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.vimrc";

# ✅ GOOD - Pure configuration
home.file.".vimrc".text = ''
  " Vim configuration
  set number
  set expandtab
'';
```

---

## 7. Detection and Prevention Tools

### Language Linters

- **statix**: Detects 20+ anti-patterns automatically

  ```bash
  statix check   # Find issues
  statix fix     # Auto-fix many problems
  ```

- **nixfmt/alejandra**: Enforce consistent formatting

### Package Tools

- **nixpkgs-hammering**: Detects packaging anti-patterns

  ```bash
  nix run github:jtojnar/nixpkgs-hammering -- packagename
  ```

- **nixpkgs-review**: Tests package changes

  ```bash
  nixpkgs-review pr 12345
  ```

### System Tools

- **systemd-analyze security**: Audit service security
- **lynis**: Comprehensive security auditing
- **nixos-rebuild build-vm**: Safe testing environment

### Performance Tools

- **NIX_SHOW_STATS=1**: Shows evaluation statistics
- **nix path-info -S**: Check closure sizes
- **nix-tree**: Visualize dependencies

---

## 8. Quick Reference Checklist

### Language

- [ ] URLs are quoted
- [ ] No excessive `with` statements
- [ ] Using `inherit` where appropriate
- [ ] No IFD in critical paths
- [ ] Secrets not read during evaluation
- [ ] Minimal `rec` usage

### System Configuration

- [ ] No `nix-env` for system packages
- [ ] Proper package separation (system vs user)
- [ ] Services run with minimal privileges
- [ ] Firewall enabled with minimal ports
- [ ] Modular configuration structure

### Packages & Overlays

- [ ] Correct `final` vs `prev` usage
- [ ] No `rec` in overlays
- [ ] Pure derivations only
- [ ] Proper dependency categorization
- [ ] Phase hooks included

### Development

- [ ] Modular flake structure
- [ ] Cross-compilation compatible
- [ ] Fast direnv integration
- [ ] CI caching configured
- [ ] Language-specific tools included

### Performance

- [ ] Garbage collection automated
- [ ] Binary caches configured
- [ ] Store optimization enabled
- [ ] Safe update procedures
- [ ] No unnecessary IFD

### Home Manager

- [ ] stateVersion set correctly
- [ ] No duplicate packages
- [ ] Gradual config migration
- [ ] Services properly isolated
- [ ] Clear system/user separation

---

## Conclusion

This reference guide covers the most critical anti-patterns encountered in real-world Nix and NixOS usage. The key to avoiding these issues is understanding:

1. **Evaluation vs Build Phase**: Keep them separate, avoid IFD
2. **Declarative Philosophy**: Everything in configuration files
3. **Proper Scoping**: Use the right tool for the right scope
4. **Security by Default**: Principle of least privilege
5. **Performance Awareness**: Understand evaluation costs
6. **Gradual Adoption**: Don't try to do everything at once

Success with Nix/NixOS requires patience, understanding of the underlying model, and adherence to community best practices. Use the detection tools, follow the patterns shown here, and always test changes in safe environments before deploying to production.
