# NixOS Anti-Patterns and Best Practices

> **Important**: These patterns were identified through community feedback and code review in GitHub issues #10, #11, and #12. Following these guidelines prevents common mistakes and ensures idiomatic NixOS code.

## 📚 Background

This document captures critical lessons learned from real community feedback about anti-patterns in NixOS configurations. These patterns were found in this repository and fixed based on expert review, helping establish guidelines for future development.

## ❌ **Critical Anti-Patterns to Avoid**

### **1. The `mkIf true` Anti-Pattern**

```nix
# ❌ WRONG - Unnecessary abstraction
services.myservice.enable = mkIf cfg.enable true;
light.enable = mkIf (cfg.profile == "laptop") true;
qemuGuest.enable = mkIf (cfg.type == "qemu" || cfg.type == "auto") true;

# ✅ CORRECT - Direct assignment
services.myservice.enable = cfg.enable;
light.enable = cfg.profile == "laptop";
qemuGuest.enable = cfg.type == "qemu" || cfg.type == "auto";
```

**Why this is wrong**:

- The NixOS module system automatically ignores disabled services
- `mkIf condition true` adds evaluation overhead for no benefit
- Trust the module system to handle enablement correctly
- This pattern was found in 8+ locations in the original codebase

### **2. Trivial Function Wrappers**

```nix
# ❌ WRONG - Pointless re-exports that add no value
mkMerge = lib.mkMerge;
mkIf = condition: config: lib.mkIf condition config;

# Functions that just call other functions with the same parameters
mkService = { name, enable ? true, config ? { } }:
  lib.mkIf enable {  # Also combines with anti-pattern #1
    services.${name} = lib.mkMerge [
      { enable = true; }
      config
    ];
  };

# ✅ CORRECT - Use library functions directly
lib.mkMerge [...]
lib.mkIf condition config

# For services, trust the module system
services.${name} = lib.mkMerge [
  { inherit enable; }
  config
];
```

**Why this is wrong**:

- Re-exporting without adding value creates pointless complexity
- Makes code harder to understand, not easier
- Increases maintenance burden without benefit
- The original `lib/default.nix` was deleted entirely due to this pattern

### **3. Magic Auto-Discovery**

```nix
# ❌ WRONG - Complex auto-discovery that hides behavior
discoverModules = dir:
  let
    entries = builtins.readDir dir;
    moduleEntries = lib.filterAttrs
      (name: type:
        name != "installer" &&
        (type == "directory" ||
         (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
      )
      entries;
    modulePaths = lib.mapAttrsToList
      (name: type:
        if type == "directory" then
          dir + "/${name}"
        else
          dir + "/${name}"
      )
      moduleEntries;
  in
  modulePaths;

# ✅ CORRECT - Explicit imports are clear and obvious
imports = [
  ./core
  ./desktop
  ./development
  ./gaming
  ./hardware
  ./presets
  ./profiles
  ./security
  ./services
  ./virtualization
  ./wsl
  ./template.nix
];
```

**Why this is wrong**:

- Makes debugging extremely difficult
- Hides module dependencies and load order
- Non-obvious behavior that surprises users
- 30+ lines of complex logic replaced with simple explicit list

### **4. Unnecessary Template Functions**

```nix
# ❌ WRONG - Redundant wrappers for every possible variant
mkWorkstation = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
  mkSystem { inherit hostname system extraModules; profile = "workstation"; };

mkServer = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
  mkSystem { inherit hostname system extraModules; profile = "server"; };

mkDevelopment = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
  mkSystem { inherit hostname system extraModules; profile = "development"; };

mkGaming = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
  mkSystem { inherit hostname system extraModules; profile = "gaming"; };

# ... 5 more similar functions

# ✅ CORRECT - Direct usage with explicit parameters
nixosConfigurations = {
  my-workstation = mkSystem {
    hostname = "my-workstation";
    profile = "workstation";
  };

  my-server = mkSystem {
    hostname = "my-server";
    profile = "server";
    system = "aarch64-linux";
  };
};
```

**Why this is wrong**:

- Creates maintenance burden without adding value
- Users can call the base function directly with desired parameters
- Proliferates similar functions (9 template functions were removed)
- Each wrapper function saved only 1 line of code

### **5. Code Duplication Without Extraction**

