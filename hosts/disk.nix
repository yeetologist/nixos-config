# Disk layout shared by every host: exactly what install.sh creates.
# Labels BOOT / swap / nixos, btrfs subvolumes @ @home @nix. Imported by each hosts/<name>/default.nix.
{ ... }:

let
  btrfs = subvol: {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "compress=zstd:1" "noatime" ];
  };
in
{
  fileSystems."/"     = btrfs "@";
  fileSystems."/home" = btrfs "@home";
  fileSystems."/nix"  = btrfs "@nix";
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
}
