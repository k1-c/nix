# nix

k1-c's NixOS configuration (flake). Manages multiple machines from a single flake.

![flake check](https://github.com/k1-c/nix/actions/workflows/check.yml/badge.svg)

## Layout

```
.
├── flake.nix              # flake entry / nixosConfigurations
├── hosts/                 # per-machine config
│   ├── insomnia/          #   main desktop (NVIDIA + Intel NPU)
│   └── dwarf/             #   secondary desktop (Intel iGPU)
├── modules/               # NixOS modules (shared across hosts)
│   └── desktop/           #   SDDM + Plasma / Niri / Hyprland
└── home/k1nix/            # home-manager (user "k1nix")
    └── desktop/           #   waybar / fuzzel / hyprlock etc.
```

## Hosts

| host     | CPU/GPU                 | role        |
| -------- | ----------------------- | ----------- |
| insomnia | Intel + NVIDIA RTX 3070 | sub desktop |
| dwarf    | Intel + iGPU            | sub desktop |

Both hosts share a single user account `k1nix`. Initial password is `password` (see below).

## Desktop environments

Pick at login via SDDM:

- **Plasma** (Wayland) — default. Liquid Glass-ish look (KWin Blur + Background Contrast + `kde-rounded-corners`, transparent panel). Walker bound to `Meta+Return` / `Meta+D`. Animated wallpaper via `plasma-smart-video-wallpaper-reborn` (drop a file at `~/.config/wallpaper/animated.mp4`).
- **Niri** (Wayland, scrollable tiling)
- **Hyprland** (Wayland, dynamic tiling)

Per-DE home-manager configs live in `home/k1nix/desktop/{plasma,niri,hyprland}.nix`. KDE side is configured declaratively via `plasma-manager`. waybar and friends run as systemd user units bound to `graphical-session.target`.

> SDDM greeter itself still runs on X11 (`wayland.enable = false`) to dodge the NVIDIA + open-module + `kwin_wayland` atomic-modeset bug — only the Plasma *session* is Wayland.

---

## Initial setup (fresh machine)

Assumes you have booted the NixOS minimal ISO.

### 1. Partition & mount

```sh
# UEFI layout (GPT + ESP)
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
```

### 2. Clone & generate hardware config

```sh
nix-shell -p git --run 'git clone https://github.com/k1-c/nix /mnt/etc/nixos'
cd /mnt/etc/nixos

# Create a directory for the new host (example: laptop)
mkdir -p hosts/laptop
sudo nixos-generate-config --root /mnt --show-hardware-config \
  > hosts/laptop/hardware-configuration.nix
```

### 3. Add the host definition

Copy `hosts/dwarf/default.nix` as a starting point for `hosts/laptop/default.nix`, then:

- set `networking.hostName` to `laptop`
- if the machine has NVIDIA, import a `./nvidia.nix` modeled after `hosts/insomnia/nvidia.nix`

Add one line to `nixosConfigurations` in `flake.nix`:

```nix
laptop = mkHost "laptop" "x86_64-linux";
```

### 4. Install

```sh
sudo nixos-install --flake /mnt/etc/nixos#laptop
# After reboot, log in as k1nix / password
```

---

## Install directly from GitHub (no clone)

When the target host is already defined in this flake (`insomnia` or `dwarf`) and the
disk layout matches what is committed in `hosts/<name>/hardware-configuration.nix`,
you can skip the clone step and let `nixos-install` fetch everything over the network.

```sh
# Boot the NixOS minimal ISO, then partition & mount /mnt
# (see "Initial setup" step 1)

# Install straight from the GitHub flake
sudo nixos-install \
  --flake github:k1-c/nix#dwarf \
  --no-root-password   # the user already has initialPassword
```

Notes:

- Older ISOs may not have flakes enabled by default. Add `--option experimental-features 'nix-command flakes'` if `nixos-install` complains about unknown experimental features.
- For a brand-new machine without a matching `hosts/<name>/` directory, this shortcut does not work. Use the full "Initial setup" flow to clone, generate `hardware-configuration.nix`, add the host to `flake.nix`, push, and then install.
- Pinning to a specific revision: `github:k1-c/nix/<commit-or-tag>#dwarf`.

---

## Applying to an existing machine (insomnia / dwarf)

```sh
git clone https://github.com/k1-c/nix ~/dev/git/github.com/k1-c/nix
cd ~/dev/git/github.com/k1-c/nix

# Evaluate first to catch errors safely
sudo nixos-rebuild dry-build --flake .#$(hostname)

# Apply
sudo nixos-rebuild switch --flake .#$(hostname)
```

> `nix flake` only sees git-tracked files. When trying local changes, at least `git add -A` (no commit needed) before running `nixos-rebuild`.

---

## Updating

```sh
# Refresh flake.lock
nix flake update

# Update a single input
nix flake update nixpkgs

# Apply
sudo nixos-rebuild switch --flake .#$(hostname)
```

To roll back a generation:

```sh
sudo nixos-rebuild switch --rollback
# Or pick an older generation from the GRUB menu
```

---

## Security note

`hosts/{insomnia,dwarf}/default.nix` ships with a hardcoded `initialPassword = "password"`.

- While this repository is public, the password is visible to anyone
- After the first install, log in, run `passwd` to change it, then delete that line and commit
- Long-term, migrate to secret management with `sops-nix` or `agenix`

`initialPassword` is only written when `/etc/shadow` has no entry for the user, so once `passwd` has changed it the option becomes a no-op. Still, the literal stays in git history, so it is hygienic to strip it.

---

## CI

GitHub Actions runs `nix flake check --no-build` on every push / PR / `workflow_dispatch` (`.github/workflows/check.yml`).

What it catches:

- Nix syntax errors
- References to nonexistent attributes / options
- Typos in import paths
- `flake.lock` consistency

What it does **not** catch: actual builds (proprietary NVIDIA, `niri-unstable`, and friends are not fetched in CI). Run `nixos-rebuild dry-build` locally, or extend the workflow with a build job if needed.

---

## Flake inputs

| input              | source                                     | purpose                                     |
| ------------------ | ------------------------------------------ | ------------------------------------------- |
| `nixpkgs`          | `NixOS/nixpkgs/nixos-25.11`                | main package set                            |
| `nixpkgs-unstable` | `NixOS/nixpkgs/nixos-unstable`             | `niri-flake` follows / a few newer packages |
| `home-manager`     | `nix-community/home-manager/release-25.11` | user-level configuration                    |
| `niri`             | `sodiboo/niri-flake`                       | `niri-unstable` + NixOS module              |
| `plasma-manager`   | `nix-community/plasma-manager`             | declarative KDE Plasma 6 home-manager module |
