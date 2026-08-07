---
layout: page
title: "Get Started"
permalink: /getting-started/
description: "From a fresh clone to a running NixOS system, with every command verified against the repository."
---

From a fresh clone to a running system. Every command and option on this page is
checked against the repository — if it is written here, it exists.

<div class="note">
<b>Just want to look?</b> Jump to <a href="#try-it-in-a-vm-first">Try it in a VM
first</a> — it boots a full desktop without touching your machine.
</div>

---

## Prerequisites

- **Nix with flakes enabled.** Add `experimental-features = nix-command flakes`
  to `/etc/nix/nix.conf`, or use the
  [Determinate Systems installer](https://install.determinate.systems/), which
  enables them by default.
- **git**
- Building a NixOS _host_ requires NixOS. On macOS or another Linux you can
  still use the dev shell, the VM, and nix-darwin — see
  [NON-NIXOS-USAGE]({{ '/docs/NON-NIXOS-USAGE.html' | relative_url }}).

This template tracks **NixOS 26.05** (stable), so nearly everything comes from
the binary cache rather than being compiled locally.

---

<ol class="steps">

<li markdown="1">
### Clone and enter the dev shell

```bash
git clone https://github.com/olafkfreund/nixos-template.git
cd nixos-template
nix develop
```

The shell provides `just`, `nixfmt`, `nixd` (Nix LSP), `statix`, `deadnix`,
`treefmt`, `shellcheck`, `shfmt`, `pre-commit`, `nh`, plus `pciutils`/`lshw`
for hardware detection.

Running `just` with no arguments opens an interactive menu over every recipe.
</li>

<li markdown="1">
### Pick a starting point

| Template                 | Use case                                   |
| ------------------------ | ------------------------------------------ |
| `hosts/desktop-template` | Workstation, full Home Manager profiles    |
| `hosts/laptop-template`  | Desktop plus power management and TLP      |
| `hosts/server-template`  | Headless, SSH-hardened, server profile     |
| `hosts/wsl2-template`    | NixOS inside Windows Subsystem for Linux 2 |
| `hosts/darwin-desktop`   | macOS workstation via nix-darwin           |
| `hosts/darwin-laptop`    | macOS laptop via nix-darwin                |
| `hosts/darwin-server`    | macOS server via nix-darwin                |

```bash
cp -r hosts/desktop-template hosts/my-machine
```

</li>

<li markdown="1">
### Generate your hardware configuration

Run this **on the machine you are configuring** — it describes that machine's
disks, filesystems and kernel modules, so it is never copied between hosts.

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/my-machine/hardware-configuration.nix
```

</li>

<li markdown="1">
### Customise the host

Edit `hosts/my-machine/configuration.nix`:

```nix
networking.hostName = "my-machine";

# GPU support. autoDetect is on by default and enables the right
# vendor module for you; set the profile to match your workload.
modules.hardware.gpu = {
  autoDetect = true;
  profile = "desktop";        # desktop | gaming | ai-compute | server-compute
};

environment.systemPackages = with pkgs; [ vim ];
```

To pin a vendor explicitly instead of relying on detection:

```nix
modules.hardware.gpu.nvidia = {
  enable = true;
  driver = "production";      # stable | beta | production
};                            # legacy_470 | legacy_390 | open
```

Then edit `hosts/my-machine/home.nix` to choose Home Manager profiles:

```nix
imports = [
  ../../home/profiles/base.nix        # git, shell, core CLI tools
  ../../home/profiles/desktop.nix     # GUI applications
  ../../home/profiles/development.nix # languages and dev tooling
];
```

See [GPU-CONFIGURATION]({{ '/docs/GPU-CONFIGURATION.html' | relative_url }}) for the
full set of GPU options.
</li>

<li markdown="1">
### Register the host in flake.nix

Open `flake.nix` and find the **`ADD YOUR OWN HOSTS HERE`** block inside
`nixosConfigurations`. Uncomment an entry and edit it:

```nix
my-machine = flakeUtils.mkSystem {
  hostname = "my-machine";     # must match the hosts/ directory name
  profile = "workstation";     # workstation | server | laptop
};                             # gaming | development | minimal
```

<div class="note">
<b>Why <code>mkSystem</code>?</b> It imports your
<code>configuration.nix</code> and wires in Home Manager, agenix and the flake
metadata module — so you never repeat that boilerplate. There is one builder;
the machine type is a parameter. See
<a href="{{ '/docs/HOST-TEMPLATES.html' | relative_url }}">HOST-TEMPLATES</a>.
</div>
</li>

<li markdown="1">
### Check before you switch

```bash
nix flake check     # evaluates every host and runs the lint gates
```

Then dry-run your specific host to see exactly what would be built:

```bash
nix build .#nixosConfigurations.my-machine.config.system.build.toplevel --dry-run
```

</li>

<li markdown="1">
### Build and activate

```bash
just test my-machine     # activate now, no bootloader entry — safest first try
just switch my-machine   # activate and make it the default boot entry
```

`just test` is the one to reach for first: if something is wrong, reboot and
you are back where you started.
</li>

</ol>

---

## Try it in a VM first

No install, no risk — this boots a complete desktop host in QEMU:

```bash
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm
# login: vm-user / nixos
```

Any host can be built this way; swap `desktop-test` for `test-server`,
`test-gaming`, or your own host name.

---

## Everyday commands

Run `just` on its own for the interactive menu, or call recipes directly:

| Command                     | What it does                                           |
| --------------------------- | ------------------------------------------------------ |
| `just switch [host]`        | Build and activate, and set as default boot entry      |
| `just test [host]`          | Activate without adding a boot entry                   |
| `just build [host]`         | Build only, do not activate                            |
| `just boot [host]`          | Stage for next boot without switching now              |
| `just update`               | Update all flake inputs                                |
| `just update-switch [host]` | Update inputs, then switch                             |
| `just check`                | `nix flake check`                                      |
| `just fmt`                  | Format Nix, shell, Markdown, YAML and JSON via treefmt |
| `just lint`                 | `statix check`                                         |
| `just validate`             | check → lint → format-check → dead-code                |
| `just test-vm [host]`       | Build and boot a host as a QEMU VM                     |
| `just list-vms`             | Show the VM configurations available                   |
| `just build-wsl2-archive`   | Build a WSL2 import tarball                            |
| `just setup-secrets`        | Initialise agenix secret management                    |
| `just edit-secret SECRET`   | Create or edit an encrypted secret                     |
| `just list-secrets`         | List age-encrypted secrets                             |
| `just rekey-secrets`        | Re-encrypt after adding a new age key                  |

`just list` prints all ~100 recipes without the menu UI.

---

## Keeping it green

```bash
just validate
```

This runs `nix flake check`, `statix`, the formatting check and `deadnix`. All
of them pass on a clean clone, and CI enforces the same set — so if `validate`
is green locally, your pull request will be too.

---

## Where to go next

- [Code Showcase]({{ '/showcase/' | relative_url }}) — how the pieces fit together
- [Usage & the just menu]({{ '/usage/' | relative_url }})
- [Features overview]({{ '/docs/FEATURES-OVERVIEW.html' | relative_url }})
- [Host templates]({{ '/docs/HOST-TEMPLATES.html' | relative_url }})
- [Secrets with agenix]({{ '/docs/AGENIX-SECRETS.html' | relative_url }})
- [WSL2 configuration]({{ '/docs/WSL2-CONFIGURATION.html' | relative_url }})

<div class="btn-row">
<a class="btn btn-primary" href="{{ '/showcase/' | relative_url }}">see the code</a>
<a class="btn" href="{{ '/documentation/' | relative_url }}">all documentation</a>
</div>
