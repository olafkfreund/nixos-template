#!/usr/bin/env bash
# NixOS Template — interactive, menu-driven control panel.
#
# A friendly front-end over the justfile: browse grouped categories, read what
# each action does, then pick it. Zero dependencies (pure bash + `just`), so it
# works in any shell without fzf/gum/python.
#
# Launched by `just`, `just menu`, or `just m`. Run a recipe directly anytime
# with `just <recipe>` — see `just list`.

# Menu variables (h, p, t, de, a, f, d, s) are assigned dynamically by ask()
# via `printf -v`, which shellcheck cannot trace.
# shellcheck disable=SC2154

set -uo pipefail

# Run from the repo root (this script lives in scripts/).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# ----- colors (disabled when not a tty or NO_COLOR is set) -----
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  G=$'\e[38;5;114m' # green accent
  B=$'\e[1;37m'     # bright label
  D=$'\e[2;37m'     # dim description
  Y=$'\e[38;5;179m' # yellow
  R=$'\e[0m'        # reset
else
  G="" B="" D="" Y="" R=""
fi

HOST="$(hostname 2>/dev/null || echo nixos)"

banner() {
  clear 2>/dev/null || true
  printf '%s' "$G"
  cat <<'EOF'
  ╔═══════════════════════════════════════════════════════════╗
  ║   ❯ NixOS Template — Control Panel                         ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
  printf '%s' "$R"
  printf "  ${D}host: ${R}${Y}%s${R}   ${D}repo: %s${R}\n\n" "$HOST" "$ROOT"
}

# choose "Title" "label|description" ...  -> sets REPLY_IDX (0-based); returns
# 0 on pick, 255 on back/quit handled internally.
REPLY_IDX=-1
choose() {
  local title="$1"
  shift
  local entries=("$@") ans i label desc
  while true; do
    banner
    printf "  ${B}%s${R}\n\n" "$title"
    i=1
    for e in "${entries[@]}"; do
      label="${e%%|*}"
      desc="${e#*|}"
      printf "   ${G}%2d${R})  ${B}%-24s${R} ${D}%s${R}\n" "$i" "$label" "$desc"
      i=$((i + 1))
    done
    printf "\n   %s[b]%s back    %s[q]%s quit\n\n" "$D" "$R" "$D" "$R"
    read -rp "  ❯ select: " ans || {
      echo
      exit 0
    }
    case "$ans" in
    q | Q)
      clear 2>/dev/null || true
      exit 0
      ;;
    b | B)
      REPLY_IDX=-1
      return 1
      ;;
    '') continue ;;
    *)
      if [[ $ans =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le "${#entries[@]}" ]; then
        REPLY_IDX=$((ans - 1))
        return 0
      fi
      ;;
    esac
  done
}

# ask VAR "Prompt" "default"  -> reads into VAR, falling back to default
ask() {
  local __var="$1" prompt="$2" def="${3:-}" input
  if [ -n "$def" ]; then
    read -rp "  ❯ ${prompt} [${Y}${def}${R}]: " input
  else
    read -rp "  ❯ ${prompt}: " input
  fi
  printf -v "$__var" '%s' "${input:-$def}"
}

# run <just-args...>  -> preview the command, confirm, execute, pause
run() {
  printf "\n  ${D}▶ just %s${R}\n" "$*"
  local c
  read -rp "  ❯ run this? [${G}Y${R}/n] " c
  case "$c" in
  n | N) return ;;
  esac
  echo
  just "$@"
  printf "\n  %s— press Enter to return to the menu —%s" "$D" "$R"
  read -r _ || true
}

