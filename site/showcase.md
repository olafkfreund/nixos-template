---
layout: page
title: "Code Showcase"
permalink: /showcase/
description: "Real code from the template — how hosts are registered, how Home Manager profiles compose, how modules expose options, and the anti-patterns this repo deliberately avoids."
---

Everything on this page is copied from the repository, not written for the
brochure. Each block links to the file it came from.

---

## ▸ One builder, not nine

Adding a machine is one function call. The machine type is a **parameter**, not
a separate function — per-variant wrappers are an anti-pattern this repo
[explicitly avoids](https://github.com/olafkfreund/nixos-template/blob/main/docs/NIXOS-ANTI-PATTERNS.md).

<div class="code-card">
<div class="code-head"><span class="path">flake.nix</span><span class="tag">register a host</span></div>
{% highlight nix %}
nixosConfigurations = flakeUtils.allConfigurations // {

my-desktop = flakeUtils.mkSystem {
hostname = "my-desktop"; # must match the hosts/ directory name
profile = "workstation"; # workstation, server, laptop,
}; # gaming, development, minimal

my-server = flakeUtils.mkSystem {
hostname = "my-server";
profile = "server";
system = "aarch64-linux"; # defaults to x86_64-linux
extraModules = [ ./hosts/my-server/services.nix ];
};
};
{% endhighlight %}
</div>

`mkSystem` wires in Home Manager, agenix and a flake-metadata module for every
host, so you never repeat that boilerplate.

<div class="code-card">
<div class="code-head"><span class="path">lib/flake-utils.nix</span><span class="tag">what you get for free</span></div>
{% highlight nix %}
modules = [
  ../hosts/${hostname}/configuration.nix
  home-manager.nixosModules.home-manager
  agenix.nixosModules.default

({ lib, ... }: {
home-manager = {
useGlobalPkgs = lib.mkDefault true;
useUserPackages = lib.mkDefault true;
extraSpecialArgs = { inherit inputs; };
};
})
] ++ extraModules;
{% endhighlight %}
</div>

---

## ▸ Profiles compose, hosts override

A host's `home.nix` imports the profiles it wants and overrides only what is
genuinely machine-specific. No copy-pasted package lists.

<div class="code-card">
<div class="code-head"><span class="path">hosts/desktop-template/home.nix</span><span class="tag">composition</span></div>
{% highlight nix %}
{
  imports = [
    ../../home/profiles/base.nix         # git, shell, core CLI tools
    ../../home/profiles/desktop.nix      # GUI apps and desktop tooling
    ../../home/profiles/development.nix  # languages and dev tools
  ];

home = {
username = "user";
homeDirectory = "/home/user";
};

# Override only what differs on this machine

programs.git = {
userName = "Desktop User";
userEmail = "<user@example.com>";
};
}
{% endhighlight %}
</div>

The profiles themselves stay DRY. Shell aliases are defined once and shared by
both shells rather than duplicated:

<div class="code-card">
<div class="code-head"><span class="path">home/profiles/base.nix</span><span class="tag">define once, use twice</span></div>
{% highlight nix %}
let
  commonAliases = {
    ll = "ls -alF";
    la = "ls -A";
    ".." = "cd ..";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    #
  };
in
{
  programs.bash = {
    # mkDefault so hosts can override individual aliases without conflicts
    shellAliases = lib.mkDefault commonAliases;
  };
  programs.zsh = {
    shellAliases = lib.mkDefault commonAliases;
  };
}
{% endhighlight %}
</div>

---

## ▸ Modules are options, not opinions

Every module declares typed options and stays inert until enabled, so you can
compose them without fighting defaults.

<div class="code-card">
<div class="code-head"><span class="path">modules/hardware/gpu/nvidia.nix</span><span class="tag">typed options</span></div>
{% highlight nix %}
let
  cfg = config.modules.hardware.gpu.nvidia;
  gpuCfg = config.modules.hardware.gpu;
  isDesktop = builtins.elem gpuCfg.profile [ "desktop" "gaming" ];
  isCompute = builtins.elem gpuCfg.profile [ "ai-compute" "server-compute" ];
