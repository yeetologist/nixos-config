# Adding a new device

A **host** is one kind of machine: a folder in `hosts/`. The folder name is the name you
install and rebuild with (`hosts/tuf/` → `#tuf`). Everything outside `hosts/` is shared.

```
hosts/disk.nix      disk layout for every host (what install.sh creates)
hosts/nixos-btw/    VMware VM
hosts/tuf/          ASUS TUF A15 laptop (full example of a real laptop host)
```

Installing the **ASUS TUF** laptop? Follow [install-tuf.md](install-tuf.md) instead.

> **Host already exists** (another VM, a second identical laptop)? Do step 1, then run
> `FLAKE=github:yeetologist/nixos-config#<host> bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh)` and skip to step 6.

## Steps

**1. Boot the NixOS installer ISO, become root, get online.**

```sh
sudo -i
nmtui                       # wifi; wired usually just works
```

**2. Clone the config.**

```sh
nix-shell -p git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
```

**3. Create the host from this machine's hardware.** Name: lowercase letters, digits, `-`.

```sh
bash add-host.sh laptop
```

It detects drivers and enables battery, Bluetooth and NVIDIA support when present.

**4. Review it.** For a complete laptop example (hybrid GPU, ASUS tools, extra disk, gaming),
see `hosts/tuf/default.nix`.

```sh
nano hosts/laptop/default.nix   # Ctrl+O Enter saves, Ctrl+X quits
git add -A                      # flakes only see files git tracks
```

**5. Install from the clone.**

```sh
FLAKE=/tmp/nixos-config#laptop bash install.sh
```

The script copies the clone to `~/nixos-config` on the new system, so nothing is lost at reboot.

**6. Reboot, log in on the console.** niri starts automatically.

**7. Push the new host** (any time later):

```sh
cd ~/nixos-config
nix-shell -p gh --run 'gh auth login'   # GitHub.com → HTTPS → browser; open the URL on your phone
git commit -am "Add host laptop" && git push origin main
```

Until it's pushed, rebuild with `sudo nixos-rebuild switch --flake ~/nixos-config#laptop`.

## Reference

**install.sh prompts**, in order:
- **Disk**: wiped, unless you pick keep-home.
- **Mode**: only for a disk that already has this layout. `w` wipes everything; `k` keeps `/home` and reinstalls the system.
- **Swap** in GiB: default is RAM, capped at 8.
- **User name**: only when installing from a local clone. Enter keeps `user` from `flake.nix`; a new name rewrites that line (staged, commit it later).
- **Hostname**: network name, unique per machine. Separate from the host folder name.
- **Password** for that user: typed twice. Root has no password.
- **Confirmation**: type the disk name.

**Rebuild** (after the host is on GitHub): `up`, which is short for
`sudo nixos-rebuild switch --refresh --flake github:yeetologist/nixos-config#<this host>`.

**User name, timezone:** set once in `flake.nix` (`user`, `timezone`); everything else reads them from there. `install.sh` can change `user` for you when installing from a local clone.

**Rename a machine:** `echo new-name | sudo tee /etc/hostname && sudo reboot` (`hostnamectl` can't write it on NixOS).

**New hardware in the same machine:** regenerate its drivers from inside the repo:
`sudo nixos-generate-config --show-hardware-config --no-filesystems > hosts/<host>/hardware-configuration.nix`

**Gotchas:**
- **Untracked files are invisible to flakes.** Run `git add -A` after creating files.
- **Windows checkouts use CRLF line endings.** Commits are fine. If you copy a working tree to Linux to build it, first run `find . -type f -exec sed -i 's/\r$//' {} +`.
- **Don't copy `hosts/nixos-btw/` into a real machine.** VMware guest tools only work inside VMware.