cat_build() {
  while choose "🚀  Build & Apply" \
    "switch|Build & activate the configuration now (uses sudo)" \
    "test|Activate temporarily — not kept after reboot" \
    "boot|Set as the next boot, don't activate now" \
    "build|Build only, don't activate anything" \
    "dry-run|Preview what would be built/changed" \
    "diff|Build, then diff the closure vs the running system" \
    "update|Update flake inputs (refresh flake.lock)" \
    "update + switch|Update inputs, then rebuild & activate" \
    "rollback (list gens)|List system generations to roll back to"; do
    case "$REPLY_IDX" in
    0)
      ask h "hostname" "$HOST"
      run switch "$h"
      ;;
    1)
      ask h "hostname" "$HOST"
      run test "$h"
      ;;
    2)
      ask h "hostname" "$HOST"
      run boot "$h"
      ;;
    3)
      ask h "hostname" "$HOST"
      run build "$h"
      ;;
    4)
      ask h "hostname" "$HOST"
      run dry-run "$h"
      ;;
    5)
      ask h "hostname" "$HOST"
      run diff "$h"
      ;;
    6) run update ;;
    7)
      ask h "hostname" "$HOST"
      run update-switch "$h"
      ;;
    8) run list-generations ;;
    esac
  done
}

cat_create() {
  while choose "🆕  Create a Host or User" \
    "list presets|Show the available host presets + details" \
    "new host (preset)|Generate a host from a preset (modern)" \
    "init host|Scaffold a host from the example template" \
    "init VM host|Create a VM-optimized host config" \
    "list user templates|Show the available user/home templates" \
    "init user|Apply a user template to a host's home.nix"; do
    case "$REPLY_IDX" in
    0) run list-presets ;;
    1)
      ask h "new hostname" ""
      ask p "preset (workstation/laptop/server/gaming/vm-guest)" "workstation"
      [ -n "$h" ] && run new-host "$h" "$p"
      ;;
    2)
      ask h "new hostname" ""
      [ -n "$h" ] && run init-host "$h"
      ;;
    3)
      ask h "new hostname" ""
      ask t "vm type (auto/qemu/virtualbox/vmware/hyperv)" "auto"
      [ -n "$h" ] && run init-vm "$h" "$t"
      ;;
    4) run list-users ;;
    5)
      ask h "hostname" "$HOST"
      ask t "template (user/developer/gamer/minimal/server)" "developer"
      run init-user "$h" "$t"
      ;;
    esac
  done
}

cat_vm() {
  while choose "🖥️   VMs & Testing" \
    "list VMs|Show available VM configurations" \
    "build VM image|Build a runnable QEMU VM image" \
    "test VM|Test-build a VM host config" \
    "detect VM|Detect the virtualization environment" \
    "detect hardware|Detect hardware type (laptop/desktop/…)" \
    "test microvm|Validate the MicroVM configuration"; do
    case "$REPLY_IDX" in
    0) run list-vms ;;
    1)
      ask h "host" "desktop-test"
      run build-vm-image "$h"
      ;;
    2)
      ask h "host" "desktop-test"
      run test-vm "$h"
      ;;
    3) run detect-vm ;;
    4) run detect-hardware ;;
    5) run test-microvm ;;
    esac
  done
}

cat_iso() {
  while choose "💿  Installer ISOs" \
    "list ISOs|Show ISO types + sizes + features" \
    "build minimal ISO|Lightweight CLI installer (~800MB)" \
    "build desktop ISO|GNOME graphical installer (~2.5GB)" \
    "build preconfigured|Installer with all templates (~1.5GB)" \
    "build all ISOs|Build every installer type" \
    "ISO workflow help|Step-by-step ISO → USB → install guide" \
    "create bootable USB|Write a built ISO to a USB device (ERASES it)"; do
    case "$REPLY_IDX" in
    0) run list-isos ;;
    1) run build-iso-minimal ;;
    2) run build-iso-desktop ;;
    3) run build-iso-preconfigured ;;
    4) run build-all-isos ;;
    5) run iso-workflow ;;
    6)
      ask f "iso filename (in result/iso/)" ""
      ask d "device (e.g. /dev/sdX)" ""
      [ -n "$f" ] && [ -n "$d" ] && run create-bootable-usb "$f" "$d"
      ;;
    esac
  done
}

cat_desktop() {
  while choose "🎨  Desktop Environments" \
    "list desktops|Show available desktops (GNOME/KDE/Hyprland/Niri)" \
    "test desktop|Test-build a desktop config for a host" \
    "niri keybindings|Show the Niri keybinding reference"; do
    case "$REPLY_IDX" in
    0) run list-desktops ;;
    1)
      ask de "desktop (gnome/kde/hyprland/niri)" "gnome"
      ask h "host" "$HOST"
      run test-desktop "$de" "$h"
      ;;
    2) run niri-keys ;;
    esac
  done
}

