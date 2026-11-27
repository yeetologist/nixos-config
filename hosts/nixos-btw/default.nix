# Host nixos-btw (VMware VM): everything that only makes sense inside the VM.
# New machines: see docs/adding-a-device.md.
{ config, pkgs, user, ... }:
let
  owner = [ "uid=${toString config.users.users.${user}.uid}" "gid=${toString config.users.groups.users.gid}" ];
in

{
  imports = [ ../disk.nix ./hardware-configuration.nix ];

  home-manager.users.${user}.imports = [ ./home.nix ];

  # Console-only VM: allow passwordless emergency/rescue shells with locked root.
  boot.initrd.systemd.emergencyAccess = true;
  systemd.services.emergency.environment.SYSTEMD_SULOGIN_FORCE = "1";
  systemd.services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";

  virtualisation.vmware.guest = {
    enable = true;
    headless = false; # enable display/input guest additions (SVGA, drag-drop, etc.)
  };
  # shortcut: nixpkgs' vmblock unit uses Type=fuse but only mount.fuse3 exists; drop once nixpkgs fixes it.
  systemd.packages = [
    (pkgs.writeTextDir "etc/systemd/system/run-vmblock\\x2dfuse.mount.d/fuse3.conf" "[Mount]\nType=fuse3\n")
  ];

  # Whole system on uutils (Ubuntu-style): rewrite GNU coreutils refs in the built closure, no rebuild.
  # Replacement keeps GNU's store name since replaceDependencies needs equal-length paths.
  system.replaceDependencies.replacements = map (old: {
    oldDependency = old;
    newDependency = pkgs.runCommand old.name { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.uutils-coreutils-noprefix}/bin/* $out/bin/
    '';
  }) [ pkgs.coreutils pkgs.coreutils-full ];

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
