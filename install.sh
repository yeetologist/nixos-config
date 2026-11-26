#!/usr/bin/env bash
# Install nixos-btw from the NixOS installer ISO (as root):
#   bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh)
# From a local clone (new host not pushed yet), copied to ~/nixos-config on the new system:
#   FLAKE=/tmp/nixos-config#laptop bash /tmp/nixos-config/install.sh
# Modes: wipe the whole disk, or reinstall keeping /home (@home and its snapshots survive).
# Layout must match hosts/vm/hardware-configuration.nix: labels BOOT/swap/nixos, subvolumes @ @home @nix.
set -euo pipefail

flake=${FLAKE:-github:yeetologist/nixos-config#nixos-btw}
die() { echo "error: $*" >&2; exit 1; }
[ "$(id -u)" = 0 ] || die "run as root"
src=${flake%%#*}
if [ -d "$src" ]; then # local flake: only git-tracked (or staged) files are visible to it
  git -C "$src" rev-parse --git-dir >/dev/null 2>&1 || die "$src is not a git repo"
  [ -z "$(git -C "$src" ls-files --others --exclude-standard)" ] || die "untracked files in $src; run: git -C $src add -A"
  src=$(realpath "$src")
fi

# --- Disk -------------------------------------------------------------------
echo "Disks:"
lsblk -dpno NAME,SIZE,MODEL -e 7,11
default_disk=$(lsblk -dpno NAME -e 7,11 | head -1)
read -rp "Install to [$default_disk]: " disk
disk=${disk:-$default_disk}
[ -b "$disk" ] || die "$disk is not a block device"
disk_gib=$(( $(lsblk -bdno SIZE "$disk") / 1024**3 ))

# Partition of $disk with the given GPT partlabel (not global by-partlabel: other disks may share it).
part() { lsblk -lnpo NAME,PARTLABEL "$disk" | awk -v l="$1" '$2 == l { print $1 }'; }

# --- Mode -------------------------------------------------------------------
mode=wipe
if [ -n "$(part root)" ] && [ -n "$(part ESP)" ] && [ -n "$(part swap)" ]; then
  echo "$disk already has a nixos-btw layout."
  read -rp "[w]ipe everything, or [k]eep /home and reinstall the system? [w/k]: " m
  case $m in k|K) mode=keep-home ;; w|W) ;; *) die "choose w or k" ;; esac
fi

# --- Swap size (wipe only; keep-home reuses the existing partition) -----------
if [ "$mode" = wipe ]; then
  ram_gib=$(( ($(awk '/MemTotal/ { print $2 }' /proc/meminfo) + 1024**2 - 1) / 1024**2 ))
  swap_default=$(( ram_gib > 8 ? 8 : ram_gib ))
  read -rp "Swap GiB (disk is ${disk_gib} GiB, RAM ${ram_gib} GiB) [$swap_default]: " swap_gib
  swap_gib=${swap_gib:-$swap_default}
  [[ $swap_gib =~ ^[0-9]+$ ]] && [ "$swap_gib" -ge 1 ] || die "swap must be a whole number >= 1"
  root_gib=$(( disk_gib - 1 - swap_gib ))
  [ "$root_gib" -ge 20 ] || die "only ${root_gib} GiB left for root; need >= 20"
fi

# --- Hostname (not in the flake, so clones don't clash; written to /etc/hostname) ---
read -rp "Hostname [nixos-btw]: " host
host=${host:-nixos-btw}
[[ $host =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || die "hostname: lowercase letters, digits, '-'; max 63"

# --- Password (typed twice: root is locked, a typo would lock you out) --------
while :; do
  read -rsp "Password for bam: " p1; echo
  read -rsp "Again: " p2; echo
  [ -n "$p1" ] && [ "$p1" = "$p2" ] && break
  echo "Empty or mismatched, try again."
done
if command -v mkpasswd >/dev/null; then hash=$(printf '%s' "$p1" | mkpasswd -m sha-512 -s)
else hash=$(printf '%s' "$p1" | openssl passwd -6 -stdin); fi
unset p1 p2

# --- Confirm ------------------------------------------------------------------
echo
echo "Host:  $host"
echo "Disk:  $disk (${disk_gib} GiB)"
if [ "$mode" = wipe ]; then
  echo "Mode:  WIPE ENTIRE DISK"
  echo "Parts: 1 GiB boot, ${swap_gib} GiB swap, ~${root_gib} GiB btrfs (@ @home @nix)"
else
  echo "Mode:  keep /home: recreate boot, @ and @nix; @home is left untouched"
fi
echo "Flake: $flake"
read -rp "Type the disk name ($disk) to continue: " ok
[ "$ok" = "$disk" ] || die "aborted"

# --- Partition / format ---------------------------------------------------------
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
if [ "$mode" = wipe ]; then
  wipefs -af "$disk"
  parted -s "$disk" -- mklabel gpt \
    mkpart ESP fat32 1MiB 1GiB set 1 esp on \
    mkpart swap linux-swap 1GiB "$(( 1 + swap_gib ))GiB" \
    mkpart root btrfs "$(( 1 + swap_gib ))GiB" 100%
  udevadm settle
  mkswap -L swap "$(part swap)"
  mkfs.btrfs -f -L nixos "$(part root)"
fi
mkfs.fat -F32 -n BOOT "$(part ESP)" # always fresh: old generations' boot entries would point at deleted @
udevadm settle
esp=$(part ESP) swp=$(part swap) root=$(part root)

# --- Subvolumes ------------------------------------------------------------------
mount "$root" /mnt
if [ "$mode" = keep-home ]; then
  [ -d /mnt/@home ] || die "no @home subvolume on $root"
  for sv in @ @nix; do
    [ -d "/mnt/$sv" ] && btrfs subvolume delete -R "/mnt/$sv"
  done
fi
btrfs subvolume create /mnt/@ /mnt/@nix
[ -d /mnt/@home ] || btrfs subvolume create /mnt/@home
[ -d /mnt/@home/.snapshots ] || btrfs subvolume create /mnt/@home/.snapshots
umount /mnt

o=compress=zstd:1,noatime
mount -o "subvol=@,$o" "$root" /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o "subvol=@home,$o" "$root" /mnt/home
mount -o "subvol=@nix,$o" "$root" /mnt/nix
mount -o umask=077 "$esp" /mnt/boot
swapon "$swp"

# --- Hostname + password file (configuration.nix reads them; mutableUsers = false) --
install -d -m 700 /mnt/etc/passwords
printf '%s\n' "$host" > /mnt/etc/hostname
( umask 077; printf '%s\n' "$hash" > /mnt/etc/passwords/bam )

# --- Install ------------------------------------------------------------------------
nixos-install --flake "$flake" --no-root-passwd --option experimental-features 'nix-command flakes'

# Local flake: keep the clone (it lives in the ISO's RAM otherwise). Never overwrite an existing one.
if [ -d "$src" ]; then
  dest=/mnt/home/bam/nixos-config
  [ -e "$dest" ] && dest=$dest.install-$(date +%Y%m%d%H%M%S)
  cp -a "$src" "$dest"
  chown -R "$(awk -F: '$1 == "bam" { print $3 ":" $4 }' /mnt/etc/passwd)" "$dest"
  echo "Config copied to ${dest#/mnt}"
fi
echo "Done. Reboot when ready."
