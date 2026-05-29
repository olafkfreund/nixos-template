---
layout: page
title: "Getting Started"
---

```
$ nix develop  # drop into the development shell
```

This page walks you through the full happy path: from cloning the repo to a running NixOS system.

---

## Prerequisites

- Nix with flakes enabled (`experimental-features = nix-command flakes` in `/etc/nix/nix.conf`)
- Or use the [Determinate Systems Nix installer](https://install.determinate.systems/) which enables flakes by default
- `git`

---

## Step 1 — Clone and enter the dev shell

```bash
git clone https://github.com/olafkfreund/nixos-template.git
cd nixos-template
nix develop
```

The dev shell provides: `nixpkgs-fmt`, `statix`, `deadnix`, `nix-tree`, `just`, and all other tooling referenced in the `justfile`.

---

## Step 2 — Choose a host template

| Template | Use case |
|---|---|
| `hosts/desktop-template` | Workstation with GNOME, full Home Manager profiles |
| `hosts/laptop-template` | Same as desktop with power management |
| `hosts/server-template` | Headless, SSH-hardened, server Home Manager profile |
| `hosts/wsl2-template` | NixOS inside Windows Subsystem for Linux 2 |
| `hosts/darwin-desktop` | macOS workstation via nix-darwin |
| `hosts/darwin-laptop` | macOS laptop via nix-darwin |
| `hosts/darwin-server` | macOS server via nix-darwin |

```bash
cp -r hosts/desktop-template hosts/my-machine
```

---

## Step 3 — Customise

Edit `hosts/my-machine/configuration.nix`:

```nix
networking.hostName = "my-machine";

# Pick your GPU (amd | nvidia | intel | none)
hardware.gpu.type = "amd";

# Add extra system packages
environment.systemPackages = with pkgs; [ vim ];
```

Edit `hosts/my-machine/home.nix` to add or remove Home Manager profiles:

```nix
imports = [
  ../../home/profiles/base.nix        # always included
  ../../home/profiles/desktop.nix     # GUI tools
  ../../home/profiles/development.nix # languages and dev tools
];
```

---

## Step 4 — Generate hardware config

On the target machine (or in a VM):

```bash
sudo nixos-generate-config --show-hardware-config > hosts/my-machine/hardware-configuration.nix
```

---

## Step 5 — Register in flake.nix

Add your host to the `nixosConfigurations` attrset following the existing pattern:

```nix
nixosConfigurations.my-machine = mkSystem {
  hostname = "my-machine";
  system = "x86_64-linux";
};
```

---

## Step 6 — Build and switch

```bash
just switch my-machine
# expands to: sudo nixos-rebuild switch --flake .#my-machine
```

---

## Common `just` commands

| Command | What it does |
|---|---|
| `just switch [host]` | Build and apply configuration |
| `just test [host]` | Test without making the change permanent |
| `just build [host]` | Build without switching |
| `just update` | Update all flake inputs |
| `just update-switch [host]` | Update inputs then switch |
| `just fmt` | Format all Nix files with `nixpkgs-fmt` |
| `just lint` | Run `statix check` |
| `just validate` | Full validation: check + lint + format-check + dead-code |
| `just check` | `nix flake check` |
| `just vm [host]` | Build and run host as a QEMU VM |
| `just build-wsl2-archive` | Build WSL2 tarball |
| `just setup-secrets` | Set up agenix secrets management |
| `just edit-secret SECRET` | Encrypt and edit a secret |
| `just list-secrets` | Show all age-encrypted secrets |
| `just rekey-secrets` | Re-encrypt after adding a new age key |

---

## Validate before switching

```bash
just validate
# Runs: flake check → statix → format check → deadnix
```

All checks pass on a clean clone. Keeping them green is a project requirement.

---

## Further reading

- [Features overview](https://github.com/olafkfreund/nixos-template/blob/main/docs/FEATURES-OVERVIEW.md)
- [Host templates](https://github.com/olafkfreund/nixos-template/blob/main/docs/HOST-TEMPLATES.md)
- [Setup guide](https://github.com/olafkfreund/nixos-template/blob/main/docs/SETUP.md)
- [GPU configuration](https://github.com/olafkfreund/nixos-template/blob/main/docs/GPU-CONFIGURATION.md)
