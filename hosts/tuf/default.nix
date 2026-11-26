# Host tuf: ASUS TUF Gaming A15 FA507UI (Ryzen 9 8945H + Radeon 780M, RTX 4070 Laptop, 32 GB).
# Install: docs/install-tuf.md.
{ pkgs, user, ... }:

{
  imports = [ ../disk.nix ./hardware-configuration.nix ];

  home-manager.users.${user}.imports = [ ./home.nix ];

  # --- ASUS laptop ----------------------------------------------------------------
  services.asusd.enable = true;                 # fan profiles, keyboard backlight, charge limit (Armoury Crate)
  services.power-profiles-daemon.enable = true; # asusd drives the platform profile through it
  services.upower.enable = true;                # battery status
  hardware.bluetooth.enable = true;             # Realtek Bluetooth (wifi: rtw89, in the kernel)

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
    options = [ "uid=1000" "gid=100" "umask=022" "nofail" "x-systemd.device-timeout=5s" ];
  };

  # --- Gaming -----------------------------------------------------------------------
  programs.steam.enable = true;                 # Proton for Windows games
  programs.gamemode.enable = true;              # `gamemoderun %command%` in Steam launch options
  services.lact.enable = true;                  # GPU monitoring/fan control (MSI Afterburner, HWiNFO)
  hardware.graphics.extraPackages = [ pkgs.lsfg-vk ]; # Lossless Scaling frame gen; needs your Steam copy of Lossless Scaling

  # --- System services ----------------------------------------------------------------
  services.opensnitch.enable = true;            # per-app firewall prompts (simplewall); UI: opensnitch-ui
  services.tailscale.enable = true;             # `sudo tailscale up` once to log in
  services.locate = { enable = true; package = pkgs.plocate; }; # `locate <name>` (Everything)
  programs.localsend.enable = true;             # also opens its firewall port
  programs.obs-studio.enable = true;
}
