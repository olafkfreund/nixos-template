---

## layout: home title: "NixOS Template"

```
$ nixos-rebuild switch --flake github:olafkfreund/nixos-template#your-machine
```

A production-ready, flake-based NixOS configuration template. Stop copy-pasting configs — inherit a curated foundation and override only what your machine needs.

---

## See it in action

!\[The just menu\]({{ '/assets/menu/showcase.gif' | relative_url }})

A single `just` command opens a guided menu covering every workflow — build, test, secrets, VMs, ISOs, and more. \[Learn how it works.\]({{ '/usage/' | relative_url }})

---

## What you get

- **Flake-first** — fully reproducible with `flake.lock`; experimental features enabled out of the box
- **Profile-based Home Manager** — `base`, `desktop`, `development`, and `server` profiles compose cleanly; no copy-paste between hosts
- **Multi-host templates** — `desktop-template`, `laptop-template`, `server-template`, `wsl2-template`, `darwin-desktop`, `darwin-laptop`, `darwin-server` ready to clone
- **GPU auto-detection** — AMD, NVIDIA, and Intel graphics configured declaratively; switch by setting `hardware.gpu.type`
- **VM testing** — spin up any host config as a QEMU VM in seconds; no install required
- **WSL2** — build a NixOS WSL2 tarball and import it on Windows with a single command
- **macOS / nix-darwin** — Darwin host templates for Apple Silicon and Intel Macs; Home Manager included
- **Agenix secrets** — age-encrypted secrets wired into systemd services; zero plaintext in the Nix store
- **Custom installer ISOs** — generate bootable NixOS ISOs pre-seeded with your config via `nixos-generators`
- **Multi-platform deployment images** — produce AMIs, QCOW2, raw, VirtualBox, and more with `just build-images`

---

## Quick start

```bash
# 1. Clone and enter the dev shell (provides nixpkgs-fmt, statix, deadnix, just, …)
git clone https://github.com/olafkfreund/nixos-template.git
cd nixos-template
nix develop

# 2. Copy the desktop template to your hostname
cp -r hosts/desktop-template hosts/my-machine
# Edit hosts/my-machine/configuration.nix and home.nix to taste

# 3. Generate hardware config on the target machine
sudo nixos-generate-config --show-hardware-config > hosts/my-machine/hardware-configuration.nix

# 4. Register the host in flake.nix (see the existing entries for the pattern),
#    then build and switch
just switch my-machine
```

---

## Try it in a VM — no install required

```bash
# Build and run the desktop-test VM (QEMU)
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm
# Login: vm-user / nixos
```

The VM boots with GNOME, all profile packages, and the full Home Manager configuration — a live preview of what you'll get after `nixos-rebuild switch`.

---

## Repository

```
$ xdg-open https://github.com/olafkfreund/nixos-template
```

- [GitHub repository](https://github.com/olafkfreund/nixos-template)
- [Host templates guide](https://github.com/olafkfreund/nixos-template/blob/main/docs/HOST-TEMPLATES.md)
- [VM support](https://github.com/olafkfreund/nixos-template/blob/main/docs/VM-SUPPORT.md)
- [WSL2 configuration](https://github.com/olafkfreund/nixos-template/blob/main/docs/WSL2-CONFIGURATION.md)
- [macOS / nix-darwin guide](https://github.com/olafkfreund/nixos-template/blob/main/docs/NIX-DARWIN-GUIDE.md)
- [Agenix secrets](https://github.com/olafkfreund/nixos-template/blob/main/docs/AGENIX-SECRETS.md)
- [ISO creation](https://github.com/olafkfreund/nixos-template/blob/main/docs/ISO-CREATION.md)
- [Deployment images](https://github.com/olafkfreund/nixos-template/blob/main/docs/DEPLOYMENT-IMAGES.md)