```nix
# ❌ WRONG - Repeated definitions across configurations
programs.bash.shellAliases = {
  ll = "ls -alF";
  la = "ls -A";
  l = "ls -CF";
  ".." = "cd ..";
  "..." = "cd ../..";
  gs = "git status";
  ga = "git add";
  gc = "git commit";
  gp = "git push";
  gl = "git log --oneline";
  gd = "git diff";
  # ... more aliases
};

programs.zsh.shellAliases = {
  ll = "ls -alF";        # Exact duplication
  la = "ls -A";          # Exact duplication
  l = "ls -CF";          # Exact duplication
  ".." = "cd ..";        # Exact duplication
  "..." = "cd ../..";    # Exact duplication
  gs = "git status";     # Exact duplication
  ga = "git add";        # Exact duplication
  # ... same aliases repeated
};

# ✅ CORRECT - Shared definition with proper extraction
let
  commonAliases = {
    # System shortcuts
    ll = "ls -alF";
    la = "ls -A";
    l = "ls -CF";
    ".." = "cd ..";
    "..." = "cd ../..";

    # Git shortcuts
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline";
    gd = "git diff";

    # System monitoring
    psg = "ps aux | grep";
    h = "history";
    j = "jobs -l";

    # Safety aliases
    rm = "rm -i";
    cp = "cp -i";
    mv = "mv -i";

    # Directory shortcuts
    mkdir = "mkdir -pv";
  };
in {
  programs.bash.shellAliases = commonAliases;
  programs.zsh.shellAliases = commonAliases;
}
```

**Why this is wrong**:

- Violates DRY (Don't Repeat Yourself) principle
- Creates maintenance nightmare when aliases need updates
- Easy to have definitions drift apart over time
- 25+ lines of duplication eliminated by proper extraction

## ✅ **Required Patterns for NixOS**

### **1. Always Use Explicit Imports**

- List all module imports explicitly in a clear list
- Avoid auto-discovery mechanisms that hide behavior
- Make dependencies and load order obvious
- Enable easy addition/removal of modules

### **2. Trust the NixOS Module System**

- Don't wrap functionality that already works correctly
- Use direct boolean assignments for service enablement
- Let the type system and module evaluation do their job
- The module system handles disabled services properly

### **3. Extract Common Functionality Properly**

- Use shared variables for truly repeated data
- Create functions only when they add real abstraction value
- Prefer composition over unnecessary wrapper functions
- Extract at the right level (don't over-abstract)

### **4. Follow Community Standards**

- Use established NixOS patterns from nixpkgs
- Don't reinvent existing functionality
- Check how official modules handle similar cases
- Prefer explicit over implicit behavior

### **5. Be Transparent About AI Assistance**

- Always disclose AI involvement prominently in generated code
- Encourage human review of generated configurations
- Welcome community feedback and expert oversight
- Add warnings about reviewing AI-generated content carefully

## **Performance and Maintainability Impact**

The anti-pattern fixes in this repository resulted in:

- **165 lines of code removed** (net reduction from 225 deletions, 60 additions)
- **Elimination of evaluation overhead** from unnecessary `mkIf` wrappers
- **Improved debugging experience** with explicit imports
- **Reduced maintenance burden** by eliminating duplicate code
- **Better alignment with NixOS community patterns**

## **Code Review Checklist**

Before submitting any NixOS configuration changes, verify:

- [ ] **No `mkIf condition true` patterns** - use direct assignment instead
- [ ] **No trivial function re-exports** - call library functions directly
- [ ] **No magic auto-discovery mechanisms** - use explicit imports
- [ ] **All imports are explicit and clear** - avoid hidden module loading
- [ ] **Common functionality is properly extracted** - eliminate duplication
- [ ] **Functions add real value, not just parameter passing** - avoid wrapper proliferation
- [ ] **Configuration follows NixOS community patterns** - check nixpkgs for examples
- [ ] **AI assistance is properly disclosed** (if applicable) - transparency in generated content

## **When in Doubt - Decision Framework**

1. **Check nixpkgs**: How do official modules handle similar functionality?
1. **Ask the community**: NixOS Discourse or Matrix channels for guidance
1. **Prefer explicit**: Make behavior obvious and discoverable, not magical
1. **Trust the system**: NixOS modules handle most cases correctly without extra wrapping
1. **Less is more**: Remove code and abstractions rather than adding unnecessary ones

## **Real-World Example: Before and After**

### Before (Anti-patterns)

```nix
# lib/default.nix (32 lines - DELETED ENTIRELY)
{ lib }:
rec {
  mkHost = import ./mkHost.nix { inherit lib; };
  mkIf = condition: config: lib.mkIf condition config;  # Pointless wrapper
  mkMerge = lib.mkMerge;                                # Pointless re-export
  mkService = { name, enable ? true, config ? { } }:   # Unnecessary abstraction
    lib.mkIf enable {                                  # Anti-pattern #1
      services.${name} = lib.mkMerge [
        { enable = true; }
        config
      ];
    };
}

# modules/default.nix (49 lines of auto-discovery logic)
discoverModules = dir: let
  # ... 30+ lines of complex auto-discovery
in modulePaths;

# Multiple files with mkIf true patterns
services.qemuGuest.enable = mkIf (cfg.type == "qemu" || cfg.type == "auto") true;
programs.dconf.enable = mkIf cfg.applications.gnome-boxes true;
# ... 8 more instances

# Duplicate shell aliases in home/profiles/base.nix
programs.bash.shellAliases = { ll = "ls -alF"; la = "ls -A"; /* ... */ };
programs.zsh.shellAliases = { ll = "ls -alF"; la = "ls -A"; /* ... */ };
```

### After (Best practices)

```nix
# lib/default.nix - DELETED (unnecessary abstractions removed)

# modules/default.nix (17 lines - explicit and clear)
{
  imports = [
    ./core
    ./desktop
    ./development
    ./gaming
    ./hardware
    ./presets
    ./profiles
    ./security
    ./services
    ./virtualization
    ./wsl
    ./template.nix
  ];
}

# Direct assignments throughout codebase
services.qemuGuest.enable = cfg.type == "qemu" || cfg.type == "auto";
programs.dconf.enable = cfg.applications.gnome-boxes;

# Shared aliases in home/profiles/base.nix
let
  commonAliases = {
    ll = "ls -alF";
    la = "ls -A";
    # ... defined once
  };
in {
  programs.bash.shellAliases = commonAliases;
  programs.zsh.shellAliases = commonAliases;
}
```

## **Community Feedback Integration**

These patterns were identified through:

- **GitHub Issues #10, #11, #12** from experienced NixOS community members
- **Expert code review** pointing out anti-patterns and suggesting improvements
- **Performance analysis** showing evaluation overhead from unnecessary abstractions
- **Maintainability concerns** about hidden behavior and debugging difficulty

This demonstrates the importance of:

- **Community review** for code quality
- **Transparency** about AI-generated content
- **Responsiveness** to expert feedback
- **Continuous improvement** based on best practices

## **Conclusion**

Following these guidelines ensures NixOS configurations that are:

- **Idiomatic** and follow community standards
- **Maintainable** with clear, explicit behavior
- **Performant** without unnecessary evaluation overhead
- **Debuggable** with obvious module relationships
- **Trustworthy** with proper disclosure of AI assistance

These patterns help both human developers and AI systems create better NixOS code that the community can rely on and build upon.

---

## **Extended Comprehensive Anti-Patterns Reference**

> **Source**: Research compilation from @docs/researched-antipatterns.md and community best practices

### **🔍 Nix Language Anti-Patterns**

#### **Unquoted URLs (Deprecated)**

```nix
# ❌ BAD - RFC 45 deprecated this due to parsing ambiguities
fetchurl {
  url = https://example.com/file.tar.gz;  # Causes static analysis issues
  sha256 = "...";
}

# ✅ GOOD - Always quote URLs
fetchurl {
  url = "https://example.com/file.tar.gz";
  sha256 = "...";
}
```

#### **Path Division Confusion**

```nix
# ❌ BAD - Nix interprets 6/3 as path "./6/3"
result = 6/3;

# ✅ GOOD - Use spacing for arithmetic
result = 6 / 3;  # Returns 2
# OR explicit function
result = builtins.div 6 3;
```

#### **Type Coercion in String Interpolation**

```nix
# ❌ BAD - Cannot coerce these types
let
  number = 42;
  boolean = true;
in {
  badNumber = "${number}";    # Error: cannot coerce integer
  badBoolean = "${boolean}";  # Error: cannot coerce boolean
}

# ✅ GOOD - Explicit conversion
{
  goodNumber = "${toString number}";    # "42"
  goodBoolean = "${toString boolean}";  # "1" or ""
}
```

#### **Excessive `with` Usage**

```nix
# ❌ BAD - Unclear variable origins, breaks static analysis
with (import <nixpkgs> {});
with lib;
with stdenv;

mkDerivation {
  name = "example";
  buildInputs = [ curl jq ];  # Where do these come from?
}

# ✅ GOOD - Explicit imports with limited scope
let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib stdenv;
in
stdenv.mkDerivation {
  name = "example";
  buildInputs = with pkgs; [ curl jq ];  # Clear, limited scope
}
```

#### **Manual Assignment Instead of `inherit`**

```nix
# ❌ BAD - Verbose and error-prone
let pkgs = import <nixpkgs> {};
in {
  curl = pkgs.curl;
  jq = pkgs.jq;
  git = pkgs.git;
}

# ✅ GOOD - Use inherit for cleaner syntax
let pkgs = import <nixpkgs> {};
in {
  inherit (pkgs) curl jq git;
}
```

### **🚨 Dangerous Builtins Usage**

#### **Import From Derivation (IFD) - Critical**

```nix
# ❌ BAD - Forces sequential evaluation, blocks parallelism
let
  generatedConfig = pkgs.runCommand "config" {} ''
    echo "some_value = 42" > $out
  '';
  configValue = builtins.readFile generatedConfig;  # Forces build during eval!
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

**Performance Impact**: Can increase evaluation time from seconds to hours for complex projects.

#### **Reading Secrets During Evaluation - Security Critical**

```nix
# ❌ BAD - Exposes password in world-readable Nix store
services.myservice = {
  password = builtins.readFile "/secrets/password";  # MAJOR SECURITY ISSUE!
}

# ✅ GOOD - Reference paths for runtime loading
services.myservice = {
  passwordFile = "/secrets/password";  # Read at runtime only
}

# ✅ BETTER - Use proper secret management
age.secrets.myservice-password.file = ../secrets/password.age;
services.myservice.passwordFile = config.age.secrets.myservice-password.path;
```

### **🏗️ System Configuration Anti-Patterns**

#### **Using `nix-env` for System Packages**

```bash
# ❌ BAD - Breaks declarative configuration and reproducibility
nix-env -i firefox vim git
# Packages persist across rebuilds, aren't tracked in config
```

```nix
# ✅ GOOD - Declarative in configuration.nix
environment.systemPackages = with pkgs; [
  firefox vim git
];
```

**Why Problematic**: `nix-env` packages aren't tracked in configuration, persist across rebuilds unexpectedly, and make rollbacks incomplete.

#### **Misusing `environment.systemPackages`**

```nix
# ❌ BAD - Installing user-specific packages system-wide
environment.systemPackages = with pkgs; [
  firefox      # Should be user-specific
  vscode       # Development tool for individual users
  spotify      # Personal application
];

# ✅ GOOD - Proper separation of concerns
environment.systemPackages = with pkgs; [
  wget curl git vim  # System essentials only
];

users.users.alice.packages = with pkgs; [
  firefox vscode spotify  # User-specific applications
];
```

#### **Running Services as Root Unnecessarily**

```nix
# ❌ BAD - Violates principle of least privilege
systemd.services.myservice = {
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    # No User specified - runs as root with full privileges!
  };
};

# ✅ GOOD - Dedicated user with comprehensive hardening
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

```nix
# ❌ BAD - Security nightmare
networking.firewall.enable = false;  # Completely exposed!
# OR
networking.firewall.allowedTCPPorts = [ 1-65535 ];  # Everything open!

# ✅ GOOD - Minimal, targeted port opening
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 80 443 ];  # Only what's actually needed

  # Interface-specific rules for internal services
  interfaces."enp3s0" = {
    allowedTCPPorts = [ 5432 ];  # PostgreSQL on internal network only
  };
};
```

#### **Monolithic Configuration File**

```nix
# ❌ BAD - Everything in one massive configuration.nix (500+ lines)
{ config, pkgs, ... }: {
  boot.loader.grub.enable = true;
  networking.hostName = "myhost";
  services.nginx.enable = true;
  services.postgresql.enable = true;
  # ... hundreds more lines making maintenance impossible
}
```

```
# ✅ GOOD - Modular structure for maintainability
/etc/nixos/
├── configuration.nix        # Main entry point (imports only)
├── hardware-configuration.nix
├── modules/
│   ├── networking.nix
│   ├── security.nix
│   └── users.nix
└── services/
    ├── nginx.nix
    └── postgresql.nix
```

### **📦 Package Management Anti-Patterns**

#### **Incorrect `final` vs `prev` Usage in Overlays**

```nix
# ❌ BAD - Causes infinite recursion
final: prev: {
  hello = final.hello.overrideAttrs (oldAttrs: {
    postPatch = "...";
  });  # Refers to itself - infinite loop!
}

# ✅ GOOD - Use prev for the base package
final: prev: {
  hello = prev.hello.overrideAttrs (oldAttrs: {
    postPatch = "...";
  });
}
```

#### **Using `rec` in Overlays**

```nix
# ❌ BAD - Breaks composability and prevents later overrides
final: prev: rec {
  pkg-a = prev.callPackage ./a { };
  pkg-b = prev.callPackage ./b { dependency-a = pkg-a; }  # Fixed reference
}

# ✅ GOOD - Reference through final for composability
final: prev: {
  pkg-a = prev.callPackage ./a { };
  pkg-b = prev.callPackage ./b { dependency-a = final.pkg-a; };  # Overrideable
}
```

#### **Impure Derivations**

```nix
# ❌ BAD - Network access during build breaks reproducibility
stdenv.mkDerivation {
  name = "impure-build";
  buildPhase = ''
    curl -O https://example.com/dependency.tar.gz  # Non-deterministic!
  '';
}

# ✅ GOOD - Pure build with fixed-output derivation
stdenv.mkDerivation {
  name = "pure-build";
  src = fetchurl {
    url = "https://example.com/dependency.tar.gz";
    sha256 = "...";  # Fixed output hash ensures reproducibility
  };
}
```

#### **Missing Phase Hooks**

```nix
# ❌ BAD - Breaks extensibility by not calling hooks
installPhase = ''
  mkdir -p $out/bin
  cp myprogram $out/bin/
'';

# ✅ GOOD - Include hooks for extensibility
installPhase = ''
  runHook preInstall
  mkdir -p $out/bin
  cp myprogram $out/bin/
  runHook postInstall
'';
```

#### **Wrong Dependency Types**

```nix
# ❌ BAD - Confusing build-time and runtime dependencies
stdenv.mkDerivation {
  buildInputs = [ gcc cmake ];  # Build tools should be nativeBuildInputs!
}

# ✅ GOOD - Correct categorization for cross-compilation
stdenv.mkDerivation {
  nativeBuildInputs = [ gcc cmake ];           # Build tools (host→target)
  buildInputs = [ openssl zlib ];              # Runtime libraries
  propagatedBuildInputs = [ essential-lib ];   # Propagated to consumers
}
```

### **🚀 Performance Anti-Patterns**

#### **Never Running Garbage Collection**

```nix
# ❌ BAD - Store grows unbounded (can reach 100GB+)
# No garbage collection configuration

# ✅ GOOD - Automated store management
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};

nix.optimise = {
  automatic = true;
  dates = [ "03:45" ];  # Run during low-usage hours
};
```

#### **Poor Binary Cache Configuration**

```nix
# ❌ BAD - Wrong public keys break substitution entirely
nix.settings = {
  substituters = [ "https://cache.example.org" ];
  trusted-public-keys = [ "wrong-key" ];  # Everything rebuilds from source!
};

# ✅ GOOD - Proper cache setup with verified keys
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

#### **Unsafe System Updates**

```bash
# ❌ BAD - Direct production updates without testing
nixos-rebuild switch --upgrade  # Risky on production systems!

# ✅ GOOD - Safe testing workflow
nixos-rebuild build       # Build without applying
nixos-rebuild test        # Test without permanent changes
nixos-rebuild build-vm    # Test in isolated VM
nixos-rebuild switch      # Apply only when confident
```

### **🏠 Home Manager Anti-Patterns**

#### **Missing stateVersion - Most Common Error**

```nix
# ❌ BAD - Causes "option 'home.stateVersion' is used but not defined"
{
  programs.git.enable = true;
  # Error: The option 'home.stateVersion' is used but not defined
}

# ✅ GOOD - Always set stateVersion (set once, never change)
{
  home.stateVersion = "24.05";  # Use version when you started
  programs.git.enable = true;
}
```

#### **Duplicate Package Management**

```nix
# ❌ BAD - Same packages in both system and Home Manager
# /etc/nixos/configuration.nix
environment.systemPackages = with pkgs; [ neovim git ];

# ~/.config/home-manager/home.nix
home.packages = with pkgs; [ neovim git ];  # Conflict and waste!

# ✅ GOOD - Clear separation of responsibilities
# System: system-wide essentials only
# Home Manager: user-specific packages and configurations
```

#### **Improper mkOutOfStoreSymlink Usage**

```nix
# ❌ BAD - Breaks flake purity and portability
home.file.".vimrc".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.vimrc";

# ✅ GOOD - Pure configuration that works everywhere
home.file.".vimrc".text = ''
  " Vim configuration
  set number
  set expandtab
  set tabstop=2
'';
```

### **🔧 Development Environment Anti-Patterns**

#### **Everything in flake.nix - Rightward Drift**

```nix
# ❌ BAD - Creates unmaintainable complexity
{
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation {
      # 100+ lines of derivation code making flake.nix huge
    };
  };
}

