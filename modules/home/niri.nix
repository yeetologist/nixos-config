{ ... }:
{
  programs.niri.settings = {
    prefer-no-csd = true; # use server-side decorations instead of drawing their own title bars
    animations.enable = false; # Disables ALL animations in niri
    hotkey-overlay.hide-not-bound = true;

    input.keyboard.xkb.layout = "us";

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
    ];

    spawn-at-startup = [
      {
        command = [
          "waybar"
        ];
      }
    ];

    binds = {
      # Hotkey help overlay
      "Mod+Shift+Slash" = {
        hotkey-overlay.title = "Show hotkey overlay";
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
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock screen";
        action.spawn = "swaylock";
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

      # Directional window focus
      "Mod+Left"  = { hotkey-overlay.title = "Focus column left (or H)";  action.focus-column-left = [ ]; };
      "Mod+Down"  = { hotkey-overlay.title = "Focus window down (or J)";  action.focus-window-down = [ ]; };
      "Mod+Up"    = { hotkey-overlay.title = "Focus window up (or K)";    action.focus-window-up = [ ]; };
      "Mod+Right" = { hotkey-overlay.title = "Focus column right (or L)"; action.focus-column-right = [ ]; };
      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];
      "Mod+L".action.focus-column-right = [ ];

      # Moving windows within workspace layout
      "Mod+Ctrl+Left"  = { hotkey-overlay.title = "Move column left (or H)";  action.move-column-left = [ ]; };
      "Mod+Ctrl+Down"  = { hotkey-overlay.title = "Move window down (or J)";  action.move-window-down = [ ]; };
      "Mod+Ctrl+Up"    = { hotkey-overlay.title = "Move window up (or K)";    action.move-window-up = [ ]; };
      "Mod+Ctrl+Right" = { hotkey-overlay.title = "Move column right (or L)"; action.move-column-right = [ ]; };
      "Mod+Ctrl+H".action.move-column-left = [ ];
      "Mod+Ctrl+J".action.move-window-down = [ ];
      "Mod+Ctrl+K".action.move-window-up = [ ];
      "Mod+Ctrl+L".action.move-column-right = [ ];

      # Structural column boundaries
      "Mod+Home"      = { hotkey-overlay.title = "Focus first column";   action.focus-column-first = [ ]; };
      "Mod+End"       = { hotkey-overlay.title = "Focus last column";    action.focus-column-last = [ ]; };
      "Mod+Ctrl+Home" = { hotkey-overlay.title = "Move column to first"; action.move-column-to-first = [ ]; };
      "Mod+Ctrl+End"  = { hotkey-overlay.title = "Move column to last";  action.move-column-to-last = [ ]; };

      # Multi-Monitor navigation focus
      "Mod+Shift+Left"  = { hotkey-overlay.title = "Focus monitor left (or H)";  action.focus-monitor-left = [ ]; };
      "Mod+Shift+Down"  = { hotkey-overlay.title = "Focus monitor down (or J)";  action.focus-monitor-down = [ ]; };
      "Mod+Shift+Up"    = { hotkey-overlay.title = "Focus monitor up (or K)";    action.focus-monitor-up = [ ]; };
      "Mod+Shift+Right" = { hotkey-overlay.title = "Focus monitor right (or L)"; action.focus-monitor-right = [ ]; };
      "Mod+Shift+H".action.focus-monitor-left = [ ];
      "Mod+Shift+J".action.focus-monitor-down = [ ];
      "Mod+Shift+K".action.focus-monitor-up = [ ];
      "Mod+Shift+L".action.focus-monitor-right = [ ];

      # Moving elements between physical displays
      "Mod+Shift+Ctrl+Left"  = { hotkey-overlay.title = "Move column to monitor left (or H)";  action.move-column-to-monitor-left = [ ]; };
      "Mod+Shift+Ctrl+Down"  = { hotkey-overlay.title = "Move column to monitor down (or J)";  action.move-column-to-monitor-down = [ ]; };
      "Mod+Shift+Ctrl+Up"    = { hotkey-overlay.title = "Move column to monitor up (or K)";    action.move-column-to-monitor-up = [ ]; };
      "Mod+Shift+Ctrl+Right" = { hotkey-overlay.title = "Move column to monitor right (or L)"; action.move-column-to-monitor-right = [ ]; };
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

      # Workspace linear movement
      "Mod+Page_Down"       = { hotkey-overlay.title = "Focus workspace down (or U)";          action.focus-workspace-down = [ ]; };
      "Mod+Page_Up"         = { hotkey-overlay.title = "Focus workspace up (or I)";            action.focus-workspace-up = [ ]; };
      "Mod+U".action.focus-workspace-down = [ ];
      "Mod+I".action.focus-workspace-up = [ ];
      "Mod+Ctrl+Page_Down"  = { hotkey-overlay.title = "Move column to workspace down (or U)"; action.move-column-to-workspace-down = [ ]; };
      "Mod+Ctrl+Page_Up"    = { hotkey-overlay.title = "Move column to workspace up (or I)";   action.move-column-to-workspace-up = [ ]; };
      "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];

      "Mod+Shift+Page_Down" = { hotkey-overlay.title = "Move workspace down (or U)";           action.move-workspace-down = [ ]; };
      "Mod+Shift+Page_Up"   = { hotkey-overlay.title = "Move workspace up (or I)";             action.move-workspace-up = [ ]; };
      "Mod+Shift+U".action.move-workspace-down = [ ];
      "Mod+Shift+I".action.move-workspace-up = [ ];

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
      "Mod+Period"       = { hotkey-overlay.title = "Expel window from column";      action.expel-window-from-column = [ ]; };

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
      "Mod+V"       = { hotkey-overlay.title = "Toggle floating window";            action.toggle-window-floating = [ ]; };
      "Mod+Shift+V" = { hotkey-overlay.title = "Switch focus floating / tiling";    action.switch-focus-between-floating-and-tiling = [ ]; };
      "Mod+W"       = { hotkey-overlay.title = "Toggle tabbed column display";      action.toggle-column-tabbed-display = [ ]; };

      # Graphics / Screen Capture pipelines
      "Print"      = { hotkey-overlay.title = "Screenshot (interactive)"; action.screenshot = [ ]; };
      "Ctrl+Print" = { hotkey-overlay.title = "Screenshot screen";        action.screenshot-screen = [ ]; };
      "Alt+Print"  = { hotkey-overlay.title = "Screenshot window";        action.screenshot-window = [ ]; };

      # System constraints & hardware state switches
      "Mod+Escape" = {
        hotkey-overlay.title = "Toggle shortcut inhibit";
        action.toggle-keyboard-shortcuts-inhibit = [ ];
        allow-inhibiting = false;
      };
      "Mod+Shift+E" = {
        hotkey-overlay.title = "Quit Niri (or Ctrl+Alt+Del)";
        action.quit = [ ];
      };
      "Ctrl+Alt+Delete".action.quit = [ ];
      "Mod+Shift+P" = {
        hotkey-overlay.title = "Power off monitors";
        action.power-off-monitors = [ ];
      };
    };
  };
}
