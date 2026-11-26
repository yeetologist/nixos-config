# Adding a new device

A **host** is one *kind* of machine (the VMware VM, a laptop model). Each host is a
folder under `hosts/` plus one entry in `flake.nix`. Everything else
(`configuration.nix`, `home.nix`, `modules/home/`) is shared by every host.

| Situation | What to do |
|---|---|
| Another machine of a kind that already has a host (e.g. another VMware VM) | Skip to [Install](#4-install). No repo changes. |
| A new kind of machine (new laptop model, desktop) | Follow every step once. Later machines of that kind only need [Install](#4-install). |

## 1. Detect the hardware

Boot the NixOS installer ISO on the new machine. Get online (`nmtui` for wifi), then run:

```sh
nixos-generate-config --show-hardware-config --no-filesystems
```

This prints the drivers the machine needs: initrd modules such as `nvme` and `xhci_pci`,
kernel modules and CPU microcode. `--no-filesystems` leaves disks out, because every
host uses the same label-based layout that `install.sh` creates.

To get the output off the machine, run `passwd` on the ISO and `scp` it to your PC,
or paste it into a gist.

## 2. Add the host folder

Pick a short name, e.g. `laptop`. The VM's folder, `hosts/vm/`, is the example to copy.

```
hosts/laptop/
├── default.nix                 # imports the file below + hardware-specific settings
└── hardware-configuration.nix  # step 1's output + the disk block from hosts/vm
```

**`hardware-configuration.nix`**: paste the step 1 output. Then copy the
`fileSystems."/"`, `"/home"`, `"/nix"`, `"/boot"` and `swapDevices` blocks from
`hosts/vm/hardware-configuration.nix` unchanged. They point at the labels `nixos`,
`BOOT` and `swap`, which `install.sh` creates on every machine.

**`default.nix`**: start from this and add only what the hardware needs:

```nix
{ pkgs, user, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Examples, keep what applies:
  # hardware.graphics.enable = true;            # GPU acceleration
  # hardware.nvidia.open = true;                # plus services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.bluetooth.enable = true;
  # services.power-profiles-daemon.enable = true; # laptop battery profiles

  # Host-only Home Manager settings, if any (see hosts/vm/home.nix):
  # home-manager.users.${user}.imports = [ ./home.nix ];
}
```

Leave out everything from `hosts/vm/`. Those settings (VMware guest tools, vmblock,
`/mnt/hgfs`, clipboard sync) only work inside VMware.

## 3. Add the flake entry

`flake.nix` builds one host, `nixos-btw`. For a second host, move the
`nixosSystem` call into a small function in the existing `let` block (next to
`user`, `system`, `timezone`), and call it once per host:

```nix
  let
    user     = "bam";
    system   = "x86_64-linux";
    timezone = "Asia/Jakarta";

    mkHost = hostModule: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs user timezone system; };
      modules = [
        ./configuration.nix
        hostModule
        inputs.niri.nixosModules.niri
        nix-index-database.nixosModules.nix-index
        home-manager.nixosModules.home-manager { /* unchanged home-manager block */ }
      ];
    };
  in {
    nixosConfigurations.nixos-btw = mkHost ./hosts/vm;
    nixosConfigurations.laptop    = mkHost ./hosts/laptop;
  };
```

Commit and push to `main`: the install and rebuild commands below fetch from GitHub, not your local copy. Only machine and nowhere to push from? See [installing from a local clone](#only-one-machine-install-from-a-local-clone-push-later).

## 4. Install

From the installer ISO, as root:

```sh
FLAKE=github:yeetologist/nixos-config#laptop \
  bash <(curl -sL https://raw.githubusercontent.com/yeetologist/nixos-config/main/install.sh)
```

Leave out `FLAKE=…` to install the default host, `nixos-btw` (the VM). The script asks for:

1. **Disk**: from a list. It is wiped, unless you choose keep-home on a disk that already has this layout.
2. **Mode**: only for a disk that already has this layout. Choose wipe, or keep `/home` and reinstall the system.
3. **Swap size**: defaults to RAM, capped at 8 GiB.
4. **Hostname**: unique per machine, written to `/etc/hostname`. The flake leaves it unset.
5. **Password for `bam`**: typed twice. Root is locked.
6. **Confirmation**: type the disk name.

Reboot. Log in on tty1 and niri starts automatically.

### Only one machine: install from a local clone, push later

If the new machine is your only one, you can't easily push the new host from
somewhere else first. Do steps 1–3 on the ISO itself and install from the clone:

```sh
nix-shell -p git                       # if the ISO has no git
git clone https://github.com/yeetologist/nixos-config -b main /tmp/nixos-config
cd /tmp/nixos-config
nixos-generate-config --show-hardware-config --no-filesystems   # step 1, paste into hosts/laptop/
#   ... create hosts/laptop/ and the flake entry (steps 2-3) with nano/vim ...
git add -A                             # required: a flake can't see untracked files
FLAKE=/tmp/nixos-config#laptop bash /tmp/nixos-config/install.sh
```

No commit or GitHub login is needed for this. `git add` is enough, and the script
refuses to start if anything is still untracked. After installing, it copies the clone
to `~/nixos-config` on the new system, because `/tmp` on the ISO is lost at reboot.
If `~/nixos-config` already exists (keep-home reinstall), it copies to
`~/nixos-config.install-<date>` instead.

After the first boot, rebuild from that folder until you push:

```sh
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

When you're ready, log in to GitHub (`gh auth login` or an SSH key), then
`git commit` and `git push` from `~/nixos-config`. From then on, the GitHub commands
in this doc work for this host too.

## 5. Day to day

Rebuild with the machine's host name (the flake attribute, not its hostname):

```sh
sudo nixos-rebuild switch --refresh --flake github:yeetologist/nixos-config#laptop
```

The `up` alias in `home.nix` rebuilds `#nixos-btw`. On other hosts, type the full
command above, or make the alias host-specific.

To rename a machine, edit `/etc/hostname` as root and reboot. `hostnamectl` cannot
write it on NixOS.

## Gotchas

- **Line endings**: on Windows the checkout uses CRLF. Commits are fine because git
  converts them to LF. Before building a copy of the working tree on Linux, strip
  the CR characters (`sed -i 's/\r$//'`), or shell scripts inside the config break.
- **Flakes only see files git tracks**: `git add` a new host folder before building it locally.
- **Same hardware, same host**: a second laptop of the same model needs no new folder.
  Only add a host when the drivers differ.
