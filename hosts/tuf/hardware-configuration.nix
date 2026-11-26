# PLACEHOLDER until install day: typical drivers for an AMD laptop with NVMe, written from
# the Windows device list. On the installer, replace it with the real detection:
#   sudo nixos-generate-config --show-hardware-config --no-filesystems > hosts/tuf/hardware-configuration.nix
# Disks live in ../disk.nix.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
