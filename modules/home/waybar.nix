# modules/home/waybar.nix
{ pkgs, ... }:

let
  herdrBtop = pkgs.writeShellApplication {
    name = "herdr-btop";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      jq
      procps
    ];
    text = ''
      # Find an existing Niri window hosting a live herdr client (not the headless server).
      find_herdr_window() {
        local windows_json pid cur win_id
        windows_json=$(niri msg -j windows 2>/dev/null) || return 1
        while read -r pid; do
          [ -n "$pid" ] || continue
          cur="$pid"
          while [ -n "$cur" ] && [ "$cur" -gt 1 ]; do
            win_id=$(printf '%s' "$windows_json" | jq -r --argjson p "$cur" '[.[] | select(.pid == $p) | .id] | first // empty')
            if [ -n "$win_id" ]; then
              printf '%s\n' "$win_id"
              return 0
            fi
            cur=$(ps -o ppid= -p "$cur" 2>/dev/null | tr -d ' ') || break
          done
        done < <(ps -eo pid=,comm=,args= | awk '$2 == "herdr" && $4 != "server" { print $1 }')
        return 1
      }

      if win_id=$(find_herdr_window); then
        niri msg action focus-window --id "$win_id" >/dev/null 2>&1 || true
      else
        ghostty -e herdr </dev/null >/dev/null 2>&1 &
        # Wait for the herdr server and initial workspace to be ready.
        i=0
        while [ "$i" -lt 50 ]; do
          if herdr workspace list 2>/dev/null | jq -e '.result.workspaces | length > 0' >/dev/null 2>&1; then
            break
          fi
          sleep 0.1
          i=$((i + 1))
        done
      fi

      # Focus an existing btop tab if one is already open; otherwise create one.
      existing_tab=$(herdr tab list 2>/dev/null | jq -r '[.result.tabs[] | select(.label == "btop") | .tab_id] | first // empty' || true)
      if [ -n "$existing_tab" ]; then
        herdr tab focus "$existing_tab" >/dev/null 2>&1
        exit 0
      fi

      tab_id=$(herdr tab create --label btop --focus | jq -r '.result.tab.tab_id')
      pane_id=$(herdr pane list | jq -r --arg tid "$tab_id" '[.result.panes[] | select(.tab_id == $tid) | .pane_id] | first // empty')
      if [ -n "$pane_id" ]; then
        herdr pane run "$pane_id" exec btop >/dev/null 2>&1
      fi
    '';
  };
in
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
        modules-right  = [ "custom/recording" "tray" "cpu" "memory" "network" "bluetooth" "pulseaudio" "battery" "clock" "custom/notifications" "custom/power" ];

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

        # -- Right: Recording badge, system tray, stats, status, stacked clock --
        "custom/recording" = {
          exec           = "sh -c 'p=$(cat /tmp/record-menu.pid 2>/dev/null); [ -n \"$p\" ] && kill -0 \"$p\" 2>/dev/null && echo \"󰑋 REC\"'";
          interval       = 2;
          signal         = 9;
          tooltip        = true;
          tooltip-format = "Recording active — click or press Mod+Alt+R to stop";
          on-click       = "record-menu";
        };

        tray = {
          icon-size = 16;
          spacing   = 8;
        };

        cpu = {
          format         = "󰻠 {usage}%";
          interval       = 2;
          tooltip-format = "CPU: {usage}%\nClick to open btop in herdr";
          on-click       = "${herdrBtop}/bin/herdr-btop";
        };

        memory = {
          format         = "󰍛 {percentage}%";
          interval       = 5;
          tooltip-format = "RAM: {used:0.1f}GiB / {total:0.1f}GiB ({percentage}%)\nClick to open btop in herdr";
          on-click       = "${herdrBtop}/bin/herdr-btop";
        };

        network = {
          format-wifi         = "󰖩 {essid}";
          format-ethernet     = "󰈀 {ipaddr}";
          format-disconnected = "󰖪 Offline";
          tooltip-format      = "{ifname}: {ipaddr}/{cidr}\nClick to configure (nmtui)";
          on-click            = "ghostty --class=com.bam.floating -e nmtui";
        };

        bluetooth = {
          format               = "󰂯 {status}";
          format-connected     = "󰂱 {device_alias}";
          format-disabled      = "";
          format-off           = "";
          format-no-controller = "";
          tooltip-format       = "{controller_alias}\t{controller_address}\n{num_connections} connected";
          on-click             = "blueman-manager";
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

        "custom/notifications" = {
          tooltip        = true;
          format         = "{icon}";
          format-icons   = {
            notification              = "󱅫";
            none                      = "󰂚";
            dnd-notification          = "󰂛";
            dnd-none                  = "󰂛";
            inhibited-notification    = "󱅫";
            inhibited-none            = "󰂚";
            dnd-inhibited-notification = "󰂛";
            dnd-inhibited-none        = "󰂛";
          };
          return-type    = "json";
          exec-if        = "which swaync-client";
          exec           = "swaync-client -swb";
          on-click       = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape         = true;
        };

        "custom/power" = {
          format         = "󰐥";
          tooltip        = true;
          tooltip-format = "Power menu (Mod+X)";
          on-click       = "power-menu";
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

      #tray, #cpu, #memory, #network, #bluetooth, #pulseaudio, #battery, #custom-notifications, #custom-power {
        padding: 0 9px;
        color: #c0caf5;
      }

      #cpu:hover, #memory:hover, #pulseaudio:hover, #network:hover, #bluetooth:hover, #clock:hover, #custom-notifications:hover, #custom-power:hover {
        background-color: rgba(192, 202, 245, 0.08);
      }

      #custom-power {
        padding: 0 12px;
        color: #f7768e;
      }

      #custom-recording {
        padding: 0 10px;
        color: #f7768e;
        font-weight: bold;
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
