---

## layout: page title: "Usage — the just menu" permalink: /usage/

Run `just` from the repo root and a guided, category-based menu opens in your terminal. Browse categories, read what each recipe does, pick one — it shows you the exact command and asks for confirmation before running anything. No extra tools required beyond the dev shell.

<video src="{{ '/assets/menu/showcase.mp4' | relative_url }}" autoplay loop muted playsinline controls style="max-width:100%;border-radius:8px"></video>

!\[Menu showcase\]({{ '/assets/menu/showcase.gif' | relative_url }})

---

## Quick start

```bash
# Enter the dev shell (provides just, nixpkgs-fmt, statix, deadnix, …)
nix develop

# Open the interactive menu
just
```

---

## How it works

1. **Category list** — the top-level menu groups every recipe into logical sections (Build & Apply, Secrets, Maintenance, …).
1. **Item descriptions** — selecting a category shows each recipe with a one-line explanation so you know what it does before you commit.
1. **Command preview + confirm** — after you pick a recipe, the menu prints the exact shell command it will run and prompts `Run? [Y/n]`. Press Enter to accept or `n` to cancel.
1. **Navigation** — press `b` to go back one level, `q` to quit.
1. **Host auto-detection** — recipes that operate on a specific host default to the current machine's hostname; you can override at the prompt.
1. **Argument prompts** — recipes that need parameters (e.g. a host name or VM count) prompt with a sensible default in brackets.

!\[Main menu\]({{ '/assets/menu/01-main.png' | relative_url }})

---

## Every menu, at a glance

### Build & Apply

Apply your NixOS configuration, test without switching, or build without activating — covers the full `nixos-rebuild` workflow for local and remote hosts.

!\[Build & Apply\]({{ '/assets/menu/02-build-apply.png' | relative_url }})

### Create Host / User

Scaffold a new host directory from a template or add a new user profile in seconds, with interactive prompts filling in names and roles.

!\[Create Host / User\]({{ '/assets/menu/03-create-host-user.png' | relative_url }})

### VMs & Testing

Boot any host configuration as a QEMU VM for a live preview, run the NixOS test suite, or build a VM image — without touching your running system.

!\[VMs & Testing\]({{ '/assets/menu/04-vms-testing.png' | relative_url }})

### Installer ISOs

Generate a bootable NixOS ISO pre-seeded with your configuration via `nixos-generators`, ready to burn or `dd` to a USB drive.

!\[Installer ISOs\]({{ '/assets/menu/05-installer-isos.png' | relative_url }})

### Desktops

Switch or rebuild desktop-specific configurations (GNOME, Hyprland, …) and manage display-manager settings without editing files by hand.

!\[Desktops\]({{ '/assets/menu/06-desktops.png' | relative_url }})

### macOS & WSL2

Build a NixOS WSL2 tarball for Windows import, or rebuild nix-darwin configurations on Apple Silicon and Intel Macs.

!\[macOS & WSL2\]({{ '/assets/menu/07-macos-wsl2.png' | relative_url }})

### Quality & Format

Run `nixpkgs-fmt`, `statix`, and `deadnix` in one step to keep code clean, or check the entire flake for evaluation errors.

!\[Quality & Format\]({{ '/assets/menu/08-quality-format.png' | relative_url }})

### Secrets

Rekey agenix secrets, add new secret files, or rotate keys — all through guided prompts that handle the age encryption details for you.

!\[Secrets\]({{ '/assets/menu/09-secrets.png' | relative_url }})

### Maintenance & Info

Show system info, garbage-collect old generations, update flake inputs, or check which hosts are defined in the flake — housekeeping made easy.

!\[Maintenance & Info\]({{ '/assets/menu/10-maintenance-info.png' | relative_url }})

---

## Prefer the command line?

```bash
# List every available recipe with descriptions
just list

# Run a recipe directly, skipping the menu
just switch my-machine
just build-vm desktop-test
just update
```

Full recipe reference and advanced usage: [docs/MENU.md on GitHub](https://github.com/olafkfreund/nixos-template/blob/main/docs/MENU.md)
