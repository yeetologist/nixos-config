# modules/home/display-menu.nix
# Windows Win+P style display switcher + resolution/scale/rotation/position
# picker for niri, driven by Rofi and `niri msg output`.
{ pkgs, ... }:
let
  displayMenu = pkgs.writeShellApplication {
    name = "display-menu";
    runtimeInputs = with pkgs; [
      jq
      wl-mirror
      procps
      coreutils
      gawk
    ];
    text = ''
      # Pressing Mod+P while the menu is already open closes it.
      if pkill -x rofi 2>/dev/null; then
        exit 0
      fi

      menu() {
        local prompt="$1"
        local items="$2"
        printf '%s\n' "$items" | rofi -dmenu -i -p "$prompt"
      }

      stop_mirror() {
        pkill -x wl-mirror 2>/dev/null || true
      }

      outputs_json=$(niri msg --json outputs)
      mapfile -t all_outputs < <(printf '%s' "$outputs_json" | jq -r 'keys[]')

      if (( ''${#all_outputs[@]} == 0 )); then
        exit 0
      fi

      # Prefer an internal laptop panel as primary; otherwise use the first output.
      primary=""
      for o in "''${all_outputs[@]}"; do
        case "$o" in
          eDP-*|LVDS-*|DSI-*)
            primary="$o"
            break
            ;;
        esac
      done
      if [[ -z "$primary" ]]; then
        primary="''${all_outputs[0]}"
      fi

      externals=()
      for o in "''${all_outputs[@]}"; do
        if [[ "$o" != "$primary" ]]; then
          externals+=("$o")
        fi
      done

      pick_output() {
        local prompt="$1"
        if (( ''${#all_outputs[@]} == 1 )); then
          printf '%s\n' "''${all_outputs[0]}"
          return 0
        fi
        local list choice
        list=$(printf '%s' "$outputs_json" | jq -r '
          to_entries[] |
          if .value.logical == null then
            "\(.key)  (off)"
          else
            "\(.key)  (\(.value.logical.width)x\(.value.logical.height) @ \(.value.logical.scale)x)"
          end
        ')
        choice=$(menu "$prompt" "$list") || return 1
        [[ -n "$choice" ]] || return 1
        printf '%s\n' "''${choice%% *}"
      }

      pick_mode() {
        local out list choice mode
        out=$(pick_output "Resolution: display") || exit 0
        list=$(printf '%s' "$outputs_json" | jq -r --arg o "$out" '
          def fmt_hz:
            ((. / 1000) | floor | tostring) + "." +
            (((. % 1000) | tostring) | ("000" + .) | .[-3:]);
          .[$o] as $d |
          "auto",
          ($d.modes | to_entries[] |
            "\(.value.width)x\(.value.height)@\(.value.refresh_rate | fmt_hz)" +
            (if .key == $d.current_mode then "  *" else "" end) +
            (if .value.is_preferred then "  (preferred)" else "" end)
          )
        ')
        choice=$(menu "Resolution ($out)" "$list") || exit 0
        [[ -n "$choice" ]] || exit 0
        mode="''${choice%% *}"
        niri msg output "$out" on
        niri msg output "$out" mode "$mode"
      }

      pick_scale() {
        local out current list choice scale
        out=$(pick_output "Scale: display") || exit 0
        current=$(printf '%s' "$outputs_json" | jq -r --arg o "$out" '.[$o].logical.scale // empty')
        list="auto"
        for s in 1 1.25 1.5 1.75 2 2.5 3; do
          if [[ -n "$current" ]] && awk -v a="$current" -v b="$s" 'BEGIN { exit !(a == b) }'; then
            list+=$'\n'"$s  *"
          else
            list+=$'\n'"$s"
          fi
        done
        choice=$(menu "Scale ($out)" "$list") || exit 0
        [[ -n "$choice" ]] || exit 0
        scale="''${choice%% *}"
        niri msg output "$out" scale "$scale"
      }

      pick_rotation() {
        local out raw_t current list choice transform
        out=$(pick_output "Rotation: display") || exit 0
        raw_t=$(printf '%s' "$outputs_json" | jq -r --arg o "$out" '.[$o].logical.transform // ""')
        case "$raw_t" in
          Normal)     current="normal" ;;
          _90)        current="90" ;;
          _180)       current="180" ;;
          _270)       current="270" ;;
          Flipped)    current="flipped" ;;
          Flipped90)  current="flipped-90" ;;
          Flipped180) current="flipped-180" ;;
          Flipped270) current="flipped-270" ;;
          *)          current="" ;;
        esac

        list=""
        for entry in \
          "normal|0° (landscape)" \
          "90|90° CCW" \
          "180|180° (upside down)" \
          "270|270° CCW" \
          "flipped|Flipped horizontal" \
          "flipped-90|Flipped + 90°" \
          "flipped-180|Flipped vertical" \
          "flipped-270|Flipped + 270°"; do
          local key="''${entry%%|*}"
          local desc="''${entry#*|}"
          local line="$key  — $desc"
          if [[ "$key" == "$current" ]]; then
            line+="  *"
          fi
          if [[ -z "$list" ]]; then
            list="$line"
          else
            list+=$'\n'"$line"
          fi
        done

        choice=$(menu "Rotation ($out)" "$list") || exit 0
        [[ -n "$choice" ]] || exit 0
        transform="''${choice%% *}"
        niri msg output "$out" transform "$transform"
      }

      pick_position() {
        local target ref choice
        if (( ''${#externals[@]} == 1 )); then
          target="''${externals[0]}"
          ref="$primary"
        else
          target=$(pick_output "Move which display?") || exit 0
          if [[ "$target" == "$primary" ]]; then
            ref="''${externals[0]}"
          else
            ref="$primary"
          fi
        fi

        choice=$(menu "Position $target relative to $ref" $'auto\nRight of '"$ref"$'\nLeft of '"$ref"$'\nAbove '"$ref"$'\nBelow '"$ref") || exit 0
        [[ -n "$choice" ]] || exit 0

        stop_mirror
        niri msg output "$ref" on
        niri msg output "$target" on

        if [[ "$choice" == "auto" ]]; then
          niri msg output "$target" position auto
          exit 0
        fi

        # Re-read logical geometry after ensuring both displays are on.
        outputs_json=$(niri msg --json outputs)
        local rx ry rw rh tw th nx ny
        read -r rx ry rw rh < <(printf '%s' "$outputs_json" | jq -r --arg o "$ref" '.[$o].logical | "\(.x) \(.y) \(.width) \(.height)"')
        read -r tw th < <(printf '%s' "$outputs_json" | jq -r --arg o "$target" '.[$o].logical | "\(.width) \(.height)"')

        case "$choice" in
          Right*) nx=$((rx + rw)); ny=$ry ;;
          Left*)  nx=$((rx - tw)); ny=$ry ;;
          Above*) nx=$rx; ny=$((ry - th)) ;;
          Below*) nx=$rx; ny=$((ry + rh)) ;;
          *)      exit 0 ;;
        esac

        niri msg output "$target" position set -- "$nx" "$ny"
      }

      # Build main menu
      items=""
      if (( ''${#externals[@]} >= 1 )); then
        first_ext="''${externals[0]}"
        if pgrep -x wl-mirror >/dev/null 2>&1; then
          dup_label="󰍺  Stop duplicate (wl-mirror)"
        else
          dup_label="󰍺  Duplicate ($primary -> $first_ext)"
        fi
        items+="󰌢  PC screen only ($primary)"$'\n'
        items+="$dup_label"$'\n'
        items+="󰍹  Extend"$'\n'
        items+="󰶐  Second screen only ($first_ext)"$'\n'
      fi

      items+="󰹑  Resolution & refresh rate..."$'\n'
      items+="󰘖  Scale..."$'\n'
      items+="󰑵  Rotation..."
      if (( ''${#externals[@]} >= 1 )); then
        items+=$'\n'"󰆾  Position..."
      fi

      choice=$(menu "Display" "$items") || exit 0
      [[ -n "$choice" ]] || exit 0

      case "$choice" in
        *"PC screen only"*)
          stop_mirror
          niri msg output "$primary" on
          for ext in "''${externals[@]}"; do
            niri msg output "$ext" off
          done
          ;;
        *"Stop duplicate"*)
          stop_mirror
          ;;
        *"Duplicate"*)
          stop_mirror
          niri msg output "$primary" on
          niri msg output "$first_ext" on
          niri msg output "$first_ext" position auto
          sleep 0.3
          nohup wl-mirror --fullscreen-output "$first_ext" "$primary" >/dev/null 2>&1 &
          ;;
        *"Extend"*)
          stop_mirror
          niri msg output "$primary" on
          for ext in "''${externals[@]}"; do
            niri msg output "$ext" on
            niri msg output "$ext" position auto
          done
          ;;
        *"Second screen only"*)
          stop_mirror
          for ext in "''${externals[@]}"; do
            niri msg output "$ext" on
            niri msg output "$ext" position auto
          done
          niri msg output "$primary" off
          ;;
        *"Resolution"*)
          pick_mode
          ;;
        *"Scale"*)
          pick_scale
          ;;
        *"Rotation"*)
          pick_rotation
          ;;
        *"Position"*)
          pick_position
          ;;
      esac
    '';
  };
in
{
  home.packages = [ displayMenu ];

  programs.niri.settings.binds."Mod+P" = {
    hotkey-overlay.title = "Display menu (Win+P)";
    action.spawn = [ "display-menu" ];
    repeat = false;
  };
}
