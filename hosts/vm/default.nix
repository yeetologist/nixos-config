# VMware guest: everything that only makes sense inside the VM.
# A bare-metal host gets its own hosts/<name>/ with its own hardware-configuration.nix.
{ pkgs, user, ... }:

{
  imports = [ ./hardware-configuration.nix ];

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
    options = [
      "allow_other"
      "uid=1000"
      "gid=100"
      "auto_unmount"
      "defaults"
      "nofail"  # don't block boot if VMware shared folders aren't available
      # These two lines fix the boot timing issue:
      "x-systemd.automount"
      "x-systemd.requires=vmtoolsd.service"
    ];
  };
}
