# modules/home/desktop.nix
# Everyday Windows-style desktop services, menus, idle/lock, dark theme, and wallpaper.
{ pkgs, ... }:
let
  powerMenu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = with pkgs; [
      procps
      systemd
    ];
    text = ''
      if pkill -x rofi 2>/dev/null; then
        exit 0
      fi

      choice=$(printf '%s\n' \
        "󰌾  Lock" \
        "󰤄  Suspend" \
        "󰍃  Log out (Quit Niri)" \
        "󰜉  Reboot" \
        "󰐥  Shut down" \
        | rofi -dmenu -i -p "Power") || exit 0

      case "$choice" in
        *"Lock"*)      swaylock -f ;;
        *"Suspend"*)   systemctl suspend ;;
        *"Log out"*)   niri msg action quit --skip-confirmation ;;
        *"Reboot"*)    systemctl reboot ;;
        *"Shut down"*) systemctl poweroff ;;
      esac
    '';
  };

  clipboardMenu = pkgs.writeShellApplication {
    name = "clipboard-menu";
    runtimeInputs = with pkgs; [
      cliphist
      wl-clipboard
      procps
    ];
    text = ''
      if pkill -x rofi 2>/dev/null; then
        exit 0
      fi

      choice=$(cliphist list | rofi -dmenu -i -p "Clipboard") || exit 0
      [[ -n "$choice" ]] || exit 0
      printf '%s\n' "$choice" | cliphist decode | wl-copy
    '';
  };

  toggleNightLight = pkgs.writeShellApplication {
    name = "toggle-night-light";
    runtimeInputs = with pkgs; [ systemd ];
    text = ''
      if systemctl --user is-active --quiet wlsunset.service; then
        systemctl --user stop wlsunset.service
      else
        systemctl --user start wlsunset.service
      fi
    '';
  };
in
{
  home.packages = with pkgs; [
    powerMenu
    clipboardMenu
    toggleNightLight
    loupe    # Wayland image viewer (PNG/JPG/WebP/GIF/SVG/AVIF)
    rofimoji # emoji picker (Mod+.)
    wtype    # Wayland typing backend for rofimoji
    swaybg   # Wayland wallpaper daemon
  ];

  # ---------------------------------------------------------------------------
  # Default applications (XDG MIME associations)
  # ---------------------------------------------------------------------------
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png"              = "org.gnome.Loupe.desktop";
      "image/jpeg"             = "org.gnome.Loupe.desktop";
      "image/gif"              = "org.gnome.Loupe.desktop";
      "image/webp"             = "org.gnome.Loupe.desktop";
      "image/bmp"              = "org.gnome.Loupe.desktop";
      "image/tiff"             = "org.gnome.Loupe.desktop";
      "image/avif"             = "org.gnome.Loupe.desktop";
      "image/svg+xml"          = "org.gnome.Loupe.desktop";
      "application/pdf"        = "org.pwmt.zathura.desktop";
      "video/mp4"              = "mpv.desktop";
      "video/x-matroska"       = "mpv.desktop";
      "video/webm"             = "mpv.desktop";
      "video/quicktime"        = "mpv.desktop";
      "video/x-msvideo"        = "mpv.desktop";
      "audio/mpeg"             = "mpv.desktop";
      "audio/flac"             = "mpv.desktop";
      "audio/ogg"              = "mpv.desktop";
      "audio/wav"              = "mpv.desktop";
      "audio/mp4"              = "mpv.desktop";
      "inode/directory"        = "thunar.desktop";
      "text/html"              = "brave-browser.desktop";
      "x-scheme-handler/http"  = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
    };
  };

  # ---------------------------------------------------------------------------
  # Notifications & Action Center (SwayNC — Mod+N)
  # ---------------------------------------------------------------------------
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 420;
      notification-window-width = 380;
      timeout = 6;
      timeout-low = 4;
      timeout-critical = 0;
      widgets = [
        "title"
        "dnd"
        "buttons-grid"
        "notifications"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        "buttons-grid" = {
          actions = [
            {
              label = "󰖔 Night";
              type = "toggle";
              active = true;
              command = "toggle-night-light";
              update-command = "systemctl --user is-active --quiet wlsunset.service && echo true || echo false";
            }
            {
              label = "󰖩 Wi-Fi";
              command = "swaync-client -cp && ghostty --class=com.bam.floating -e nmtui";
            }
            {
              label = "󰍹 Display";
              command = "swaync-client -cp && display-menu";
            }
            {
              label = "󰕾 Audio";
              command = "swaync-client -cp && (pkill -x pavucontrol || pavucontrol)";
            }
            {
              label = "󰐥 Power";
              command = "swaync-client -cp && power-menu";
            }
          ];
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Clipboard history (cliphist — Mod+V)
  # ---------------------------------------------------------------------------
  services.cliphist.enable = true;

  # ---------------------------------------------------------------------------
  # Idle & auto-lock (swayidle + swaylock)
  # Laptop auto-suspend (30 min) is added in hosts/tuf/home.nix.
  # ---------------------------------------------------------------------------
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      {
        timeout = 300; # 5 min: lock screen
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600; # 10 min: power off monitors
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
    ];
  };

  # ---------------------------------------------------------------------------
  # Night Light (wlsunset — automatic 4000K at night, toggleable in SwayNC)
  # ---------------------------------------------------------------------------
  services.wlsunset = {
    enable = true;
    sunrise = "06:00";
    sunset = "19:00";
    temperature = {
      day = 6500;
      night = 4000;
    };
  };

  # ---------------------------------------------------------------------------
  # Tray applets: Wi-Fi (nm-applet) & USB auto-mount (udiskie)
  # Bluetooth (blueman-applet) is enabled in hosts/tuf/home.nix.
  # ---------------------------------------------------------------------------
  services.network-manager-applet.enable = true;
  services.udiskie = {
    enable = true;
    tray = "auto"; # only appears in tray when a removable drive is mounted
  };

  # ---------------------------------------------------------------------------
  # Global dark theme (GTK + dconf + Qt; prefer-dark is already set in home.nix)
  # ---------------------------------------------------------------------------
  gtk = {
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "Adwaita-dark";
    icon-theme = "Papirus-Dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