cat_platform() {
  while choose "🪟  macOS & WSL2" \
    "macOS overview|List NixOS VMs/ISOs for Mac users" \
    "build macOS VM|Build a NixOS VM for UTM/QEMU on Mac" \
    "macOS help|Full macOS/UTM guide" \
    "build WSL2 archive|Build the WSL2 import tarball" \
    "test WSL2|Validate the WSL2 configuration" \
    "WSL2 install help|Show WSL2 installation instructions"; do
    case "$REPLY_IDX" in
    0) run list-macos ;;
    1)
      ask t "type (desktop/laptop/server)" "desktop"
      ask a "arch (aarch64/x86_64)" "aarch64"
      run build-macos-vm "$t" "$a"
      ;;
    2) run macos-help ;;
    3) run build-wsl2-archive ;;
    4) run test-wsl2 ;;
    5) run wsl2-install-help ;;
    esac
  done
}

cat_quality() {
  while choose "✅  Quality & Formatting" \
    "check|Run nix flake check" \
    "validate|check + lint + format-check + dead-code" \
    "format|Format all Nix files (nixpkgs-fmt)" \
    "lint|Lint with statix" \
    "dead code|Find unused code with deadnix" \
    "full quality suite|validate + security audit + outdated" \
    "run pre-commit hooks|Run all pre-commit hooks now"; do
    case "$REPLY_IDX" in
    0) run check ;;
    1) run validate ;;
    2) run fmt ;;
    3) run lint ;;
    4) run dead-code-check ;;
    5) run quality ;;
    6) run run-hooks ;;
    esac
  done
}

cat_secrets() {
  while choose "🔐  Secrets (agenix)" \
    "setup secrets|Initialize agenix secrets management" \
    "list secrets|List all .age secrets" \
    "edit secret|Edit/create a secret with agenix" \
    "check secrets|Validate secrets.nix" \
    "rekey secrets|Re-encrypt all secrets after key changes"; do
    case "$REPLY_IDX" in
    0) run setup-secrets ;;
    1) run list-secrets ;;
    2)
      ask s "secret name (without .age)" ""
      [ -n "$s" ] && run edit-secret "$s"
      ;;
    3) run check-secrets ;;
    4) run rekey-secrets ;;
    esac
  done
}

cat_info() {
  while choose "ℹ️   Maintenance & Info" \
    "system info|Hostname, configs, current generation" \
    "flake inputs|Show flake inputs + versions" \
    "list generations|System generations" \
    "clean|Garbage-collect the Nix store" \
    "clean old (7d+)|Remove generations older than 7 days" \
    "clean results|Remove leftover result symlinks" \
    "dev shell|Enter the development shell (nix develop)" \
    "all recipes (raw)|Full just --list output"; do
    case "$REPLY_IDX" in
    0) run info ;;
    1) run show-inputs ;;
    2) run list-generations ;;
    3) run clean ;;
    4) run clean-old ;;
    5) run clean-results ;;
    6) run shell ;;
    7) run list ;;
    esac
  done
}

main() {
  if ! command -v just >/dev/null 2>&1; then
    echo "error: 'just' is not installed. Enter the dev shell first: nix develop" >&2
    exit 1
  fi
  while choose "What would you like to do?" \
    "Build & Apply|Switch, test, build, update your system" \
    "Create Host/User|Scaffold a new host or user from templates" \
    "VMs & Testing|Build and test virtual machines" \
    "Installer ISOs|Build bootable NixOS installers" \
    "Desktops|Browse & test desktop environments" \
    "macOS & WSL2|NixOS on a Mac or on Windows/WSL2" \
    "Quality & Format|Lint, format, validate the codebase" \
    "Secrets|Manage agenix-encrypted secrets" \
    "Maintenance & Info|Clean store, show info, dev shell"; do
    case "$REPLY_IDX" in
    0) cat_build ;;
    1) cat_create ;;
    2) cat_vm ;;
    3) cat_iso ;;
    4) cat_desktop ;;
    5) cat_platform ;;
    6) cat_quality ;;
    7) cat_secrets ;;
    8) cat_info ;;
    esac
  done
  clear 2>/dev/null || true
}

main "$@"
