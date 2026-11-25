# modules/home/waybar.nix
{ pkgs, ... }:

{
  programs.waybar = {
    enable  = true;
    # package = pkgs.waybar;

    # -------------------------------------------------------------------------
    # Bar layout & modules
    # -------------------------------------------------------------------------
    settings = {
      mainBar = {
        layer    = "top";
        position = "top";
        height   = 32;
        spacing  = 4;

        modules-left   = [ "niri/workspaces" "niri/window" ];
        modules-center = [ "clock" ];
        modules-right  = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

        # -- Left --
        "niri/workspaces" = {
          format = "{name}";
        };
        "niri/window" = {
          max-length = 50;
        };

        # -- Center --
        clock = {
          format          = " {:%H:%M}";
          format-alt      = " {:%Y-%m-%d %H:%M:%S}";
          tooltip-format  = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };

        # -- Right --
        cpu = {
          format   = " {usage}%";
          interval = 2;
        };
        memory = {
          format   = " {}%";
          interval = 5;
        };
        battery = {
          format          = "{icon} {capacity}%";
          format-icons    = [ "" "" "" "" "" ];
          format-charging = " {capacity}%";
          states = { warning = 30; critical = 15; };
        };
        network = {
          format-wifi         = " {essid}";
          format-ethernet     = " {ipaddr}";
          format-disconnected = "󰖪 No Network";
          tooltip-format      = "{ifname}: {ipaddr}/{cidr}";
        };
        pulseaudio = {
          format         = "{icon} {volume}%";
          format-muted   = "󰝟 Muted";
          format-icons   = { default = [ "" "" "" ]; };
          on-click       = "pavucontrol";
        };
        tray = {
          spacing = 8;
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
        background-color: rgba(26, 27, 38, 0.95);
        color: #c0caf5;
      }

      #workspaces button {
        padding: 0 8px;
        color: #565f89;
      }
      #workspaces button.active {
        color: #7aa2f7;
        border-bottom: 2px solid #7aa2f7;
      }

      #clock, #cpu, #memory, #battery, #network, #pulseaudio, #tray {
        padding: 0 10px;
        color: #c0caf5;
      }

      #battery.warning  { color: #e0af68; }
      #battery.critical { color: #f7768e; }
    '';
  };
}
