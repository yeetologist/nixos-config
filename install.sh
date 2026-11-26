#!/usr/bin/env bash
# Fresh install of nixos-btw from the NixOS installer ISO. WIPES THE DISK.
#   sudo bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh) /dev/sda
# hardware-configuration.nix mounts by label, so no clone or regenerated hardware config is needed.
set -euo pipefail

disk=${1:?usage: install.sh /dev/sdX}
flake=${FLAKE:-github:yeetologist/nixos-config#nixos-btw}
[ -b "$disk" ] || { echo "$disk is not a block device" >&2; exit 1; }
[ "$(id -u)" = 0 ] || { echo "run as root" >&2; exit 1; }

lsblk "$disk"
read -rp "ERASE everything on $disk? type yes: " ok </dev/tty
[ "$ok" = yes ] || exit 1

# 1. Partition (GPT: 1 GiB ESP, 4 GiB swap, rest btrfs). Partlabels avoid sda1 vs nvme0n1p1.
parted -s "$disk" -- mklabel gpt \
  mkpart ESP fat32 1MiB 1GiB set 1 esp on \
  mkpart swap linux-swap 1GiB 5GiB \
  mkpart root btrfs 5GiB 100%
udevadm settle
p=/dev/disk/by-partlabel
mkfs.fat -F32 -n BOOT "$p/ESP"
mkswap -L swap "$p/swap"
mkfs.btrfs -f -L nixos "$p/root"
udevadm settle

# 2. btrfs subvolumes @ @home @nix, plus @home/.snapshots for snapper.
mount "$p/root" /mnt
btrfs subvolume create /mnt/@ /mnt/@home /mnt/@nix
btrfs subvolume create /mnt/@home/.snapshots
umount /mnt
o=compress=zstd:1,noatime
mount -o "subvol=@,$o" "$p/root" /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o "subvol=@home,$o" "$p/root" /mnt/home
mount -o "subvol=@nix,$o" "$p/root" /mnt/nix
mount -o umask=077 "$p/ESP" /mnt/boot
swapon "$p/swap"

# 3. Password for bam (configuration.nix reads /etc/passwords/bam; mutableUsers = false).
mkdir -p /mnt/etc/passwords
hash=""
while [ -z "$hash" ]; do
  hash=$(mkpasswd -m sha-512 </dev/tty) || hash=""
done
printf '%s\n' "$hash" > /mnt/etc/passwords/bam
chmod 600 /mnt/etc/passwords/bam

# 4. Install straight from GitHub. Root stays locked (hashedPassword = "!").
nixos-install --flake "$flake" --no-root-passwd --option experimental-features 'nix-command flakes'

echo "Done. Reboot when ready."
