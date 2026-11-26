# modules/home/record-menu.nix
# Wayland port of dmenurecord: Rofi screen / region / audio recorder on Mod+Alt+R
# using wf-recorder + slurp, with SwayNC notifications and a Waybar REC badge.
{ pkgs, ... }:
let
  recordMenu = pkgs.writeShellApplication {
    name = "record-menu";
    runtimeInputs = with pkgs; [
      wf-recorder
      slurp
      ffmpeg
      libnotify
      procps
      coreutils
    ];
    text = ''
      pidfile="/tmp/record-menu.pid"
      outdir="$HOME/Videos/Recordings"

      signal_bar() {
        pkill -RTMIN+9 -x .waybar-wrapped 2>/dev/null || pkill -RTMIN+9 -x waybar 2>/dev/null || true
      }

      stop_recording() {
        local pid
        pid=$(cat "$pidfile" 2>/dev/null || true)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
          kill -INT "$pid" 2>/dev/null || true
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.2
          done
          if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
          fi
        fi
        rm -f "$pidfile"
        signal_bar
        notify-send "Recording stopped" "Saved in $outdir"
      }

      # If a recording is active, Mod+Alt+R stops it immediately.
      if [[ -f "$pidfile" ]]; then
        pid=$(cat "$pidfile" 2>/dev/null || true)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
          stop_recording
          exit 0
        else
          rm -f "$pidfile"
        fi
      fi

      if pkill -x rofi 2>/dev/null; then
        exit 0
      fi

      choice=$(printf '%s\n' \
        "󰍹  Screen (video only)" \
        "󰍹  Screen + Audio" \
        "󰩭  Region (video only)" \
        "󰩭  Region + Audio" \
        "󰍬  Audio only (FLAC)" \
        | rofi -dmenu -i -p "Record") || exit 0
      [[ -n "$choice" ]] || exit 0

      mkdir -p "$outdir"
      stamp=$(date '+%Y-%m-%d_%H-%M-%S')

      case "$choice" in
        *"Screen (video only)"*)
          out="$outdir/screen-$stamp.mp4"
          nohup wf-recorder -f "$out" >/dev/null 2>&1 &
          ;;
        *"Screen + Audio"*)
          out="$outdir/screencast-$stamp.mp4"
          nohup wf-recorder --audio -f "$out" >/dev/null 2>&1 &
          ;;
        *"Region (video only)"*)
          geom=$(slurp) || exit 0
          out="$outdir/region-$stamp.mp4"
          nohup wf-recorder -g "$geom" -f "$out" >/dev/null 2>&1 &
          ;;
        *"Region + Audio"*)
          geom=$(slurp) || exit 0
          out="$outdir/region-audio-$stamp.mp4"
          nohup wf-recorder --audio -g "$geom" -f "$out" >/dev/null 2>&1 &
          ;;
        *"Audio only"*)
          out="$outdir/audio-$stamp.flac"
          nohup ffmpeg -y -f pulse -i default -c:a flac "$out" >/dev/null 2>&1 &
          ;;
        *)
          exit 0
          ;;
      esac

      echo "$!" > "$pidfile"
      signal_bar
      notify-send "Recording started" "$(basename "$out")"
    '';
  };
in
{
  home.packages = [ recordMenu ];

  programs.niri.settings.binds."Mod+Alt+R" = {
    hotkey-overlay.title = "Record screen / region / audio";
    action.spawn = [ "record-menu" ];
    repeat = false;
  };
}
