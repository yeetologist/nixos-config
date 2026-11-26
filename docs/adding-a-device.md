# Adding a new device

Every command below is meant to be typed in a terminal: the installer ISO's console,
or a shell on an installed machine. No GUI is needed.

## How hosts work

A **host** is one *kind* of machine. Each host is a folder in `hosts/`, and the folder
name is the name you install and rebuild with:

```
hosts/
├── disk.nix              # disk layout shared by every host (what install.sh creates)
├── nixos-btw/            # the VMware VM  →  github:yeetologist/nixos-config#nixos-btw
│   ├── default.nix       #   VMware guest tools, shared folders
│   ├── hardware-configuration.nix
│   └── home.nix          #   VM clipboard sync (Home Manager)
└── laptop/               # a new host     →  …#laptop
```

`flake.nix` turns every folder in `hosts/` into a system automatically. Adding a host
never needs a `flake.nix` edit. Everything outside `hosts/` (`configuration.nix`,
`home.nix`, `modules/home/`) is shared by all hosts.

**Which path you need:**

| Situation | Do |
|---|---|
| Another machine of a kind that already has a host (another VMware VM, a second identical laptop) | [Path A](#path-a-existing-host-just-install): install only. |
| A new kind of machine, and you can push to GitHub from somewhere else | [Path B](#path-b-new-host-pushed-to-github-first): add the host, push, install. |
| A new kind of machine, and it's your only one | [Path C](#path-c-new-host-only-machine-install-from-a-local-clone): add the host on the installer, install, push later. |

## Before any path: boot the installer

1. Write the NixOS installer ISO (from nixos.org) to a USB stick and boot the machine from it.
2. Become root and get online:

```sh
sudo -i
nmtui                                    # wifi: "Activate a connection". Wired usually works already.
ping -c 2 github.com                     # check you're online
```

---

## Path A: existing host, just install

```sh
FLAKE=github:yeetologist/nixos-config#nixos-btw \
  bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh)
```

Replace `nixos-btw` with the host you want. Leaving out `FLAKE=…` installs `nixos-btw`.
Then answer the prompts (see [The install prompts](#the-install-prompts)) and `reboot`.

---

## Path B: new host, pushed to GitHub first

Use this when you have another computer (or the VM) that can push to GitHub.

### B1. On the new machine (installer): create the host

```sh
nix-shell -p git                         # the installer may not have git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
bash add-host.sh laptop                  # pick the name; lowercase, digits, '-'
```

`add-host.sh` creates `hosts/laptop/` from this machine's hardware:
- **`hardware-configuration.nix`**: the drivers it needs, detected by `nixos-generate-config`.
- **`default.nix`**: imports the disk layout, and switches on battery and Bluetooth
  support if the hardware has them. An NVIDIA GPU gets a commented-out line for you to review.

Review it and add anything else the machine needs (see [Common host settings](#common-host-settings)):

```sh
nano hosts/laptop/default.nix            # Ctrl+O Enter to save, Ctrl+X to quit
```

### B2. Move the host to a machine that can push

From the installer, print the two files:

```sh
cat hosts/laptop/default.nix hosts/laptop/hardware-configuration.nix
```

Copy them to the other computer. Pick one way:
- **SSH from the other computer**: on the installer run `passwd` (sets a password for
  the live session) and `ip -4 addr` (shows its IP). Then on the other computer:
  `scp -r root@<ip>:/tmp/nixos-config/hosts/laptop hosts/`
- **Paste**: retype or paste the files into `hosts/laptop/` on the other computer.

On the other computer, in the repo:

```sh
git pull
git add hosts/laptop
git commit -m "Add host laptop"
git push origin main
```

### B3. Back on the new machine: install from GitHub

```sh
FLAKE=github:yeetologist/nixos-config#laptop \
  bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh)
```

Answer the prompts and `reboot`.

---

## Path C: new host, only machine (install from a local clone)

Nothing gets pushed before the install. The host lives in a local clone, and the
script copies that clone onto the new system.

### C1. Create the host on the installer

```sh
nix-shell -p git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
bash add-host.sh laptop
nano hosts/laptop/default.nix            # review; see "Common host settings"
git add -A                               # required: a flake can't see untracked files
```

No commit or GitHub login is needed yet. `add-host.sh` already staged its files.
Run `git add -A` again after any edit that creates new files.

### C2. Install from the clone

```sh
FLAKE=/tmp/nixos-config#laptop bash /tmp/nixos-config/install.sh
```

The script refuses to start if anything is untracked. After installing, it copies the clone to
`/home/bam/nixos-config` on the new system, because the installer's `/tmp` is lost at reboot.
On a keep-home reinstall where that folder exists, it copies to
`nixos-config.install-<date>` instead. Answer the prompts and `reboot`.

### C3. After the first boot: rebuild locally, then push

Until the host is on GitHub, rebuild from the local folder:

```sh
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

To push, log in to GitHub once, then commit:

```sh
cd ~/nixos-config
gh auth login                            # GitHub.com → HTTPS → "Login with a web browser"; open the URL on your phone
git add -A
git commit -m "Add host laptop"
git push origin main
```

`gh` isn't installed by default. Use `nix-shell -p gh` first, or add an SSH key to
GitHub instead. From now on, the GitHub rebuild command below works for this host.

---

## Install day: tuf

`hosts/tuf/` already exists, for the ASUS TUF A15 FA507UI that currently runs Windows.
NixOS replaces Windows on the **WD SN5000S** disk (Windows `C:` and `D:`). The **ADATA**
disk (Windows `E:`) keeps its files and becomes `/data`.

**In Windows, before wiping:**

```powershell
# admin PowerShell
Set-Volume -DriveLetter E -NewFileSystemLabel data   # NixOS mounts /dev/disk/by-label/data
powercfg /h off                                      # turns off Fast Startup, so E: closes cleanly
```

- Copy everything you need off `C:` and `D:`: they are wiped. `E:` survives.
- Copy your secrets to `E:` (they never go in this public repo): `C:\Users\BAM\.ssh`,
  `%APPDATA%\rclone\rclone.conf`.
- Optional: copy Windows configs to `E:` for later porting: `.config\starship.toml`,
  `%APPDATA%\nushell`, `%APPDATA%\Zed\settings.json`, `.gitconfig`,
  `%APPDATA%\yazi\config`, the mpv `portable_config`.
- Shut down normally (not restart), so `E:` is cleanly unmounted.

**On the installer:** follow [Path C](#path-c-new-host-only-machine-install-from-a-local-clone),
but `hosts/tuf/` already exists, so skip `add-host.sh` and regenerate only the drivers:

```sh
sudo -i
nmtui
nix-shell -p git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
nixos-generate-config --show-hardware-config --no-filesystems > hosts/tuf/hardware-configuration.nix
git add -A
lsblk -o NAME,SIZE,MODEL,LABEL        # find the WD disk (SN5000S); the ADATA one shows LABEL "data"
FLAKE=/tmp/nixos-config#tuf bash /tmp/nixos-config/install.sh
```

At the disk prompt, pick the **WD** disk, never the one labelled `data`. At the hostname prompt,
type anything, e.g. `tuf`. Swap: keep the default 8.

**After the first boot:**

```sh
ls /data                                             # the old E: drive
cp -r /data/.ssh ~/.ssh && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
mkdir -p ~/.config/rclone && cp /data/rclone.conf ~/.config/rclone/
sudo tailscale up                                    # log in to Tailscale
asusctl -c 80                                        # battery charge limit
nvidia-offload glxinfo -B | grep -i renderer         # should say RTX 4070 (nix-shell -p mesa-demos)
```

Then push the regenerated `hosts/tuf/hardware-configuration.nix` from `~/nixos-config`
(see Path C, step C3). After that, `up` rebuilds this laptop from GitHub.

Not in `hosts/tuf`:
- **JDownloader 2:** not packaged in nixpkgs. Run its Linux installer from jdownloader.org.
- **Zotero:** nixpkgs builds it on an end-of-life, insecure Firefox. Use the tarball
  from zotero.org, or wait for nixpkgs to move it to a supported engine.

---

## The install prompts

`install.sh` asks, in order:

1. **Disk**: pick from the list (Enter = first). It is wiped unless you choose keep-home.
2. **Mode**: only shown if the disk already has this layout. `w` wipes everything. `k`
   keeps `/home` (your files and snapshots) and reinstalls the system.
3. **Swap size** in GiB: default is your RAM, capped at 8.
4. **Hostname**: this machine's network name, unique per machine (e.g. `laptop-01`).
   It is separate from the host folder name.
5. **Password for `bam`**: typed twice. Root has no password.
6. **Confirmation**: type the disk name (e.g. `/dev/nvme0n1`) to start.

After `reboot`, log in on the console (tty1) and niri starts automatically.

## Day to day

Rebuild a machine from GitHub with its **host folder name**:

```sh
sudo nixos-rebuild switch --refresh --flake github:yeetologist/nixos-config#laptop
```

The `up` alias in `home.nix` runs this for `#nixos-btw` only. Type the command in
full on other hosts.

Rename a machine (hostname, not host folder):

```sh
echo new-name | sudo tee /etc/hostname && sudo reboot    # hostnamectl can't write it on NixOS
```

Regenerate a host's drivers after a hardware change. Run on that machine, inside
the repo:

```sh
sudo nixos-generate-config --show-hardware-config --no-filesystems > hosts/laptop/hardware-configuration.nix
```

## Common host settings

Add these to `hosts/<name>/default.nix` inside the `{ … }` block, only if the machine has the hardware:

```nix
hardware.bluetooth.enable = true;                 # Bluetooth
services.power-profiles-daemon.enable = true;     # laptop: battery power profiles
services.upower.enable = true;                    # laptop: battery status
hardware.nvidia.open = true;                      # NVIDIA GPU (RTX 20xx or newer)
services.xserver.videoDrivers = [ "nvidia" ];     #   …needed with the line above
services.fprintd.enable = true;                   # fingerprint reader
```

Settings for your user on just this host go in `hosts/<name>/home.nix`. Use
`hosts/nixos-btw/home.nix` as the example, and uncomment the
`home-manager.users.${user}.imports` line in `default.nix`.

Don't copy anything from `hosts/nixos-btw/`. VMware guest tools, shared folders and the
clipboard sync only work inside VMware.

### Example: ASUS TUF Gaming A15 FA507UI

This is the current laptop: AMD Ryzen with a Radeon iGPU, an NVIDIA RTX 4070 Laptop GPU,
Realtek wifi, Bluetooth and audio. nixos-hardware has no FA507UI module. The settings below
follow its sister models (`asus/fa507nv`, `asus/fa507rm`). Every option was checked
against this repo's pinned nixpkgs.

**1. Get the GPU bus IDs.** Run this on the laptop, from the installer or an installed system.
It prints each GPU with its ID already in the decimal form Nix wants (`lspci` shows hex):

```sh
nix-shell -p pciutils --run 'for d in $(lspci -D | awk "/VGA|3D|Display/ {print \$1}"); do IFS=":." read -r _ b s f <<<"$d"; printf "%-45s PCI:%d:%d:%d\n" "$(lspci -s "$d" | cut -d" " -f2-)" "$((16#$b))" "$((16#$s))" "$((16#$f))"; done'
```

Expect two lines, an `NVIDIA … AD106M` (often `PCI:1:0:0`) and an `AMD/ATI … Radeon`
(e.g. `PCI:101:0:0`). Use the IDs your laptop prints, not these.

**2. `hosts/laptop/default.nix`** (after `bash add-host.sh laptop`, replace the generated body):

```nix
# Host laptop: ASUS TUF Gaming A15 FA507UI (Ryzen + Radeon iGPU, RTX 4070 Laptop).
{ config, pkgs, user, ... }:

{
  imports = [ ../disk.nix ./hardware-configuration.nix ];

  # ASUS: fan/performance profiles, keyboard backlight, battery charge limit (replaces Armoury Crate).
  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true; # asusd drives the platform profile through it
  services.upower.enable = true;                # battery status for waybar

  # Wifi (Realtek rtw89) and AMD microcode load from firmware that configuration.nix already enables.
  hardware.bluetooth.enable = true;             # Realtek Bluetooth

  # NVIDIA RTX 4070 + Radeon iGPU (hybrid "PRIME offload"): the iGPU runs the desktop,
  # the NVIDIA GPU sleeps until an app asks for it with `nvidia-offload <app>`.
  services.xserver.videoDrivers = [ "nvidia" ]; # also selects the driver on Wayland
  hardware.nvidia = {
    open = true;                                # open kernel module: recommended for RTX 20xx and newer
    modesetting.enable = true;
    powerManagement.enable = true;              # save VRAM across suspend
    powerManagement.finegrained = true;         # power the dGPU fully off when idle (needs offload)
    dynamicBoost.enable = true;                 # shift power CPU<->GPU under load (Windows: nvpcf)
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;          # adds the `nvidia-offload` command
      amdgpuBusId = "PCI:101:0:0";              # from step 1 (AMD line)
      nvidiaBusId = "PCI:1:0:0";                # from step 1 (NVIDIA line)
    };
  };
}
```

**3. After the first boot:**

```sh
asusctl profile -P Quiet                      # or Balanced / Performance (Fn+F5 cycles too)
asusctl -c 80                                 # stop charging at 80% to spare the battery
nvidia-offload glxinfo -B | grep -i renderer  # should name the RTX 4070 (nix-shell -p mesa-demos)
nvidia-smi                                    # GPU status; "No devices" while idle is normal with finegrained
```

**How the Windows drivers in the backup map to NixOS:**

| Windows driver(s) | What it is | On NixOS |
|---|---|---|
| `fa507ui_*`, `armourycratecontrolinterface`, `asuskeyboardfilter`, `asussci2`, `asusvirtualdevice` | ASUS model, fan and keyboard control | `services.asusd` (asusctl) |
| `nvamsi`, `nvhda`, `nvpcf` | NVIDIA driver, HDMI audio, Dynamic Boost | `hardware.nvidia.*` above (`nvpcf` = `dynamicBoost`) |
| `amdwin-*`, `amdocl`, `amdogl`, `amdvlk`, `atihdwt6` | Radeon iGPU graphics and HDMI audio | in the kernel/Mesa (`amdgpu`), nothing to set |
| `amdpmf`, `amdmicropep`, `amdppkg`, `amdpsp`, `amdgpio2`, `amdi2c`, `amdpcibridgeextension` | AMD power, platform and chipset | in the kernel (`amd_pmf`, `amd-pstate`); `power-profiles-daemon` above |
| `amdacp*`, `amdsdw*`, `amdafd`, `amdsafd`, `hdxacpasus` | AMD audio coprocessor (built-in microphones) | in the kernel (SOF/ACP), works through PipeWire |
| `rt68cx21x64`, `realtek*`, `hdx_asusext_*` | Realtek audio and ASUS speaker tuning | in the kernel; tuning profiles have no Linux version (EasyEffects can approximate them) |
| `dax3_*` | Dolby Atmos | no Linux driver |
| `netrtwlane601` | Realtek wifi | in the kernel (`rtw89`) + firmware, already enabled |
| `rtkbtfilter` | Realtek Bluetooth | `hardware.bluetooth.enable` |
| `asusptpfilter` | precision touchpad | in the kernel (`i2c-hid`); niri configures tapping etc. |
| `mep_camera_component`, `usbvideo_ext` | webcam | in the kernel (`uvcvideo`) |
| `kipudrv` | AMD NPU (Ryzen AI) | in the kernel (`amdxdna`); nothing on Linux uses it by default |
| `rcbottom`, `rccfg`, `rcraid` | AMD RAID | not needed. If the installer sees no disk, set the BIOS storage mode to AHCI/NVMe instead of RAID |
| `wireguard`, `wintun`, `ovpn-dco`, `wiresock` | VPN clients | not drivers on Linux; add `networking.wireguard` or OpenVPN if wanted |
| `vmci`, `vmusb` | VMware Workstation (host side) | only if you install VMware on Linux: `virtualisation.vmware.host.enable = true;` |
| `hidhide`, `vigembus` | game controller emulation | not needed; controllers work natively |
| `ss*`, `secu*`, `ssud*`, `c7xxphone`, `ccdcmb*`, `mbtmdm`, `via_usb_*`, `flashusb`, `pawnio`, `prn*`, `pr*drv`, `piecomponent`, `microsofteffectpack`, `netadapter`, `netbridge`, `ndiswgc_lwf` | phone, USB modem, flashing tools, printers, Windows-only components | not needed |

If something misbehaves on this model, try these:
- **Black screen or a flickering internal display:** try `hardware.nvidia.open = false;`.
- **No display at all on the NVIDIA GPU:** try `services.supergfxd.enable = true;` with
  `supergfxctl -m Hybrid`.
- **Kernel too new for the NVIDIA driver:** `configuration.nix` uses the latest kernel. If
  the NVIDIA module fails to build, pin this host to
  `boot.kernelPackages = pkgs.linuxPackages;`.

## Gotchas

- **Untracked files are invisible**: a flake only sees files git knows about. After
  creating files, run `git add -A` before building or installing from a local clone.
- **Windows line endings**: a checkout on Windows uses CRLF. Commits are fine, because
  git converts them to LF. If you copy the working tree to Linux to build it, strip
  the CR characters first (`find . -type f -exec sed -i 's/\r$//' {} +`), or the shell
  scripts inside the config break.
- **Same hardware, same host**: a second laptop of the same model uses the existing
  host folder ([Path A](#path-a-existing-host-just-install)). Give it a different hostname at the prompt.
