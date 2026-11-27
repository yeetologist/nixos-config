# Host tuf: ASUS TUF Gaming A15 FA507UI (Ryzen 9 8945H + Radeon 780M, RTX 4070 Laptop, 32 GB).
# Install: docs/install-tuf.md.
{ config, pkgs, user, ... }:
let
  owner = [ "uid=${toString config.users.users.${user}.uid}" "gid=${toString config.users.groups.users.gid}" ];
in

{
  imports = [ ../disk.nix ./hardware-configuration.nix ];

  home-manager.users.${user}.imports = [ ./home.nix ];

  # --- ASUS laptop ----------------------------------------------------------------
  services.asusd = {                            # fan profiles, keyboard backlight, charge limit (G-Helper / Armoury Crate)
    enable = true;
    enableUserService = true;                   # user service for rog-control-center GUI
  };
  services.power-profiles-daemon.enable = true; # asusd drives the platform profile through it
  services.upower.enable = true;                # battery status
  hardware.bluetooth.enable = true;             # Realtek Bluetooth (wifi: rtw89, in the kernel)
  services.blueman.enable = true;               # Bluetooth tray applet & manager GUI

  # --- Hybrid graphics: Radeon 780M runs the desktop, RTX 4070 on demand (`nvidia-offload <app>`) ---
  services.xserver.videoDrivers = [ "nvidia" ]; # also selects the driver on Wayland
  hardware.nvidia = {
    open = true;                                # open kernel module (RTX 20xx+); set false if the screen misbehaves
    modesetting.enable = true;
    powerManagement.enable = true;              # keep VRAM across suspend
    powerManagement.finegrained = true;         # power the dGPU off when idle
    dynamicBoost.enable = true;                 # CPU<->GPU power shifting (Windows: nvpcf)
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:102:0:0";              # Radeon 780M, read from Windows Device Manager
      nvidiaBusId = "PCI:1:0:0";                # RTX 4070
    };
  };

  # --- Second NVMe (ADATA, Windows E:) stays NTFS, mounted at /data ------------------
  # Needs the volume label "data" (install-day checklist). nofail: boot doesn't wait if it's missing.
  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ntfs3";
    options = owner ++ [ "umask=022" "nofail" "x-systemd.device-timeout=5s" ];
  };

  # --- Gaming -----------------------------------------------------------------------
  programs.steam.enable = true;                 # Proton for Windows games
  programs.gamemode.enable = true;              # `gamemoderun %command%` in Steam launch options
  services.lact.enable = true;                  # GPU monitoring/fan control (MSI Afterburner, HWiNFO)
  hardware.graphics.extraPackages = [ pkgs.lsfg-vk ]; # Lossless Scaling frame gen; needs your Steam copy of Lossless Scaling

  # --- System services ----------------------------------------------------------------
  services.fwupd.enable = true;                 # firmware updates via LVFS (https://fwupd.org)
  services.opensnitch.enable = true;            # per-app firewall prompts (simplewall); UI: opensnitch-ui
  services.tailscale.enable = true;             # `sudo tailscale up` once to log in
  # NextDNS DoH proxy on 127.0.0.1:53, used only after `set-wifi-dns` (away from home; at home the
  # router's stubby handles DNS). DoH on 443, like Windows: DoT's port 853 is often blocked (the home router does).
  services.nextdns = { enable = true; arguments = [ "-profile" "a3fc53" "-report-client-info" "-listen" "127.0.0.1:53" ]; };
  services.locate = { enable = true; package = pkgs.plocate; }; # `locate <name>` (Everything)
  programs.localsend.enable = true;             # also opens its firewall port
  programs.nix-ld.enable = true;                # run prebuilt binaries from curl|bash installers (e.g. Warp agent CLI)
  programs.obs-studio.enable = true;
}
