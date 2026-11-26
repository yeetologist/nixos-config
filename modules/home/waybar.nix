# modules/home/waybar.nix
{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    # -------------------------------------------------------------------------
    # Bar layout & modules (Windows-style bottom taskbar)
    # -------------------------------------------------------------------------
    settings = {
      mainBar = {
        layer    = "top";
        position = "top";
        height   = 40;
        spacing  = 2;

        modules-left   = [ "custom/launcher" "niri/workspaces" "wlr/taskbar" ];
        modules-center = [ ];
        modules-right  = [ "tray" "cpu" "memory" "network" "pulseaudio" "battery" "clock" ];

        # -- Left: Start button, workspaces, open windows taskbar --
        "custom/launcher" = {
          format   = "󱄅";
          tooltip  = true;
          tooltip-format = "Applications (Mod+D)";
          on-click = "rofi -show drun";
        };

        "niri/workspaces" = {
          format = "{index}";
        };

        "wlr/taskbar" = {
          format          = "{icon} {title:.22}";
          icon-size       = 18;
          icon-theme      = "Papirus-Dark";
          tooltip-format  = "{title}";
          on-click        = "activate";
          on-click-middle = "close";
          ignore-list     = [ ];
        };

        # -- Right: System tray, stats, status, stacked clock --
        tray = {
          icon-size = 16;
          spacing   = 8;
        };

        cpu = {
          format   = "󰻠 {usage}%";
          interval = 2;
        };

        memory = {
          format   = "󰍛 {percentage}%";
          interval = 5;
        };

        network = {
          format-wifi         = "󰖩 {essid}";
          format-ethernet     = "󰈀 {ipaddr}";
          format-disconnected = "󰖪 Offline";
          tooltip-format      = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format           = "{icon} {volume}%";
          format-muted     = "󰝟 Muted";
          format-icons     = { default = [ "󰕿" "󰖀" "󰕾" ]; };
          on-click         = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right   = "pkill -x pavucontrol || pavucontrol";
          scroll-step      = 5;
        };

        battery = {
          format          = "{icon} {capacity}%";
          format-icons    = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
          format-charging = "󰂄 {capacity}%";
          states          = { warning = 30; critical = 15; };
        };

        clock = {
          format         = "{:%H:%M\n%Y-%m-%d}";
          format-alt     = "{:%H:%M:%S\n%a %b %d}";
          tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Styling (CSS)
    # -------------------------------------------------------------------------
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0.96);
        color: #c0caf5;
        border-bottom: 1px solid #292e42;
      }

      #custom-launcher {
        padding: 0 14px;
        font-size: 18px;
        color: #7aa2f7;
      }
      #custom-launcher:hover {
        background-color: rgba(122, 162, 247, 0.16);
      }

      #workspaces {
        margin: 0 4px;
        border-right: 1px solid #292e42;
        padding-right: 4px;
      }
      #workspaces button {
        padding: 0 8px;
        color: #565f89;
      }
      #workspaces button:hover {
        background-color: rgba(192, 202, 245, 0.08);
        color: #c0caf5;
      }
      #workspaces button.active {
        color: #7aa2f7;
        border-bottom: 2px solid #7aa2f7;
      }

      #taskbar {
        margin-left: 4px;
      }
      #taskbar button {
        padding: 0 10px;
        margin: 3px 2px;
        border-radius: 4px;
        color: #a9b1d6;
        background-color: rgba(41, 46, 66, 0.45);
        border-bottom: 2px solid transparent;
      }
      #taskbar button:hover {
        background-color: rgba(122, 162, 247, 0.18);
        color: #c0caf5;
      }
      #taskbar button.active {
        background-color: rgba(122, 162, 247, 0.22);
        color: #ffffff;
        border-bottom: 2px solid #7aa2f7;
      }

      #tray, #cpu, #memory, #network, #pulseaudio, #battery {
        padding: 0 9px;
        color: #c0caf5;
      }

      #pulseaudio:hover, #network:hover, #clock:hover {
        background-color: rgba(192, 202, 245, 0.08);
      }

      #clock {
        padding: 2px 12px;
        font-size: 12px;
        color: #c0caf5;
      }

      #battery.warning  { color: #e0af68; }
      #battery.critical { color: #f7768e; }
    '';
  };
}
