# Adding a Host

This page describes how to add a new machine to the flake. Everything below is
checked against the code in `lib/flake-utils.nix` — if a function is named here,
it exists.

> **Previous versions of this page documented `mkWorkstation`, `mkServer`,
> `mkGaming`, `mkLaptop`, `mkVM`, `mkContainer`, `mkDevelopment`, `mkMinimal`,
> `mkMediaServer`, `mkDesktopHost` and `mkServerHost`. None of those functions
> ever existed in this repository** — they were removed as an anti-pattern (see
> [NIXOS-ANTI-PATTERNS.md](NIXOS-ANTI-PATTERNS.md#4-unnecessary-template-functions))
> but the documentation was never updated. There is one builder, `mkSystem`, and
> it takes the machine type as a parameter.

---

## The short version

```bash
# 1. Copy the closest starting point
cp -r hosts/desktop-template hosts/my-desktop

# 2. Generate hardware configuration for THIS machine
sudo nixos-generate-config --show-hardware-config \
  > hosts/my-desktop/hardware-configuration.nix

# 3. Register it: uncomment a line in the "ADD YOUR OWN HOSTS HERE" block
#    near the bottom of flake.nix

# 4. Build it
sudo nixos-rebuild switch --flake .#my-desktop
```

Step 3 in full — in `flake.nix`:

```nix
nixosConfigurations = flakeUtils.allConfigurations // {
  my-desktop = flakeUtils.mkSystem {
    hostname = "my-desktop";
    profile = "workstation";
  };
};
```

Starting points in `hosts/`: `desktop-template`, `laptop-template`,
`server-template`, `wsl2-template`.

---

## `mkSystem`

The single builder for NixOS hosts. Defined in `lib/flake-utils.nix`.

```nix
flakeUtils.mkSystem {
  hostname = "my-server";        # required
  system = "aarch64-linux";      # optional, default "x86_64-linux"
  profile = "server";            # optional, default "workstation"
  extraModules = [ ./extra.nix ];# optional, default [ ]
}
```

| Parameter      | Type            | Default          | Meaning                                                                                                |
| -------------- | --------------- | ---------------- | ------------------------------------------------------------------------------------------------------ |
| `hostname`     | string          | _(required)_     | Must match the directory name under `hosts/`. `mkSystem` imports `hosts/<hostname>/configuration.nix`. |
| `system`       | string          | `"x86_64-linux"` | Nix system double.                                                                                     |
| `profile`      | enum            | `"workstation"`  | One of `workstation`, `server`, `laptop`, `gaming`, `development`, `minimal`.                          |
| `extraModules` | list of modules | `[ ]`            | Appended to the module list.                                                                           |

### What `profile` actually does

`profile` is **metadata**, not a package set. It is passed through `flakeMeta`
to `modules/core/system-identification.nix`, where it drives the system
description, `system.nixos.tags`, the `NIXOS_PROFILE` environment variable and
the `nixos-info` command.

It does **not** by itself install packages or enable services. What your host
gets comes from the modules its `configuration.nix` imports. Setting
`profile = "server"` on a host whose `configuration.nix` imports the desktop
modules still gives you a desktop.

### What every host gets automatically

`mkSystem` always adds:

- `hosts/<hostname>/configuration.nix`
- the Home Manager NixOS module (with `useGlobalPkgs` and `useUserPackages`)
- the agenix NixOS module, for secrets
- a `flakeMeta` module providing `/etc/nixos/flake-metadata.json`, the
  `NIXOS_*` environment variables and the `nixos-info` command

A host's `home.nix` imports the shared Home Manager profiles by relative path,
e.g. `../../home/profiles/desktop.nix`.

---

## Other builders

These exist and are used by this repository, but you are unlikely to need them
for an ordinary machine.

| Function           | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `mkSystem`         | Normal NixOS host. **This is the one you want.** |
| `mkWSLSystem`      | NixOS under WSL2; adds the NixOS-WSL module.     |
| `mkInstaller`      | Installer ISO from `hosts/installer-isos/`.      |
| `mkMacOSInstaller` | Installer ISO from `hosts/macos-isos/`.          |

The pre-built sets `templates`, `testConfigs`, `installers`, `macosVMs` and
`wslConfigs` are merged into `allConfigurations`, which is what `flake.nix`
exposes as `nixosConfigurations`.

---

## Examples

### Headless server on ARM

```nix
my-server = flakeUtils.mkSystem {
  hostname = "my-server";
  system = "aarch64-linux";
  profile = "server";
};
```

### Laptop with extra host-specific modules

```nix
my-laptop = flakeUtils.mkSystem {
  hostname = "my-laptop";
  profile = "laptop";
  extraModules = [
    ./hosts/my-laptop/thinkpad-tweaks.nix
  ];
};
```

### Overriding a setting without a separate file

`extraModules` takes inline modules too:

```nix
my-desktop = flakeUtils.mkSystem {
  hostname = "my-desktop";
  profile = "workstation";
  extraModules = [
    { time.timeZone = "Europe/Oslo"; }
  ];
};
```

---

## Standalone Home Manager

`homeConfigurations` entries are built by `mkHome` in `flake.nix` and are for
using Home Manager **without** NixOS:

```nix
"user@my-desktop" = mkHome { hostname = "my-desktop"; };
```

On a NixOS host you do not need this — `mkSystem` already wires Home Manager in.

---

## Verifying before you switch

```bash
nix flake check                                    # evaluate every host
nix build .#nixosConfigurations.my-desktop.config.system.build.toplevel --dry-run
sudo nixos-rebuild test --flake .#my-desktop       # activate without a boot entry
sudo nixos-rebuild switch --flake .#my-desktop
```

---

## Presets

For a whole machine type in one line, import `../../modules/presets` and pick
one:

```nix
modules.presets = {
  enable = true;
  preset = "workstation";   # workstation | laptop | server | vm | gaming
};
```

`desktop-template` and the `test-*` hosts work this way. Earlier versions also
had a `modules/profiles/` directory doing the same job for one host; it was
imported unconditionally by `modules/default.nix`, so its desktop package set
landed on every host including servers. It has been removed in favour of
presets.
