---
layout: page
title: "Features"
permalink: /features/
---

```
$ nix flake show github:olafkfreund/nixos-template
```

---

## GPU Auto-detection (AMD / NVIDIA / Intel)

Set one option and the template wires up the correct kernel modules, Mesa drivers, Vulkan layers, VA-API acceleration, and power management automatically. No more hunting through kernel params and driver names.

```nix
# In hosts/my-machine/configuration.nix
hardware.gpu.type = "amd";    # or "nvidia" or "intel" or "none"
```

Full reference: [GPU configuration](https://github.com/olafkfreund/nixos-template/blob/main/docs/GPU-CONFIGURATION.md)

---

## VM Testing — no install required

Every host configuration can be booted as a QEMU virtual machine. Use this to preview a config, run integration tests, or demonstrate the setup to others — all without touching physical hardware.

```bash
# Build and run the desktop-test VM
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm
# Login: vm-user / nixos

# Or use the just recipe for any host
just vm my-machine
```

The `vm-test` and `vm-test-config` directories contain pre-baked integration test hosts used in CI. Full reference: [VM support](https://github.com/olafkfreund/nixos-template/blob/main/docs/VM-SUPPORT.md)

---

## WSL2 — NixOS on Windows

Build a NixOS WSL2 distribution archive from the `wsl2-template` host and import it into Windows with two commands.

```bash
# Build the tarball
just build-wsl2-archive
# result/tarball/nixos-system-x86_64-linux.tar.xz

# Import on Windows (run from PowerShell or CMD)
wsl --import NixOS-Template C:\WSL\NixOS result\tarball\nixos-system-x86_64-linux.tar.xz
wsl -d NixOS-Template
```

From inside WSL2, apply updates with the normal `nixos-rebuild switch` workflow. Full reference: [WSL2 configuration](https://github.com/olafkfreund/nixos-template/blob/main/docs/WSL2-CONFIGURATION.md)

---

## macOS / nix-darwin

Three Darwin host templates cover the common Mac roles: desktop workstation, laptop, and server. Home Manager is integrated as a nix-darwin module — no separate `home-manager switch` invocation needed.

```bash
# Switch a Darwin host (after registering in flake.nix)
darwin-rebuild switch --flake .#darwin-desktop
```

The `darwin/` directory holds nix-darwin-specific modules mirroring the NixOS module layout. Full reference: [nix-darwin guide](https://github.com/olafkfreund/nixos-template/blob/main/docs/NIX-DARWIN-GUIDE.md), [macOS + NixOS guide](https://github.com/olafkfreund/nixos-template/blob/main/docs/MACOS-NIXOS-GUIDE.md)

---

## Agenix Secrets

Secrets are age-encrypted at rest and decrypted into a tmpfs at activation time. They never appear as plaintext in the Nix store or in git history. Each secret is scoped to specific SSH host keys, so only authorised machines can decrypt it.

```bash
# Set up agenix (generates secrets/secrets.nix with host keys)
just setup-secrets

# Create or edit a secret
just edit-secret my-api-key      # opens $EDITOR, encrypts on save

# Rotate encryption after adding a new machine's key
just rekey-secrets
```

Reference in your NixOS config:

```nix
age.secrets."my-api-key".file = ../secrets/my-api-key.age;
services.myservice.apiKeyFile = config.age.secrets."my-api-key".path;
```

Full reference: [Agenix secrets](https://github.com/olafkfreund/nixos-template/blob/main/docs/AGENIX-SECRETS.md)

---

## Custom Installer ISOs

Generate a bootable NixOS ISO pre-seeded with your configuration using `nixos-generators`. Boot from a USB stick to install your exact setup on bare metal.

```bash
# Build the installer ISO for the default installer profile
nix build .#nixosConfigurations.installer-isos.config.system.build.isoImage

# Or use the just recipe
just build-iso
# Outputs: result/iso/nixos-*.iso
```

Full reference: [ISO creation](https://github.com/olafkfreund/nixos-template/blob/main/docs/ISO-CREATION.md)

---

## Multi-platform Deployment Images

Produce cloud and hypervisor images from the same configuration used on bare metal. The `build-images` targets call `nixos-generators` with appropriate format flags.

```bash
just build-images
# Builds: QCOW2, raw, VirtualBox OVA, Amazon AMI (where configured)
```

Images inherit your full system configuration — same packages, services, and secrets setup as the live system. Full reference: [Deployment images](https://github.com/olafkfreund/nixos-template/blob/main/docs/DEPLOYMENT-IMAGES.md)

---

## Profile-based Home Manager

Four composable profiles eliminate copy-paste between host configs:

| Profile | Includes |
|---|---|
| `base.nix` | git, zsh/bash aliases, starship, common CLI tools |
| `desktop.nix` | GUI apps, multimedia, browser, desktop environment support |
| `development.nix` | Language toolchains, LSP servers, editors, dev tools |
| `server.nix` | Server administration, monitoring, networking tools |

```nix
# Mix and match per host
imports = [
  ../../home/profiles/base.nix
  ../../home/profiles/development.nix
];
```

Changes to a profile propagate to every host that imports it on the next `nixos-rebuild switch`.

---

## Hardware Auto-optimisation

The template includes automatic detection of CPU microcode, SSD scheduler tuning, power profiles, and kernel parameters. See [hardware auto-optimisation](https://github.com/olafkfreund/nixos-template/blob/main/docs/HARDWARE-AUTO-OPTIMIZATION.md) for the full breakdown.

---

## Desktop Environments

GNOME, KDE Plasma, and minimal setups are available as composable modules under `modules/desktop/`. Switch by changing the import in your host configuration. See [desktop environments](https://github.com/olafkfreund/nixos-template/blob/main/docs/DESKTOP-ENVIRONMENTS.md).
