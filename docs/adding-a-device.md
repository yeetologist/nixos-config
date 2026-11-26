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

## Gotchas

- **Untracked files are invisible**: a flake only sees files git knows about. After
  creating files, run `git add -A` before building or installing from a local clone.
- **Windows line endings**: a checkout on Windows uses CRLF. Commits are fine, because
  git converts them to LF. If you copy the working tree to Linux to build it, strip
  the CR characters first (`find . -type f -exec sed -i 's/\r$//' {} +`), or the shell
  scripts inside the config break.
- **Same hardware, same host**: a second laptop of the same model uses the existing
  host folder ([Path A](#path-a-existing-host-just-install)). Give it a different hostname at the prompt.
