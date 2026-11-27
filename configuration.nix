# NixOS system configuration for nixos-btw.
# Options reference: https://search.nixos.org/options
# Manual:           https://nixos.org/manual/nixos/stable/

# `user` and `timezone` are injected via specialArgs in flake.nix.
{ lib, pkgs, config, inputs, user, timezone, ... }:

{
  # ---------------------------------------------------------------------------
  # Nixpkgs
  # ---------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------------------------
  # Boot
  # ---------------------------------------------------------------------------
  boot = {
    loader = {
      systemd-boot = {
        enable             = true;
        consoleMode        = "0"; # use the firmware's native resolution
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    tmp.useTmpfs           = true; # /tmp lives in RAM — cleared on every boot
    kernelPackages = pkgs.linuxPackages_latest;
  };

  services.fstrim.enable = true;

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  networking = {
    hostName           = ""; # per machine: /etc/hostname (install.sh writes it; edit it as root to rename; hostnamectl cannot here)
    enableIPv6         = true;
    networkmanager.enable = true; # manage connections with nmcli / nmtui

    firewall = {
      enable          = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # ---------------------------------------------------------------------------
  # Localisation
  # ---------------------------------------------------------------------------
  time.timeZone      = timezone;
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true; # keep TTY keymap in sync with Xkb layout

  # ---------------------------------------------------------------------------
  # Users
  # ---------------------------------------------------------------------------
  # Disable imperative passwd changes — manage passwords declaratively.
  users.mutableUsers = false;

  users.users.${user} = {
    isNormalUser       = true;
    uid                = 1000; # pinned: mounts in hosts/ take ownership from it
    hashedPasswordFile = "/etc/passwords/${user}";
    extraGroups  = [
      "wheel"          # sudo access
      "networkmanager" # nmcli without sudo
      "audio"          # direct audio device access
      "video"          # camera, GPU, backlight
    ];    
    shell              = pkgs.nushell; # modules/home/nushell.nix (also listed in environment.shells below)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlSLNdvjdJ8JR54lwCXeEkBnfdEXh+wuzZV45dQLlLP"
    ];
  };

  # Root login is disabled; VM-only passwordless emergency shell lives in hosts/nixos-btw/default.nix.
  users.users.root.hashedPassword = "!";


  # ---------------------------------------------------------------------------
  # Environment
  # ---------------------------------------------------------------------------
  environment.variables = {
    EDITOR           = "nvim";
    VISUAL           = "nvim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Use $HOME (not ${HOME}) so pam_env can rewrite it to @{HOME} for early PAM.
  environment.sessionVariables = {
    XDG_CACHE_HOME              = "$HOME/.cache";
    XDG_CONFIG_HOME             = "$HOME/.config";
    XDG_BIN_HOME                = "$HOME/.local/bin";
    XDG_DATA_HOME               = "$HOME/.local/share";
    XDG_STATE_HOME              = "$HOME/.local/state";
    LESSHISTFILE                = "-";
    LESS                        = "-R";
    FZF_DEFAULT_OPTS            = "--layout=reverse --height 40%";
    CARGO_HOME                  = "$HOME/.local/share/cargo";
    GOPATH                      = "$HOME/.local/share/go";
    NODE_REPL_HISTORY           = "$HOME/.local/share/node_repl_history";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  environment.localBinInPath  = true;
  environment.shells          = [ pkgs.nushell ]; # login shell must be in /etc/shells
  environment.defaultPackages = []; # opt-out of the default NixOS package set

  # System-level packages only — prefer home.packages for user tools.
  environment.systemPackages = with pkgs; [
    # Rust drop-in replacement for GNU coreutils in PATH (native nixpkgs, no flake needed)
    (lib.hiPrio uutils-coreutils-noprefix)

    # Network
    wget

    # System inspection
    btop lm_sensors usbutils pciutils fastfetch
  ];

  # ---------------------------------------------------------------------------
  # Fonts
  # ---------------------------------------------------------------------------
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
    ];
    fontconfig.defaultFonts = {
      serif     = [ "Noto Serif" "Noto Color Emoji" ];
      sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      emoji     = [ "Noto Color Emoji" ];
    };
  };

  # ---------------------------------------------------------------------------
  # Audio — Pipewire (PulseAudio + ALSA + JACK compatibility)
  # ---------------------------------------------------------------------------
  services.pipewire = {
    enable       = true;
    alsa.enable  = true;
    pulse.enable = true;
  };

  # ---------------------------------------------------------------------------
  # Wayland / XDG portals
  # niri-flake enables xdg.portal, adds xdg-desktop-portal-gnome (screencast),
  # and ships niri-portals.conf via configPackages; add the GTK portal here.
  # ---------------------------------------------------------------------------
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # ---------------------------------------------------------------------------
  # Desktop — Niri (Wayland compositor)
  # ---------------------------------------------------------------------------
  # niri-flake's own builds need libdisplay-info_0_2, which nixpkgs-unstable removed;
  # use nixpkgs' niri (cached on cache.nixos.org) with the niri-flake module.
  programs.niri.enable  = true;
  programs.niri.package = pkgs.niri;
  programs.dconf.enable = true; # allows GTK apps to persist their settings

  # GUI file manager (Mod+Shift+E) with trash, thumbnails, and removable-drive support
  programs.thunar.enable = true;
  programs.xfconf.enable = true;

  # ---------------------------------------------------------------------------
  # Security
  # ---------------------------------------------------------------------------
  security = {
    polkit.enable = true; # required for privilege escalation in Niri/Wayland
    pam.services.login.enableGnomeKeyring = true; # auto-unlock secrets on login
    pam.services.swaylock = {}; # allow swaylock to authenticate unlocks
  };

  # ---------------------------------------------------------------------------
  # Services
  # ---------------------------------------------------------------------------
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication       = false; # keys only
        KbdInteractiveAuthentication = false;
        PermitRootLogin              = "no";
      };
    };

    gnome.gnome-keyring.enable = true; # secret storage for GUI apps
    udisks2.enable             = true; # removable drive / USB auto-mounting (udiskie, Thunar)
    gvfs.enable                = true; # trash, MTP, network shares in Thunar
    tumbler.enable             = true; # file thumbnails in Thunar

    # btrfs health checks — scrubs read every block and verifies checksums.
    btrfs.autoScrub = {
      enable      = true;
      interval    = "monthly";
      fileSystems = [ "/" ];
    };

    # Automatic btrfs snapshots of /home with timeline-based cleanup.
    snapper.configs.home = {
      SUBVOLUME       = "/home";
      ALLOW_USERS     = [ user ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
    };
  };

  # ---------------------------------------------------------------------------
  # Programs
  # ---------------------------------------------------------------------------
  programs = {
    ssh.enableAskPassword = false; # don't pop up a GUI password dialog for SSH

    # nix-locate: search which package provides a given file path.
    # comma (,): run any nixpkgs binary ad-hoc, e.g.  , cowsay hello
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    command-not-found.enable = false; # replaced by nix-index's hook
  };

  # ---------------------------------------------------------------------------
  # Hardware
  # ---------------------------------------------------------------------------
  hardware.enableRedistributableFirmware = true; # Wi-Fi cards, GPU microcode, etc.

  # ---------------------------------------------------------------------------
  # Nix daemon
  # ---------------------------------------------------------------------------
  nix = {
    # Pin legacy `nix-shell` / <nixpkgs> to the exact flake revision.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];

    # Weekly garbage collection — removes store paths older than 14 days.
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };

    optimise.automatic = true; # hard-link identical files in the store

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store   = true;  # dedupe each new path on write (replaceDependencies copies)
      max-jobs              = "auto"; # parallel builds = number of CPUs
      cores                 = 0;      # each job uses all available cores

      # Binary caches — pre-built closures for community packages.
      substituters = [
        "https://nix-community.cachix.org"
        "https://herdr.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "herdr.cachix.org-1:3nH7IStRsS0ASfdonA0DCRR2ZrSCeWitZ7Kwew0cR4I="
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # State version
  # Set once at install time. Do NOT change — see `man configuration.nix`.
  # ---------------------------------------------------------------------------
  system.stateVersion = "26.05";
}