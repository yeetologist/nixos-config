# Home Manager configuration for the primary user.
# `user` is injected via extraSpecialArgs in flake.nix.
{ pkgs, config, user, host, ... }:

{
  imports = [
    ./modules/home/bash.nix
    ./modules/home/display-menu.nix
    ./modules/home/git.nix
    ./modules/home/niri.nix
    ./modules/home/nvim.nix
    ./modules/home/rofi.nix
    ./modules/home/waybar.nix
    ./modules/home/mpv.nix
    ./modules/home/yazi.nix
    ./modules/home/starship.nix
    ./modules/home/nushell.nix
    ./modules/home/gh.nix
    ./modules/home/zed.nix
  ];

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  home.username    = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05"; # do NOT change after first activation

  programs.home-manager.enable = true; # let HM manage itself

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # ---------------------------------------------------------------------------
  # User packages
  # System-level tools live in configuration.nix; user-facing apps go here.
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Browser & desktop
    brave
    ghostty            # GPU-accelerated terminal
    papirus-icon-theme # app icons for Waybar taskbar and Rofi
    xwayland-satellite # XWayland for apps that don't support Wayland yet
    swaylock           # Wayland screen locker
    orca               # screen reader
    zathura            # document viewer

    # Clipboard & desktop controls
    wl-clipboard       # wl-copy / wl-paste for Wayland
    playerctl          # MPRIS media control
    brightnessctl      # backlight control
    pavucontrol        # PipeWire/PulseAudio volume mixer (per-app volume & device switching)

    # Development
    gnupg
    nodejs

    # Shell utilities
    tmux
    nnn
    highlight
    tldr

    # Media
    yt-dlp

    # Text processing
    ripgrep file
  ];
}
