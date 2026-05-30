---
layout: home
title: "NixOS Template"
---

<div class="hero">
<pre style="color:var(--accent);text-shadow:var(--glow)">
 _ __ (_)_ __ ___  ___    _ _____ ___ _ __  _ __  | |__ _| |_ ___
| '_ \| | \ / _ \/ __|  | __/ -_) '  \| '_ \| / _` |  _/ -_)
|_| |_|_/_\_\___/\___|   \__\___|_|_|_| .__/|_\__,_|\__\___|
                                      |_|  NixOS 26.05
</pre>

# A NixOS config you actually want to start from

Flake-based, profile-driven, multi-host. Stop copy-pasting configs — inherit a
curated foundation and override only what your machine needs.
</div>

<div class="btn-row">
<a class="btn" href="{{ '/getting-started/' | relative_url }}">get started</a>
<a class="btn" href="{{ '/usage/' | relative_url }}">the menu</a>
<a class="btn" href="{{ '/documentation/' | relative_url }}">docs</a>
<a class="btn" href="https://github.com/olafkfreund/nixos-template">github</a>
</div>

## ▸ see it in action

`just` opens a guided control panel — browse, read, pick. It previews the
command and confirms before running.

<video src="{{ '/assets/menu/showcase.mp4' | relative_url }}" autoplay loop muted playsinline controls></video>

![The just menu]({{ '/assets/menu/showcase.gif' | relative_url }})

## ▸ what you get

<div class="feature-grid">
<div class="card"><b>Flake-first</b><p>Fully reproducible with flake.lock — one command to build any host.</p></div>
<div class="card"><b>Profile-based Home Manager</b><p>base · desktop · development · server profiles compose cleanly.</p></div>
<div class="card"><b>Multi-host templates</b><p>desktop · laptop · server · WSL2 · macOS — ready to clone.</p></div>
<div class="card"><b>GPU auto-detection</b><p>AMD, NVIDIA, and Intel configured declaratively.</p></div>
<div class="card"><b>VM testing</b><p>Spin up any host as a QEMU VM in seconds — no install.</p></div>
<div class="card"><b>Installer ISOs</b><p>Build bootable NixOS installers pre-seeded with your config.</p></div>
<div class="card"><b>agenix secrets</b><p>age-encrypted secrets wired into systemd — zero plaintext in the store.</p></div>
<div class="card"><b>The just menu</b><p>A guided, zero-dependency control panel over every task.</p></div>
</div>

## ▸ quick start

```
$ nix develop                                   # enter the dev shell
$ cp -r hosts/desktop-template hosts/$(hostname)
$ sudo nixos-generate-config --show-hardware-config \
    > hosts/$(hostname)/hardware-configuration.nix
$ just switch                                    # build & activate
```

Just want to look first? Boot it in a VM, no install:

```
$ nix build .#nixosConfigurations.desktop-test.config.system.build.vm
$ ./result/bin/run-desktop-test-vm               # login: vm-user / nixos
```

## ▸ screenshots

<div class="shot-gallery">
<figure><a href="{{ '/assets/menu/01-main.png' | relative_url }}"><img src="{{ '/assets/menu/01-main.png' | relative_url }}" alt="Main menu"></a><figcaption>The control panel</figcaption></figure>
<figure><a href="{{ '/assets/menu/02-build-apply.png' | relative_url }}"><img src="{{ '/assets/menu/02-build-apply.png' | relative_url }}" alt="Build & Apply"></a><figcaption>Build &amp; Apply</figcaption></figure>
<figure><a href="{{ '/assets/menu/05-installer-isos.png' | relative_url }}"><img src="{{ '/assets/menu/05-installer-isos.png' | relative_url }}" alt="Installer ISOs"></a><figcaption>Installer ISOs</figcaption></figure>
</div>

<p style="margin-top:1.4rem"><a class="btn" href="{{ '/usage/' | relative_url }}">explore the full menu</a></p>
