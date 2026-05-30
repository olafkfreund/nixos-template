---
layout: page
title: "Usage — the just menu"
permalink: /usage/
---

`just` opens a guided control panel: browse categories, read what each action
does, then pick it. It previews the exact command and asks to confirm before
running. Zero dependencies — pure bash, works in any shell.

<video src="{{ '/assets/menu/showcase.mp4' | relative_url }}" autoplay loop muted playsinline controls></video>

![Menu showcase]({{ '/assets/menu/showcase.gif' | relative_url }})

## Quick start

```
$ nix develop      # enter the dev shell (provides just)
$ just             # open the menu
```

## How it works

- **Numbered selection** — type a number, press Enter.
- **Every item has a description** so you know what it does before picking it.
- **Command preview + confirm** — it prints `▶ just <command>` and asks `[Y/n]`
  before running anything.
- **`b`** goes back, **`q`** quits.
- The **hostname is auto-detected**; actions that need arguments prompt with
  sensible defaults.
- Colors auto-disable when piped or when `NO_COLOR` is set.

![Main menu]({{ '/assets/menu/01-main.png' | relative_url }})

## Every menu, at a glance

### Build & Apply
Switch, test, boot, build, dry-run, diff, update, and roll back your system.

![Build & Apply]({{ '/assets/menu/02-build-apply.png' | relative_url }})

### Create Host / User
Scaffold a new host from a preset or template, or apply a user/home template.

![Create Host or User]({{ '/assets/menu/03-create-host-user.png' | relative_url }})

### VMs & Testing
Build and run VM images, detect your VM/hardware, validate the MicroVM.

![VMs & Testing]({{ '/assets/menu/04-vms-testing.png' | relative_url }})

### Installer ISOs
Build minimal / desktop / preconfigured installers and write a bootable USB.

![Installer ISOs]({{ '/assets/menu/05-installer-isos.png' | relative_url }})

### Desktops
Browse and test GNOME, KDE, Hyprland, and Niri; show Niri keybindings.

![Desktops]({{ '/assets/menu/06-desktops.png' | relative_url }})

### macOS & WSL2
NixOS VMs/ISOs for Mac (UTM/QEMU) and the WSL2 distribution for Windows.

![macOS & WSL2]({{ '/assets/menu/07-macos-wsl2.png' | relative_url }})

### Quality & Format
Check, validate, format, lint, find dead code, run the pre-commit hooks.

![Quality & Format]({{ '/assets/menu/08-quality-format.png' | relative_url }})

### Secrets
Set up, list, edit, validate, and re-key agenix-encrypted secrets.

![Secrets]({{ '/assets/menu/09-secrets.png' | relative_url }})

### Maintenance & Info
System info, flake inputs, generations, store cleanup, and the dev shell.

![Maintenance & Info]({{ '/assets/menu/10-maintenance-info.png' | relative_url }})

## Prefer the command line?

The menu is just a friendly front-end — everything is still a plain recipe:

```
$ just list                 # show every recipe (raw)
$ just switch               # build & activate this host
$ just build-iso-minimal    # run a recipe directly
$ just new-host my-pc workstation
```

Full reference:
[docs/MENU.md](https://github.com/olafkfreund/nixos-template/blob/main/docs/MENU.md).
