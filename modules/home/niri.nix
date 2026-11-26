{ ... }:
{
  programs.niri.settings = {
    prefer-no-csd = true; # use server-side decorations instead of drawing their own title bars
    animations.enable = false; # Disables ALL animations in niri
    hotkey-overlay.hide-not-bound = true;

    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
      };
      mouse = {
        accel-profile = "flat";
      };
    };

    layout = {
      default-column-width = { proportion = 0.5; };
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
        { proportion = 1.0 / 1.0; }
      ];
      focus-ring.enable = false;
      border.enable = false;
      gaps = 0; # no gaps between windows/columns
      struts = {
        left   = 0; # no screen-edge padding
        right  = 0;
        top    = 0;
        bottom = 0;
      };
    };

    window-rules = [
      {
        matches = [ { app-id = "^org\\.pulseaudio\\.pavucontrol$"; } ];
        open-floating = true;
        default-column-width = { fixed = 760; };
        default-window-height = { fixed = 540; };
      }
      {
        matches = [ { app-id = "^com\\.bam\\.floating$"; } ];
        open-floating = true;
        default-column-width = { fixed = 1000; };
        default-window-height = { fixed = 700; };
      }
    ];

    spawn-at-startup = [
      {
        command = [
          "waybar"
        ];
      }
      {
        # Solid dark background; swap "-c" "#1a1b26" for "-i" "/path/to/img.png" "-m" "fill" anytime.
        command = [
          "swaybg"
          "-c"
          "#1a1b26"
        ];
      }
    ];

    binds = {
      # Hotkey help overlay (custom 3-column cheatsheet is bound in modules/home/hotkey-overlay.nix)
      "Mod+Ctrl+Shift+Slash" = {
        hotkey-overlay.title = "Show built-in Niri hotkey overlay";
        action.show-hotkey-overlay = [ ];
      };

      # Application spawning
      "Mod+T" = {
        hotkey-overlay.title = "Open terminal (Ghostty)";
        action.spawn = "ghostty";
      };
      "Mod+D" = {
        hotkey-overlay.title = "App launcher (Rofi)";
        action.spawn = [ "rofi" "-show" "drun" ];
      };
      "Alt+Tab" = {
        hotkey-overlay.title = "Window switcher (Alt+Tab)";
        action.spawn = [ "rofi" "-show" "window" ];
        repeat = false;
      };
      "Mod+E" = {
        hotkey-overlay.title = "File manager (yazi)";
        action.spawn = [ "ghostty" "-e" "yazi" ];
      };
      "Mod+Shift+E" = {
        hotkey-overlay.title = "File manager (Thunar)";
        action.spawn = "thunar";
      };
      "Ctrl+Shift+Escape" = {
        hotkey-overlay.title = "Task Manager (btop)";
        action.spawn = [ "ghostty" "--class=com.bam.floating" "-e" "btop" ];
        repeat = false;
      };
      "Mod+N" = {
        hotkey-overlay.title = "Notification center (SwayNC)";
        action.spawn = [ "swaync-client" "-t" "-sw" ];
        repeat = false;
      };
      "Mod+V" = {
        hotkey-overlay.title = "Clipboard history (Win+V)";
        action.spawn = [ "clipboard-menu" ];
        repeat = false;
      };
      "Mod+Period" = {
        hotkey-overlay.title = "Emoji picker (Win+.)";
        action.spawn = [ "rofimoji" "--selector" "rofi" "--action" "type" "copy" ];
        repeat = false;
      };
      "Mod+X" = {
        hotkey-overlay.title = "Power menu (Win+X)";
        action.spawn = [ "power-menu" ];
        repeat = false;
      };
      "Mod+B" = {
        hotkey-overlay.title = "Toggle Waybar show / hide";
        action.spawn-sh = "pkill -USR1 -x .waybar-wrapped || pkill -USR1 -x waybar || waybar";
        repeat = false;
      };
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock screen (Mod+Alt+L)";
        action.spawn = "swaylock";
        repeat = false;
      };

      "Super+Alt+S" = {
        hotkey-overlay.title = "Toggle screen reader (Orca)";
        action.spawn-sh = "pkill orca || exec orca";
        allow-when-locked = true;
      };

      # Audio controls (PipeWire / WirePlumber)
      "Mod+Ctrl+V" = {
        hotkey-overlay.title = "Audio mixer (pavucontrol)";
        action.spawn-sh = "pkill -x pavucontrol || pavucontrol";
        repeat = false;
      };
      "XF86AudioRaiseVolume" = {
        hotkey-overlay.title = "Volume +10%";
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        hotkey-overlay.title = "Volume -10%";
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        hotkey-overlay.title = "Mute audio";
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        hotkey-overlay.title = "Mute microphone";
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        allow-when-locked = true;
      };

      # Media controls (playerctl)
      "XF86AudioPlay" = {
        hotkey-overlay.title = "Media play / pause";
        action.spawn-sh = "playerctl play-pause";
        allow-when-locked = true;
      };
      "XF86AudioPause" = {
        action.spawn-sh = "playerctl play-pause";
        allow-when-locked = true;
      };
      "XF86AudioStop" = {
        hotkey-overlay.title = "Media stop";
        action.spawn-sh = "playerctl stop";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        hotkey-overlay.title = "Media previous";
        action.spawn-sh = "playerctl previous";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        hotkey-overlay.title = "Media next";
        action.spawn-sh = "playerctl next";
        allow-when-locked = true;
      };

      # Monitor Brightness controls (Must be a list in the new syntax)
      "XF86MonBrightnessUp" = {
        hotkey-overlay.title = "Brightness +10%";
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "+10%"
        ];
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        hotkey-overlay.title = "Brightness -10%";
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "10%-"
        ];
        allow-when-locked = true;
      };

      # Window management execution
      "Mod+O" = {
        hotkey-overlay.title = "Toggle overview";
        action.toggle-overview = [ ];
        repeat = false;
      };
      "Mod+Q" = {
        hotkey-overlay.title = "Close window";
        action.close-window = [ ];
        repeat = false;
      };

      # Directional window / workspace focus (Vim HJKL primary, Arrows as aliases)
      "Mod+H" = { hotkey-overlay.title = "Focus column left";               action.focus-column-left = [ ]; };
      "Mod+J" = { hotkey-overlay.title = "Focus window or workspace down";  action.focus-window-or-workspace-down = [ ]; };
      "Mod+K" = { hotkey-overlay.title = "Focus window or workspace up";    action.focus-window-or-workspace-up = [ ]; };
      "Mod+L" = { hotkey-overlay.title = "Focus column right";              action.focus-column-right = [ ]; };
      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Down".action.focus-window-or-workspace-down = [ ];
      "Mod+Up".action.focus-window-or-workspace-up = [ ];
      "Mod+Right".action.focus-column-right = [ ];

      # Moving windows / columns (i3/Vim style: Mod+Shift+HJKL, Arrows as aliases)
      "Mod+Shift+H" = { hotkey-overlay.title = "Move column left";                     action.move-column-left = [ ]; };
      "Mod+Shift+J" = { hotkey-overlay.title = "Move window down / to workspace down"; action.move-window-down-or-to-workspace-down = [ ]; };
      "Mod+Shift+K" = { hotkey-overlay.title = "Move window up / to workspace up";     action.move-window-up-or-to-workspace-up = [ ]; };
      "Mod+Shift+L" = { hotkey-overlay.title = "Move column right";                    action.move-column-right = [ ]; };
      "Mod+Shift+Left".action.move-column-left = [ ];
      "Mod+Shift+Down".action.move-window-down-or-to-workspace-down = [ ];
      "Mod+Shift+Up".action.move-window-up-or-to-workspace-up = [ ];
      "Mod+Shift+Right".action.move-column-right = [ ];

      # Structural column boundaries
      "Mod+Home"       = { hotkey-overlay.title = "Focus first column";   action.focus-column-first = [ ]; };
      "Mod+End"        = { hotkey-overlay.title = "Focus last column";    action.focus-column-last = [ ]; };
      "Mod+Shift+Home" = { hotkey-overlay.title = "Move column to first"; action.move-column-to-first = [ ]; };
      "Mod+Shift+End"  = { hotkey-overlay.title = "Move column to last";  action.move-column-to-last = [ ]; };

      # Multi-Monitor navigation focus (Mod+Ctrl+HJKL, Arrows as aliases)
      "Mod+Ctrl+H" = { hotkey-overlay.title = "Focus monitor left";  action.focus-monitor-left = [ ]; };
      "Mod+Ctrl+J" = { hotkey-overlay.title = "Focus monitor down";  action.focus-monitor-down = [ ]; };
      "Mod+Ctrl+K" = { hotkey-overlay.title = "Focus monitor up";    action.focus-monitor-up = [ ]; };
      "Mod+Ctrl+L" = { hotkey-overlay.title = "Focus monitor right"; action.focus-monitor-right = [ ]; };
      "Mod+Ctrl+Left".action.focus-monitor-left = [ ];
      "Mod+Ctrl+Down".action.focus-monitor-down = [ ];
      "Mod+Ctrl+Up".action.focus-monitor-up = [ ];
      "Mod+Ctrl+Right".action.focus-monitor-right = [ ];

      # Moving columns between physical displays (Mod+Ctrl+Shift+HJKL, Arrows as aliases)
      "Mod+Ctrl+Shift+H" = { hotkey-overlay.title = "Move column to monitor left";  action.move-column-to-monitor-left = [ ]; };
      "Mod+Ctrl+Shift+J" = { hotkey-overlay.title = "Move column to monitor down";  action.move-column-to-monitor-down = [ ]; };
      "Mod+Ctrl+Shift+K" = { hotkey-overlay.title = "Move column to monitor up";    action.move-column-to-monitor-up = [ ]; };
      "Mod+Ctrl+Shift+L" = { hotkey-overlay.title = "Move column to monitor right"; action.move-column-to-monitor-right = [ ]; };
      "Mod+Ctrl+Shift+Left".action.move-column-to-monitor-left = [ ];
      "Mod+Ctrl+Shift+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Ctrl+Shift+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Ctrl+Shift+Right".action.move-column-to-monitor-right = [ ];

      # Pure workspace jumping & reordering
      "Mod+Page_Down"       = { hotkey-overlay.title = "Focus workspace down";          action.focus-workspace-down = [ ]; };
      "Mod+Page_Up"         = { hotkey-overlay.title = "Focus workspace up";            action.focus-workspace-up = [ ]; };
      "Mod+Ctrl+Page_Down"  = { hotkey-overlay.title = "Move column to workspace down"; action.move-column-to-workspace-down = [ ]; };
      "Mod+Ctrl+Page_Up"    = { hotkey-overlay.title = "Move column to workspace up";   action.move-column-to-workspace-up = [ ]; };
      "Mod+Shift+Page_Down" = { hotkey-overlay.title = "Move workspace down";           action.move-workspace-down = [ ]; };
      "Mod+Shift+Page_Up"   = { hotkey-overlay.title = "Move workspace up";             action.move-workspace-up = [ ]; };

      # Mouse Wheel / Touchpad integrations
      "Mod+WheelScrollDown" = {
        hotkey-overlay.title = "Scroll: focus workspace down";
        action.focus-workspace-down = [ ];
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = {
        hotkey-overlay.title = "Scroll: focus workspace up";
        action.focus-workspace-up = [ ];
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollDown" = {
        hotkey-overlay.title = "Scroll: move column to workspace down";
        action.move-column-to-workspace-down = [ ];
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollUp" = {
        hotkey-overlay.title = "Scroll: move column to workspace up";
        action.move-column-to-workspace-up = [ ];
        cooldown-ms = 150;
      };

      "Mod+WheelScrollRight"      = { hotkey-overlay.title = "Scroll: focus column right (or Shift+Down)"; action.focus-column-right = [ ]; };
      "Mod+WheelScrollLeft"       = { hotkey-overlay.title = "Scroll: focus column left (or Shift+Up)";    action.focus-column-left = [ ]; };
      "Mod+Ctrl+WheelScrollRight" = { hotkey-overlay.title = "Scroll: move column right (or Shift+Down)";  action.move-column-right = [ ]; };
      "Mod+Ctrl+WheelScrollLeft"  = { hotkey-overlay.title = "Scroll: move column left (or Shift+Up)";     action.move-column-left = [ ]; };

      "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

      # Explicit Workspace Indices (1 to 9 navigation)
      "Mod+1" = { hotkey-overlay.title = "Focus workspace 1–9"; action.focus-workspace = 1; };
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1" = { hotkey-overlay.title = "Move column to workspace 1–9"; action.move-column-to-workspace = 1; };
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      # Column structural mutations
      "Mod+BracketLeft"  = { hotkey-overlay.title = "Consume or expel window left";  action.consume-or-expel-window-left = [ ]; };
      "Mod+BracketRight" = { hotkey-overlay.title = "Consume or expel window right"; action.consume-or-expel-window-right = [ ]; };
      "Mod+Comma"        = { hotkey-overlay.title = "Consume window into column";    action.consume-window-into-column = [ ]; };

      # Layout scale presets and sizing alterations
      "Mod+R"            = { hotkey-overlay.title = "Cycle column width preset";      action.switch-preset-column-width = [ ]; };
      "Mod+Shift+R"      = { hotkey-overlay.title = "Cycle column width preset back"; action.switch-preset-column-width-back = [ ]; };
      "Mod+Ctrl+Shift+R" = { hotkey-overlay.title = "Cycle window height preset";     action.switch-preset-window-height = [ ]; };
      "Mod+Ctrl+R"       = { hotkey-overlay.title = "Reset window height";            action.reset-window-height = [ ]; };

      "Mod+F"       = { hotkey-overlay.title = "Maximize column";                action.maximize-column = [ ]; };
      "Mod+Shift+F" = { hotkey-overlay.title = "Fullscreen window";              action.fullscreen-window = [ ]; };
      # "Mod+M".action.maximize-window = [];
      "Mod+Ctrl+F"  = { hotkey-overlay.title = "Expand column to fill width";    action.expand-column-to-available-width = [ ]; };
      "Mod+C"       = { hotkey-overlay.title = "Center column";                  action.center-column = [ ]; };
      "Mod+Ctrl+C"  = { hotkey-overlay.title = "Center visible columns";         action.center-visible-columns = [ ]; };

      # Micro dimension sizing increments
      "Mod+Minus"       = { hotkey-overlay.title = "Column width -10%";  action.set-column-width = "-10%"; };
      "Mod+Equal"       = { hotkey-overlay.title = "Column width +10%";  action.set-column-width = "+10%"; };
      "Mod+Shift+Minus" = { hotkey-overlay.title = "Window height -10%"; action.set-window-height = "-10%"; };
      "Mod+Shift+Equal" = { hotkey-overlay.title = "Window height +10%"; action.set-window-height = "+10%"; };

      # Layout modes & transitions
      "Mod+Shift+Space" = { hotkey-overlay.title = "Toggle floating window";         action.toggle-window-floating = [ ]; };
      "Mod+Shift+V"     = { hotkey-overlay.title = "Switch focus floating / tiling"; action.switch-focus-between-floating-and-tiling = [ ]; };
      "Mod+W"           = { hotkey-overlay.title = "Toggle tabbed column display";   action.toggle-column-tabbed-display = [ ]; };

      # Graphics / Screen Capture pipelines
      "Print"       = { hotkey-overlay.title = "Screenshot (interactive)";              action.screenshot = [ ]; };
      "Mod+Shift+S" = { hotkey-overlay.title = "Screenshot / Snipping Tool (Win+Shift+S)"; action.screenshot = [ ]; };
      "Ctrl+Print"  = { hotkey-overlay.title = "Screenshot screen";                     action.screenshot-screen = [ ]; };
      "Alt+Print"   = { hotkey-overlay.title = "Screenshot window";                     action.screenshot-window = [ ]; };

      # System constraints & hardware state switches
      "Mod+Escape" = {
        hotkey-overlay.title = "Toggle shortcut inhibit";
        action.toggle-keyboard-shortcuts-inhibit = [ ];
        allow-inhibiting = false;
      };
      "Ctrl+Alt+Delete" = {
        hotkey-overlay.title = "Quit Niri";
        action.quit = [ ];
      };
      "Mod+Shift+P" = {
        hotkey-overlay.title = "Power off monitors";
        action.power-off-monitors = [ ];
      };
    };
  };
}
