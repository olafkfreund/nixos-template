# Modern NixOS Configuration Template

> **⚠️ AI-Generated Content Notice**: This template was developed with AI assistance. While thoroughly tested and validated, please review configurations carefully before use, especially for production environments. Contributions and human oversight are welcome to improve the template.
>
> **Community Contributions Welcome**: If you identify any anti-patterns, improvements, or have suggestions for better NixOS practices, please contribute to our [NixOS Anti-Patterns Guide](docs/NIXOS-ANTI-PATTERNS.md). Your expertise helps make this template better for the entire NixOS community.

A modular, flake-based NixOS starter template with Home Manager integration, multi-host support, automatic GPU driver detection, and ready-made configurations for desktops, laptops, servers, virtual machines, WSL2, and macOS (nix-darwin). Clone it, copy a host template, and you have a working declarative system configuration in minutes.

**Wayland-only, three desktops:** GNOME, [Hyprland](https://hypr.land) and [niri](https://github.com/YaLTeR/niri) — each with a ready-to-copy host (`hosts/desktop-template`, `hosts/hyprland-template`, `hosts/niri-template`). There is no X11 session — XWayland is enabled so Steam, Discord and older Electron apps still run. Hyprland and niri are configured through Home Manager, so a host can override a single keybinding without replacing the whole config file.

---

## Quick Start (NixOS)

```bash
# 1. Clone the repository
git clone https://github.com/olafkfreund/nixos-template.git
cd nixos-template

# 2. Enter the dev shell (provides just, nixd, statix, deadnix, and more)
nix develop
# Running `just` with no arguments opens an interactive command menu.

# 3. Copy the desktop host template
cp -r hosts/desktop-template hosts/$(hostname)

# 4. Generate your hardware configuration
sudo nixos-generate-config --show-hardware-config \
  > hosts/$(hostname)/hardware-configuration.nix

# 5. Register the host in flake.nix
# Open flake.nix, find the "ADD YOUR OWN HOSTS HERE" block near the bottom,
# and uncomment/edit one entry:
#
#   my-desktop = flakeUtils.mkSystem {
#     hostname = "my-desktop";     # must match the hosts/ directory name
#     profile = "workstation";     # workstation, server, laptop, gaming,
#   };                             # development or minimal

# 6. Build and switch
just switch $(hostname)
```

> Need a server, laptop, VM, or gaming host? See [docs/HOST-TEMPLATES.md](docs/HOST-TEMPLATES.md) — one builder, `mkSystem`, with the machine type as a parameter.

---

## Try It First (no install required)

Build and run the bundled test VM to explore the template without changing your system:

```bash
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm
# Log in as: vm-user / nixos
```

Not on NixOS yet? See [docs/NON-NIXOS-USAGE.md](docs/NON-NIXOS-USAGE.md) for Docker-based and VM-based workflows that work on any OS, including Windows and macOS.

---

## Common Commands

Running `just` with no arguments opens the **interactive menu** — a full control panel that groups all ~100 recipes into 9 categories, shows descriptions, previews the exact command, and asks for confirmation before running anything. No flags, no memorisation required.

![Menu showcase](https://raw.githubusercontent.com/olafkfreund/nixos-template/main/site/assets/menu/showcase.gif)

For the full guide see [docs/MENU.md](docs/MENU.md). Common recipes are also callable directly:

| Command              | What it does                                      |
| -------------------- | ------------------------------------------------- |
| `just`               | Open the interactive menu (all ~100 recipes)      |
| `just switch <host>` | Build and activate configuration                  |
| `just test <host>`   | Build and activate without adding a boot entry    |
| `just boot <host>`   | Build and set as next boot, without switching now |
| `just update`        | Update all flake inputs                           |
| `just fmt`           | Format Nix, shell, Markdown, YAML, JSON           |
| `just check`         | Run `nix flake check`                             |
| `just list`          | Print every recipe (raw, no menu UI)              |

---

## Project Structure

```
nixos-template/
├── flake.nix              # Flake inputs, outputs, and nixosConfigurations
├── lib/                   # Helper functions
│   ├── flake-utils.nix    # Configuration factory (mkSystem, allConfigurations)
│   ├── deployment-images.nix  # Multi-platform image generation
│   └── darwin-configs.nix # nix-darwin helpers
├── modules/               # Shared NixOS modules (core, desktop, GPU, services…)
├── home/                  # Home Manager profiles (base, desktop, development, server)
├── hosts/                 # Per-host configurations
│   ├── desktop-template/  # Starting point for a new desktop host
│   └── …                  # Your hosts go here
└── docs/                  # Extended documentation (see below)
```

---

## Versioning

Tracks the current NixOS stable release, **nixpkgs `nixos-26.05`**, with Home Manager on the matching `release-26.05` branch. Stable gives near-complete binary cache coverage, so a first build downloads rather than compiles.

Host configurations use `system.stateVersion = "26.05"`. That value records the release a machine was _first installed_ with — it is not a "current version" field, so leave it alone when you upgrade unless the release notes tell you otherwise.

Prefer bleeding edge? Change both inputs in `flake.nix` to `nixos-unstable` and `home-manager` (master); the comment above the inputs spells it out.

---

## Documentation

Full documentation lives in [`docs/`](docs/). See [docs/README.md](docs/README.md) for the complete index. Quick links:

**Getting started**

- [docs/SETUP.md](docs/SETUP.md) — detailed first-time setup walkthrough
- [docs/HOST-TEMPLATES.md](docs/HOST-TEMPLATES.md) — all host types and flake registration
- [docs/USER-TEMPLATES.md](docs/USER-TEMPLATES.md) — Home Manager user profiles
- [docs/NON-NIXOS-USAGE.md](docs/NON-NIXOS-USAGE.md) — using the template without NixOS

**Platforms**

- [docs/WINDOWS-HOWTO.md](docs/WINDOWS-HOWTO.md) — Windows + WSL2 setup
- [docs/WSL2-CONFIGURATION.md](docs/WSL2-CONFIGURATION.md) — WSL2 NixOS configuration
- [docs/MACOS-NIXOS-GUIDE.md](docs/MACOS-NIXOS-GUIDE.md) — macOS (nix-darwin) guide
- [docs/NIX-DARWIN-GUIDE.md](docs/NIX-DARWIN-GUIDE.md) — nix-darwin reference

**Hardware & GPU**

- [docs/GPU-CONFIGURATION.md](docs/GPU-CONFIGURATION.md) — GPU driver setup (AMD/NVIDIA/Intel)
- [docs/HARDWARE-AUTO-OPTIMIZATION.md](docs/HARDWARE-AUTO-OPTIMIZATION.md) — automatic hardware detection
- [docs/ZERO-CONFIGURATION.md](docs/ZERO-CONFIGURATION.md) — zero-config hardware optimization

**Advanced & Secrets**

- [docs/AGENIX-SECRETS.md](docs/AGENIX-SECRETS.md) — age-encrypted secrets with agenix
- [docs/DEPLOYMENT-IMAGES.md](docs/DEPLOYMENT-IMAGES.md) — cloud/VM image generation
- [docs/ADVANCED-FEATURES.md](docs/ADVANCED-FEATURES.md) — overlays, custom packages, and more

**Reference**

- [docs/NIXOS-ANTI-PATTERNS.md](docs/NIXOS-ANTI-PATTERNS.md) — common mistakes and how to avoid them
- [docs/CODE-QUALITY.md](docs/CODE-QUALITY.md) — linting and formatting tools
- [docs/VALIDATION.md](docs/VALIDATION.md) — configuration validation
- [docs/CHANGELOG.md](docs/CHANGELOG.md) — release history

---

## Troubleshooting

| Problem                           | Fix                                              |
| --------------------------------- | ------------------------------------------------ |
| Build fails with evaluation error | Run `nix flake check` for details                |
| VM hangs at boot                  | Rebuild: `just test <host>` inside the VM config |
| `permission denied` errors        | Ensure your user is in the `wheel` group         |

**Getting help:**

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Options Search](https://search.nixos.org/options)
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
