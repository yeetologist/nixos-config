# Installing tuf (ASUS TUF Gaming A15 FA507UI)

NixOS replaces Windows on the **WD SN5000S** disk (Windows `C:` + `D:`, wiped).
The **ADATA** disk (Windows `E:`) keeps its files and becomes `/data`.
The config is already in `hosts/tuf/`. Only its drivers get regenerated on the laptop.

## 1. In Windows, before wiping

**1. Prepare `E:`** in an admin PowerShell. Both can be undone (label `""`, `powercfg /h on`).

```powershell
Set-Volume -DriveLetter E -NewFileSystemLabel data   # NixOS mounts it by this label
powercfg /h off                                      # Fast Startup off, so E: closes cleanly
```

**2. Back up to `E:`.** `C:` and `D:` are wiped. First, everything in `AppData\Roaming` (about 10 GB):
game saves and `ludusavi-backup`, RenPy, mpv scripts and cookies, the yt-dlp plugin, Zed's private settings,
`rclone.conf`. Then your SSH keys:

```powershell
robocopy "$env:APPDATA" E:\backup\AppData-Roaming /E /XJ /R:1 /W:1
robocopy "$HOME\.ssh" E:\backup\.ssh /E
```

Copy anything else you need off `C:` and `D:` too. Secrets never go in the public repo.

**3. Shut down** (not restart), then boot the NixOS installer USB.

## 2. On the installer

```sh
sudo -i
nmtui
nix-shell -p git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
nixos-generate-config --show-hardware-config --no-filesystems > hosts/tuf/hardware-configuration.nix
git add -A
FLAKE=/tmp/nixos-config#tuf bash install.sh
```

At the prompts:
- **Disk:** pick the **WD (SN5000S)**, never the ADATA one. `lsblk -o NAME,SIZE,MODEL,LABEL` shows the ADATA one with label `data`.
- **Hostname:** `tuf`.
- **Swap:** the default, 8.

## 3. After the first boot

```sh
b=/data/backup/AppData-Roaming
cp -r /data/backup/.ssh ~/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
mkdir -p ~/.config/rclone && cp $b/rclone/rclone.conf ~/.config/rclone/
mkdir -p ~/.config/mpv ~/.config/yt-dlp && cp -r $b/mpv/scripts ~/.config/mpv/ && cp -r $b/yt-dlp/plugins ~/.config/yt-dlp/
mkdir -p /data/ludusavi-backup && cp -rn $b/ludusavi-backup/. /data/ludusavi-backup/   # then restore saves in the ludusavi GUI
gh auth login
sudo tailscale up
asusctl -c 80                                        # stop charging at 80%
nix-shell -p mesa-demos --run 'nvidia-offload glxinfo -B' | grep -i renderer   # expect RTX 4070
```

**Zed:** your preferences are already applied. Copy the private keys (`agent`, `language_models`,
`edit_predictions`, `proxy`, `server_url`, `ssh_connections`) from `$b/Zed/settings.json` into
Zed's settings (`Ctrl+,`).

Then push the regenerated drivers (step 7 of [adding-a-device.md](adding-a-device.md)). After that, `up` rebuilds the laptop from GitHub.

## Not in hosts/tuf

- **JDownloader 2:** not packaged in nixpkgs. Use the Linux installer from jdownloader.org.
- **Zotero:** nixpkgs builds it on an end-of-life, insecure Firefox. Use the tarball from zotero.org.

## If something's wrong

- **Black or flickering screen:** set `hardware.nvidia.open = false;` in `hosts/tuf/default.nix`.
- **NVIDIA driver fails to build on the latest kernel:** add `boot.kernelPackages = pkgs.linuxPackages;` there.
- **`/data` missing:** check `lsblk -f` shows the label `data`. If it was left "dirty" (Windows not shut down cleanly), run `nix-shell -p ntfs3g --run 'sudo ntfsfix -d /dev/<partition>'`.
