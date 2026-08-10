# FAQ

The questions that actually come up, in roughly the order people hit them.

For anything not here, the [official NixOS FAQ](https://wiki.nixos.org/wiki/FAQ)
is thorough, and [NixOS Discourse](https://discourse.nixos.org/) answers real
questions quickly.

---

## I downloaded a binary and it won't run

You get `No such file or directory` for a file that is plainly there.

Every dynamically linked Linux binary hardcodes the path of its interpreter,
almost always `/lib64/ld-linux-x86-64.so.2`. That path does not exist on NixOS
— the loader lives in the Nix store. The kernel reports the _missing loader_ as
the missing file, which is why the error names a file that exists.

This template enables [`nix-ld`](https://github.com/nix-community/nix-ld) by
default, which puts a shim at the expected path. Most prebuilt tooling then
works: `rustup`, `nvm`, vendor SDKs, AppImages, the server VS Code downloads
when you connect to a remote.

Still failing with `error while loading shared libraries: libfoo.so.1`? The
loader ran; a library is missing. Add it:

```nix
modules.core.nix-ld.libraries =
  options.modules.core.nix-ld.libraries.default ++ [ pkgs.libfoo ];
```

Find which package owns a library with `nix-locate libfoo.so.1` (from the
`nix-index` package).

For something you use daily, a proper derivation or a `devShell` is better.
`nix-ld` is for the binary someone handed you.

---

## Does this package go in `configuration.nix` or `home.nix`?

- `environment.systemPackages` — everyone on the machine, including root.
  System tools, anything a rescue shell needs, anything a system service uses.
- `home.packages` — just you. Your editor, your CLI tools, your applications.

**When unsure, put it in `home.nix`.** It is the smaller blast radius, and
moving it later is a two-line change.

Do not put the same package in both. It is not an error, but you will end up
with two copies in your PATH and confusion about which one you are running.

---

## Why doesn't my change take effect?

**Did you commit it?** Flakes only see files tracked by git. A brand new file
that is untracked is invisible to the build — and the error usually mentions
something entirely unrelated.

```bash
git add -A
```

This catches everyone at least once, usually while adding their first module.

---

## Should I change `system.stateVersion`?

No.

It is not a "which NixOS version am I on" field. It records the release the
machine was **first installed** with, so that stateful services (databases,
mail spools) know which on-disk format to expect. Changing it does not upgrade
anything; it just tells PostgreSQL you have already migrated when you have not.

Leave it at the value it was created with, forever, unless release notes tell
you otherwise. Upgrading NixOS means changing the `nixpkgs` input, not this.

`home.stateVersion` follows the same rule.

---

## How do I upgrade?

```bash
just update              # updates flake.lock
just switch my-machine   # builds and activates
```

`nix flake update` bumps every input to its latest commit. To move to a new
NixOS release, change the branch in `flake.nix` (`nixos-26.05` →
`nixos-26.11`) along with the matching `home-manager` release, then update.

Read the release notes first. Leave `stateVersion` alone.

---

## My disk is full

Every build you have ever made is still in `/nix/store`. Unchecked, this
reaches hundreds of gigabytes.

This template enables weekly garbage collection. To run it now:

```bash
sudo nix-collect-garbage -d      # delete everything not currently referenced
nix store optimise               # hardlink identical files
```

`-d` also removes old _generations_, so you lose the ability to roll back to
them. That is usually what you want; just know it is the trade.

---

## Something broke. How do I get back?

At the boot menu, pick the previous generation. Nothing is lost — old
generations stay bootable until garbage collected.

From a running system:

```bash
sudo nixos-rebuild switch --rollback
```

To try something risky without needing the boot menu at all, use
`nixos-rebuild test` — it activates without touching the boot default, so a
reboot returns you to the last known-good system.

For changes that might stop the machine reaching a login prompt (GPU drivers,
display managers), a [specialisation](../hosts/examples/specialisations.nix)
gives you a second boot entry to fall back to.

---

## How do I find a package or an option?

- Packages: <https://search.nixos.org/packages>
- Options: <https://search.nixos.org/options> — the one you will use most
- Home Manager options: <https://nix-community.github.io/home-manager/options.xhtml>

From the shell:

```bash
nix search nixpkgs firefox
man configuration.nix
```

In your editor, `nixd` (in this repo's dev shell) gives option completion and
inline documentation, which beats all of the above.

---

## `Package X has an unfree license`

```nix
nixpkgs.config.allowUnfree = true;
```

Or for one package only:

```nix
nixpkgs.config.allowUnfreePredicate =
  pkg: builtins.elem (lib.getName pkg) [ "steam" "discord" ];
```

---

## Can I just `nix-env -i` something?

You can, and you will regret it.

`nix-env` installs into a per-user profile that no configuration file
describes. It survives rebuilds, it is invisible to your flake, it will not
appear on another machine, and when something breaks six months later there is
nothing to read. It defeats the reason to run NixOS.

To try something for one shell session:

```bash
nix shell nixpkgs#cowsay
```

Gone when you close the shell. That is the right tool for "I just want to look
at it".

---

## How do I set up a development environment?

Not with system packages. Per-project, with a `flake.nix` in the project:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [ python313 uv ruff ];
      };
    };
}
```

`nix develop` enters it. Add [direnv](https://direnv.net/) with `nix-direnv`
and it activates automatically when you `cd` in.

This keeps each project's toolchain with the project, and keeps two projects
needing different versions from fighting.

---

## `pip install` / `npm -g` fails

Same root cause as the binary question above: prebuilt wheels and native node
modules ship compiled `.so` files that expect FHS paths.

- Python: use `uv` or a `devShell` with the packages you need, or `nix-ld`
  for wheels.
- Node: usually fine; native modules may need `nix-ld`.
- Rust/Go: build from source, so they mostly just work.

---

## Black screen after enabling NVIDIA

The most common first-boot failure on this hardware. Check in order:

1. `nixpkgs.config.allowUnfree = true` — the driver is unfree.
1. `services.xserver.videoDrivers = [ "nvidia" ];` — required even on Wayland.
1. `hardware.nvidia.modesetting.enable = true;`
1. On a laptop with hybrid graphics, set `hardware.nvidia.prime.*BusId` from
   `lspci | grep -E 'VGA|3D'` (`01:00.0` becomes `PCI:1:0:0`).

Boot the previous generation to get back. See
[GPU-CONFIGURATION.md](GPU-CONFIGURATION.md) and the
[NixOS wiki NVIDIA page](https://wiki.nixos.org/wiki/NVIDIA).

---

## Can I encrypt my disk?

Yes, but decide before you install — you cannot convert a running system.

See [DISK-SETUP.md](DISK-SETUP.md) and
[`hosts/examples/disko-luks-btrfs.nix`](../hosts/examples/disko-luks-btrfs.nix).

---

## Do I have to fork this whole repo?

No, and for a first configuration you probably should not — 25 hosts and a
preset system is a lot to inherit on day one.

```bash
nix flake init -t github:olafkfreund/nixos-template#minimal
nix flake init -t github:olafkfreund/nixos-template#desktop
```

Four or five short files in your own repository, which you can read end to end.
Come back here for modules to copy when you want them.

---

## Where do secrets go?

Never in a `.nix` file. Everything in the Nix store is world-readable, and
`builtins.readFile` on a secret puts it there permanently.

Use [agenix](AGENIX-SECRETS.md) — age-encrypted files committed to the repo,
decrypted at activation into `/run/agenix`. Pass services the _path_
(`passwordFile`), never the value.

---

## Is NixOS a good first Linux distribution?

Honestly: no, unless you enjoy reading documentation.

Everything you already know about installing software is wrong here, and the
error messages are unusually poor at telling you why. What you get for that is
a machine you can rebuild exactly, on any hardware, years later — which is
worth a great deal once you have it.

If you are on the fence, run it in a VM first:

```bash
nix build .#nixosConfigurations.desktop-test.config.system.build.vm
./result/bin/run-desktop-test-vm     # login: vm-user / nixos
```
