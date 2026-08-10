# Run downloaded binaries that were not built for NixOS.
#
# This is the single most-asked NixOS question -- it is question 10 in the
# official FAQ ("I've downloaded a binary, but I can't run it, what can I do?").
#
# Why it happens: every dynamically linked ELF hardcodes the path to its
# interpreter, almost always /lib64/ld-linux-x86-64.so.2. On NixOS that path
# does not exist -- the loader lives in the store under /nix/store/...-glibc.
# So the binary fails with a bewildering "No such file or directory" even
# though the file is plainly right there.
#
# nix-ld installs a small shim at the expected path which re-execs the real
# loader with a library path assembled from `libraries` below. That covers
# most prebuilt tooling: language version managers (nvm, rustup, pyenv),
# vendor SDKs, AppImages, VS Code remote/devcontainer servers, and the
# language servers editors download at runtime.
#
# Reach for a proper derivation or a devShell when you are packaging something
# for real. nix-ld is for the binary someone handed you.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.core.nix-ld;
in
{
  options.modules.core.nix-ld = {
    enable = lib.mkEnableOption "nix-ld, so unpatched dynamic binaries run" // {
      default = true;
    };

    libraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        # The floor: nearly every prebuilt binary wants these.
        stdenv.cc.cc.lib # libstdc++
        zlib
        openssl
        curl
        libxml2
        icu

        # Anything that draws a window or plays a sound.
        glib
        gtk3
        cairo
        pango
        gdk-pixbuf
        alsa-lib
        libGL
        fontconfig
        freetype
        dbus
        expat
        nspr
        nss

        # Electron and headless Chromium (VS Code servers, Playwright, ...).
        at-spi2-atk
        at-spi2-core
        cups
        libdrm
        libxkbcommon
        mesa
        libgbm
        systemd
        # Top-level names, not the `xorg.*` set -- that set is deprecated in
        # nixpkgs and referencing it prints a warning on every rebuild.
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
      ];
      description = ''
        Libraries made visible to non-NixOS binaries.

        Still getting `error while loading shared libraries: libfoo.so.1`?
        Find its owner with `nix-locate libfoo.so.1` (from the `nix-index`
        package) and append it here rather than replacing the list:

        ```nix
        modules.core.nix-ld.libraries = options.modules.core.nix-ld.libraries.default
          ++ [ pkgs.libfoo ];
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      inherit (cfg) libraries;
    };
  };
}
