# hosts/

This directory contains per-machine NixOS (and nix-darwin) configurations.

## Quick start — the one happy path

1. **Copy a template** that matches your hardware:
   ```
   cp -r hosts/desktop-template  hosts/<your-machine>
   # or laptop-template / server-template / wsl2-template
   ```
2. **Generate hardware config** on the target machine:
   ```
   nixos-generate-config --show-hardware-config > hosts/<your-machine>/hardware-configuration.nix
   ```
3. **Add your host** to `flake.nix` (follow the existing `mkSystem` call pattern).
4. **Deploy:**
   ```
   just switch <your-machine>
   ```

That's it. Edit `hosts/<your-machine>/configuration.nix` and `home.nix` for
machine-specific tweaks; shared behaviour lives in `modules/` and `home/profiles/`.

---

## Directory map

### Starting templates — copy one of these

| Directory          | Purpose                                    |
|--------------------|--------------------------------------------|
| `desktop-template` | Workstation with GUI (X11/Wayland)         |
| `laptop-template`  | Mobile laptop (power management, backlight)|
| `server-template`  | Headless server (no GUI)                   |
| `wsl2-template`    | WSL2 on Windows                            |

### Test fixtures / VM demos — leave these alone

These exist for CI validation and VM demos. Do **not** copy them as a base for
real machines; they contain minimal or synthetic hardware configs.

| Directory        | Purpose                                     |
|------------------|---------------------------------------------|
| `qemu-vm`        | QEMU guest demo (referenced by flake)       |
| `microvm`        | MicroVM demo                                |
| `desktop-test`   | CI smoke-test for desktop profile           |
| `test-workstation`| CI smoke-test for workstation profile      |
| `test-gaming`    | CI smoke-test for gaming profile            |
| `test-server`    | CI smoke-test for server profile            |

### Installer images and macOS

| Directory / prefix | Purpose                                   |
|--------------------|-------------------------------------------|
| `installer-isos/`  | NixOS installer ISO configurations       |
| `macos-vms/`       | macOS VM configs (nix-darwin)            |
| `macos-isos/`      | macOS ISO builder configs                |
| `darwin-desktop`   | nix-darwin workstation                   |
| `darwin-laptop`    | nix-darwin laptop                        |
| `darwin-server`    | nix-darwin server                        |

### Shared helpers

| File / Dir    | Purpose                                      |
|---------------|----------------------------------------------|
| `common.nix`  | Shared options imported by multiple hosts     |
| `examples/`   | Annotated example snippets (read-only)        |