in
{
  options.modules.hardware.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";

    driver = lib.mkOption {
      type = lib.types.enum [
        "stable" "beta" "production" "legacy_470" "legacy_390" "open"
      ];
      default = "stable";
      description = "NVIDIA driver branch to use";
    };

};
}
{% endhighlight %}
</div>

Turning it on is a line in your host:

<div class="code-card">
<div class="code-head"><span class="path">hosts/&lt;host&gt;/configuration.nix</span><span class="tag">enable it</span></div>
{% highlight nix %}
modules.hardware.gpu.nvidia = {
  enable = true;
  driver = "production";
};
{% endhighlight %}
</div>

---

## ▸ The anti-patterns this repo refuses

These came out of real community review. The rules live in
[NIXOS-ANTI-PATTERNS.md](https://github.com/olafkfreund/nixos-template/blob/main/docs/NIXOS-ANTI-PATTERNS.md)
and are enforced by `statix`, `deadnix` and code review.

<div class="compare">
<div class="code-card bad">
<div class="code-head"><span class="path">✗ don't</span><span class="tag">mkIf true</span></div>
{% highlight nix %}
services.myservice.enable =
  mkIf cfg.enable true;

light.enable =
mkIf (cfg.profile == "laptop") true;
{% endhighlight %}
</div>
<div class="code-card good">
<div class="code-head"><span class="path">✓ do</span><span class="tag">trust the module system</span></div>
{% highlight nix %}
services.myservice.enable = cfg.enable;

light.enable =
cfg.profile == "laptop";
{% endhighlight %}
</div>
</div>

<div class="compare">
<div class="code-card bad">
<div class="code-head"><span class="path">✗ don't</span><span class="tag">magic auto-discovery</span></div>
{% highlight nix %}
discoverModules = dir:
  let
    entries = builtins.readDir dir;
    # ... 30+ lines of filtering
  in modulePaths;
{% endhighlight %}
</div>
<div class="code-card good">
<div class="code-head"><span class="path">✓ do</span><span class="tag">explicit imports</span></div>
{% highlight nix %}
imports = [
  ./core
  ./desktop
  ./development
  ./hardware
];
{% endhighlight %}
</div>
</div>

<div class="compare">
<div class="code-card bad">
<div class="code-head"><span class="path">✗ don't</span><span class="tag">secrets at eval time</span></div>
{% highlight nix %}
# Copies the secret into the
# world-readable Nix store
services.myservice.password =
  builtins.readFile "/secrets/pw";
{% endhighlight %}
</div>
<div class="code-card good">
<div class="code-head"><span class="path">✓ do</span><span class="tag">agenix, read at runtime</span></div>
{% highlight nix %}
age.secrets.db-password.file =
  ../secrets/db-password.age;

services.myservice.passwordFile =
config.age.secrets.db-password.path;
{% endhighlight %}
</div>
</div>

---

## ▸ Secrets stay encrypted in git

`agenix` is wired into every host built by `mkSystem`. Secrets are age-encrypted
in the repository and decrypted to tmpfs at boot — never into the Nix store.

<div class="code-card">
<div class="code-head"><span class="path">modules/security/agenix.nix</span><span class="tag">runtime decryption</span></div>
{% highlight nix %}
options.modules.security.agenix = {
  enable = mkEnableOption "Age-based secret management with agenix";

secretsPath = mkOption {
type = types.str;
default = "/run/agenix"; # tmpfs — in memory, not on disk
description = "Base path where decrypted secrets are stored at runtime.";
};
};
{% endhighlight %}
</div>

See [AGENIX-SECRETS.md]({{ '/docs/AGENIX-SECRETS.html' | relative_url }}) for the
full workflow.

---

## ▸ Desktops are Wayland-only, and configured as modules

GNOME, Hyprland and niri. All three are Wayland-native; there is no X11 session
and no KDE. The two tiling compositors take their configuration from Home
Manager, so a host overrides one binding instead of replacing a whole file.

<div class="code-card">
<div class="code-head"><span class="path">home/profiles/hyprland.nix</span><span class="tag">structured, not a string</span></div>
{% highlight nix %}
wayland.windowManager.hyprland = {
  enable = true;
  xwayland.enable = true;   # Steam and older Electron apps still work

  settings = {
    "$mod" = "SUPER";
    decoration.rounding = 10;

    bind = [
      "$mod, Q, exec, alacritty"
      "$mod, R, exec, wofi --show drun"
    ]
    # 20 workspace bindings, generated rather than written out twice
    ++ builtins.concatMap (i: [
      "$mod, ${toString i}, workspace, ${toString i}"
      "$mod SHIFT, ${toString i}, movetoworkspace, ${toString i}"
    ]) (builtins.genList (n: n + 1) 10);
  };
};
{% endhighlight %}
</div>

niri has no module in nixpkgs or Home Manager, so the template pulls in
[niri-flake](https://github.com/sodiboo/niri-flake) for one — actions are real
Nix values, not strings in a KDL blob.

<div class="code-card">
<div class="code-head"><span class="path">home/profiles/niri.nix</span><span class="tag">typed actions</span></div>
{% highlight nix %}
programs.niri.settings.binds =
  with config.lib.niri.actions;
  {
    "Mod+T".action = spawn "alacritty";
    "Mod+Q".action = close-window;

    # niri's `spawn` has no shell, so a pipeline needs spawn-sh.
    # The old config passed "$(slurp)" and "|" as literal argv.
    "Print".action = spawn-sh ''grim -g "$(slurp)" - | wl-copy'';

    "Mod+WheelScrollDown" = {
      action = focus-workspace-down;
      cooldown-ms = 150;
    };
  };
{% endhighlight %}
</div>

<div class="note">
<b>Why this matters.</b> These were a 158-line <code>hyprland.conf</code> and a
228-line <code>config.kdl</code>, written as inline Nix strings into
<code>/etc</code>. System-wide, so nothing could be overridden per user, and a
config language embedded in a Nix string gets no LSP, no formatter and one
extra indent on every line.
</div>

---

## ▸ Quality is a build gate, not a promise

`nix flake check` evaluates **every** host and builds every lint gate. If a
host stops evaluating, CI goes red.

<div class="code-card">
<div class="code-head"><span class="path">flake.nix</span><span class="tag">checks</span></div>
{% highlight nix %}
checks = forAllSystems (system: {
  statix-check     = ...;   # lints every .nix file
  deadnix-check    = ...;   # fails on unused declarations
  shellcheck-check = ...;   # every script in scripts/
  treefmt          = ...;   # nixfmt + shfmt + mdformat + yamlfmt + prettier
  pre-commit-check = ...;
  vm-test-desktop  = ...;   # boots a real VM and asserts on services
  vm-test-server   = ...;
}
// nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
  wsl2-config = self.nixosConfigurations.wsl2-template.config.system.build.toplevel;
  wsl2-home   = self.homeConfigurations."nixos@wsl2-template".activationPackage;
});
{% endhighlight %}
</div>

The VM tests boot an actual machine and assert against it:

<div class="code-card">
<div class="code-head"><span class="path">flake.nix</span><span class="tag">vm-test-server</span></div>
{% highlight python %}
machine.start()
machine.wait_for_unit("multi-user.target")

machine.wait_for_unit("sshd.service")
machine.succeed("systemctl is-active sshd")
machine.succeed("systemctl is-active firewall")

machine.shutdown()
{% endhighlight %}
</div>

<div class="note">
<b>Run it yourself.</b> <code>nix flake check</code> reproduces the whole suite
locally — the same thing CI runs, with no extra setup.
</div>

---

<div class="btn-row">
<a class="btn btn-primary" href="{{ '/getting-started/' | relative_url }}">get started</a>
<a class="btn" href="{{ '/documentation/' | relative_url }}">full documentation</a>
<a class="btn" href="{{ site.github_repo }}">browse the source</a>
</div>