# ✅ GOOD - Modular structure with separation of concerns
{
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./package.nix { };
  };
}
```

#### **Blocking direnv Operations**

```bash
# ❌ BAD - Slow .envrc freezes shells and editors for 5+ seconds
nix-shell --run 'direnv dump > .envrc.cache'

# ✅ GOOD - Use nix-direnv for instant activation
use flake  # With nix-direnv installed - executes in <500ms
```

**Rule**: `.envrc` should execute in under 500ms for good developer experience.

### **🛠️ Detection and Prevention Tools**

#### **Automated Anti-Pattern Detection**

```bash
# Language linting and formatting
statix check           # Detects 20+ anti-patterns automatically
statix fix             # Auto-fixes many problems
nixfmt .              # Consistent formatting
alejandra .           # Alternative formatter

# Package analysis
nixpkgs-hammering      # Detects packaging anti-patterns
nixpkgs-review pr 123  # Tests package changes safely

# System security analysis
systemd-analyze security service-name    # Service security audit
lynis                                   # Comprehensive system security scan
```

#### **Performance Analysis Tools**

```bash
# Evaluation performance
NIX_SHOW_STATS=1 nix build    # Shows evaluation statistics
nix path-info -S              # Check closure sizes
nix-tree                      # Visualize dependency graphs

