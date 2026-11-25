{ pkgs, ... }:

{
  programs.rofi = {
    enable   = true;
    # package  = pkgs.rofi-wayland; # Wayland-native fork
    theme    = "gruvbox-dark"; # run `rofi-theme-selector` to preview others

    settings = {
      terminal            = "ghostty";
      font                = "JetBrainsMono Nerd Font 12";
      modi                = "drun,run,window";
      show-icons          = true;
      icon-theme          = "Papirus-Dark";
      drun-display-format = "{name}";
      display-drun        = " Apps";
      display-run         = " Run";
      display-window      = " Windows";
      kb-cancel           = "Escape,Super+d"; # same key that opens it
    };
  };
}
