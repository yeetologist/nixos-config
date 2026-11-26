# Host nixos-btw (VMware VM): everything that only makes sense inside the VM.
# New machines: see docs/adding-a-device.md.
{ config, pkgs, user, ... }:
let
  owner = [ "uid=${toString config.users.users.${user}.uid}" "gid=${toString config.users.groups.users.gid}" ];
in

{
  imports = [ ../disk.nix ./hardware-configuration.nix ];

  home-manager.users.${user}.imports = [ ./home.nix ];

  virtualisation.vmware.guest = {
    enable = true;
    headless = false; # enable display/input guest additions (SVGA, drag-drop, etc.)
  };
  # shortcut: nixpkgs' vmblock unit uses Type=fuse but only mount.fuse3 exists; drop once nixpkgs fixes it.
  systemd.packages = [
    (pkgs.writeTextDir "etc/systemd/system/run-vmblock\\x2dfuse.mount.d/fuse3.conf" "[Mount]\nType=fuse3\n")
  ];

  # VMware shared folders.
  fileSystems."/mnt/hgfs" = {
    device = ".host:/";
    fsType = "fuse.vmhgfs-fuse";
    options = owner ++ [
      "allow_other"
      "auto_unmount"
      "defaults"
      "nofail"  # don't block boot if VMware shared folders aren't available
      # These two lines fix the boot timing issue:
      "x-systemd.automount"
      "x-systemd.requires=vmtoolsd.service"
    ];
  };
}