# Store management
nix-du                        # Analyze store usage
nix store optimise            # Deduplicate store paths
```

### **✅ Final Checklist for Quality Assurance**

Before any configuration change, verify:

#### **Language & Evaluation**

- [ ] URLs are quoted (no bare URLs)
- [ ] Minimal `with` usage (explicit imports preferred)
- [ ] No IFD in critical evaluation paths
- [ ] Secrets not read during evaluation
- [ ] Minimal `rec` usage (prefer explicit references)
- [ ] No type coercion errors in string interpolation

#### **System Configuration**

- [ ] No `nix-env` usage for system packages
- [ ] Proper package separation (system vs user scope)
- [ ] Services run with minimal privileges and hardening
- [ ] Firewall enabled with minimal necessary ports
- [ ] Modular configuration structure for maintainability

#### **Package Management**

- [ ] Correct `final` vs `prev` usage in overlays
- [ ] No `rec` in overlays (breaks composability)
- [ ] Pure derivations only (no network access during build)
- [ ] Proper dependency categorization (native vs build vs propagated)
- [ ] Phase hooks included for extensibility

#### **Performance & Maintenance**

- [ ] Garbage collection automated with reasonable retention
- [ ] Binary caches configured with correct public keys
- [ ] Store optimization enabled
- [ ] Safe update procedures documented and followed
- [ ] No unnecessary IFD blocking evaluation

#### **Home Manager Integration**

- [ ] `stateVersion` set correctly (and never changed)
- [ ] No duplicate packages between system and user
- [ ] Gradual config migration strategy
- [ ] Pure configuration (no impure symlinks)
- [ ] Clear system/user separation of responsibilities

### **🎯 Key Success Principles**

1. **Evaluation vs Build Phase**: Keep them completely separate to enable parallelism
2. **Declarative Philosophy**: Everything in configuration files, no imperative changes
3. **Proper Scoping**: Right tool for the right scope (system vs user vs build-time)
4. **Security by Default**: Principle of least privilege everywhere
5. **Performance Awareness**: Understand evaluation costs and caching strategies
6. **Gradual Adoption**: Don't try to migrate everything at once
7. **Community Standards**: Follow established patterns from nixpkgs

**Remember**: Success with Nix/NixOS requires patience, understanding of the underlying model, and strict adherence to community best practices. Always test changes in safe environments before deploying to production systems.

---

## **References and Further Reading**

- **Primary Anti-Patterns Guide**: @docs/researched-antipatterns.md (comprehensive reference)
- **Repository-Specific Patterns**: @CLAUDE.md (development guidelines for this repo)
- **Official Documentation**: [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- **Community Resources**: [NixOS Discourse](https://discourse.nixos.org/), [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)
- **Code Quality Tools**: [statix](https://github.com/nerdypepper/statix), [nixpkgs-hammering](https://github.com/jtojnar/nixpkgs-hammering)

This comprehensive guide ensures robust, maintainable, and community-standard NixOS configurations.
