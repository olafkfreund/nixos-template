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
