{ config, pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    # -------------------------------------------------------------------------
    # mpv.conf
    # -------------------------------------------------------------------------
    config = {
      # RENDERING
      profile        = "high-quality";
      vo             = "gpu-next";

      # Linux / Wayland — Vulkan backend + VA-API hardware decoding
      gpu-api        = "vulkan";
      hwdec          = "vaapi";

      # Scalers
      scale          = "ewa_lanczossharp";   # luma upscaler
      cscale         = "ewa_lanczossharp";   # chroma up/downscaler
      dscale         = "mitchell";           # luma downscaler

      # Color management
      icc-profile-auto        = "yes";
      target-colorspace-hint  = "yes";
      dither-depth            = "auto";

      # HDR → SDR / wide-gamut tone mapping
      tone-mapping        = "bt.2446a";
      hdr-compute-peak    = "auto";
      gamut-mapping-mode  = "auto";

      # Smoother playback on high-refresh-rate displays
      video-sync    = "display-resample";
      interpolation = "yes";
      tscale        = "oversample";

      # Debanding
      deband            = "yes";
      deband-iterations = 2;    # more passes = smoother gradients (default: 1)
      deband-threshold  = 35;   # grain strength threshold (default: 48)
      deband-range      = 16;   # initial range for grain sampling (default: 16)
      deband-grain      = 4;    # extra noise to mask banding (default: 32; lower = cleaner)

      # WINDOW
      keep-open          = "yes";      # pause on the last frame
      keepaspect         = "yes";      # maintain aspect ratio on window resize
      keepaspect-window  = "yes";      # maintain aspect ratio when windowed
      autofit-larger     = "90%x90%"; # don't open a window larger than 90% of the screen
      geometry           = "50%:50%"; # center the window on startup

      # TERMINAL
      cursor-autohide        = 200;     # hide cursor after 200 ms
      cursor-autohide-fs-only = "yes"; # only autohide in fullscreen
      msg-color              = "yes";   # colorize log messages
      msg-module             = "yes";   # prepend module name to log messages
      term-osd-bar           = "yes";   # show progress bar in terminal

      # OSD
      border            = "no";
      osd-font          = "JetBrainsMono Nerd Font Mono";
      osd-font-size     = 32;
      osd-color         = "#FFFFFFFF";        # ARGB
      osd-border-color  = "#DD322640";        # ARGB
      osd-border-size   = 2;
      osd-bar-align-y   = -1;                 # -1 = top, 0 = center, 1 = bottom
      osd-bar-h         = 2;                  # bar height as % of screen height
      osd-bar-w         = 99;                 # bar width as % of screen width
      osd-duration      = 2000;               # hide OSD after 2 s
      osd-status-msg    = "\${time-pos} / \${duration}\${?percent-pos:  (\${percent-pos}%)}\${?frame-drop-count:\${!frame-drop-count==0:  Dropped: \${frame-drop-count}}}\n\${?chapter:Chapter: \${chapter}}";

      # PLAYBACK
      force-seekable            = "yes";  # force videos to be seekable
      save-position-on-quit     = "yes";  # resume from last position on reopen
      prefetch-playlist         = "yes";  # prefetch next playlist entry
      hls-bitrate               = "max";  # use highest quality for HLS streams
      cache                     = "no";   # disable cache for local playback (overridden per-profile below)
      hr-seek                   = "yes";  # frame-accurate seeking
      hr-seek-framedrop         = "yes";  # allow frame drop during seek for responsiveness
      watch-later-options-clr   = "yes";  # don't persist per-file volume/filters etc.

      # AUDIO
      ao     = "pipewire";               # Linux audio output (Pipewire)
      alang  = "en,eng,enUS,en-US";      # preferred audio languages

      # SUBTITLES
      slang                       = "en,eng,enUS,en-US";
      sub-auto                    = "fuzzy";   # load external subs even if filename doesn't match exactly
      embeddedfonts               = "yes";     # use embedded fonts for SSA/ASS subtitles
      sub-fix-timing              = "no";      # don't auto-fix subtitle gaps

      sub-font                    = "JetBrainsMono Nerd Font Mono";
      sub-font-size               = 32;
      sub-color                   = "#eaea27";       # yellow
      sub-shadow-color            = "#80000000";     # semi-transparent black drop shadow
      sub-shadow-offset           = 2;
      sub-scale-with-window       = "yes";

      # External subtitle search paths
      "sub-file-paths-append"     = [
        "Subs/\${filename/no-ext}"
        "Subs/\${filename}"
        "subs/\${filename/no-ext}"
        "subs/\${filename}"
        "ASS" "Ass" "ass"
        "SRT" "Srt" "srt"
        "Sub" "Subs" "subs"
        "Subtitles" "subtitles"
        "ttml"
      ];

      # YT-DLP / STREAMING
      ytdl-format      = "bestvideo[ext=webm]+bestaudio[ext=webm]/bestvideo+bestaudio/best";
      ytdl-raw-options = "yes-playlist=,ignore-config=,sub-lang=\"en,eng,enUS,en-US\",write-sub=,write-auto-sub=";

      # SCREENSHOTS
      screenshot-format           = "png";
      screenshot-high-bit-depth   = "yes";
      screenshot-png-compression  = 1;
      screenshot-jpeg-quality     = 95;
      screenshot-dir              = "~/Pictures";
      screenshot-template         = "%f-%wH.%wM.%wS.%wT-#%#00n";
    };

    # -------------------------------------------------------------------------
    # Profiles (mpv.conf [section] blocks)
    # -------------------------------------------------------------------------
    profiles = {
      # Audio-only formats — disable video renderer and screensaver suppression
      "extension.m4b" = {
        stop-screensaver = "no";
        vid = "no";
      };
      "extension.mp3" = {
        stop-screensaver = "no";
        vid = "no";
      };

      # Network Streaming Cache — aggressive buffering for SMB/HTTP streams
      "protocol.smb" = {
        profile-restore        = "copy";
        cache                  = "yes";
        cache-secs             = 600;
        demuxer-max-bytes      = "2048M";
        demuxer-max-back-bytes = "1024M";
        demuxer-hysteresis-secs = 60;
      };
      "protocol.http" = {
        profile = "protocol.smb";
      };
      "protocol.https" = {
        profile = "protocol.smb";
      };
    };

    # -------------------------------------------------------------------------
    # input.conf
    # -------------------------------------------------------------------------
    bindings = {
      # Quality Menu
      "ALT+f"  = "script-binding quality_menu/video_formats_toggle";
      "ALT+F"  = "script-binding quality_menu/audio_formats_toggle";

      # Mouse
      "MOUSE_BTN0_DBL" = "cycle fullscreen";
      "MOUSE_BTN2"     = "cycle pause";

      # Arrow / Navigation keys
      "RIGHT"       = "osd-msg-bar seek +5  relative+keyframes";
      "LEFT"        = "osd-msg-bar seek -5  relative+keyframes";
      "SHIFT+RIGHT" = "osd-msg-bar seek +1  relative+exact";
      "SHIFT+LEFT"  = "osd-msg-bar seek -1  relative+exact";
      "CTRL+RIGHT"  = "frame-step ; show-text \"Frame: \${estimated-frame-number} / \${estimated-frame-count}\"";
      "CTRL+LEFT"   = "frame-back-step ; show-text \"Frame: \${estimated-frame-number} / \${estimated-frame-count}\"";

      "UP"         = "osd-msg-bar seek +30  relative+keyframes";
      "DOWN"       = "osd-msg-bar seek -30  relative+keyframes";
      "SHIFT+UP"   = "osd-msg-bar seek +120 relative+keyframes";
      "SHIFT+DOWN" = "osd-msg-bar seek -120 relative+keyframes";

      "PGUP"  = "osd-msg-bar seek +600 relative+keyframes";
      "PGDWN" = "osd-msg-bar seek -600 relative+keyframes";

      "ALT+RIGHT" = "sub-seek +1 ; show-text \"Sub Seek +1\"";
      "ALT+LEFT"  = "sub-seek -1 ; show-text \"Sub Seek -1\"";

      # Number row — image adjustments & volume
      "1" = "add contrast -1 ; show-text \"Contrast: \${contrast}\"";
      "2" = "add contrast +1 ; show-text \"Contrast: \${contrast}\"";
      "3" = "add brightness -1 ; show-text \"Brightness: \${brightness}\"";
      "4" = "add brightness +1 ; show-text \"Brightness: \${brightness}\"";
      "5" = "add gamma -1 ; show-text \"Gamma: \${gamma}\"";
      "6" = "add gamma +1 ; show-text \"Gamma: \${gamma}\"";
      "7" = "add saturation -1 ; show-text \"Saturation: \${saturation}\"";
      "8" = "add saturation +1 ; show-text \"Saturation: \${saturation}\"";
      "9" = "add volume -2 ; show-text \"Volume: \${volume}\"";
      "0" = "add volume +2 ; show-text \"Volume: \${volume}\"";
      "!" = "cycle ontop";
      "\\" = "cycle mute";

      # Q / q row
      "Q" = "script-binding auto_save_state/quit-watch-later-conditional";
      "q" = "quit";

      "w"      = "script-message osc-playlist";
      "W"      = "playlist-shuffle";
      "e"      = "playlist-prev ; show-text \"\${playlist-pos-1}/\${playlist-count}\"";
      "r"      = "playlist-next ; show-text \"\${playlist-pos-1}/\${playlist-count}\"";

      "t"      = "cycle-values sub-use-margins \"yes\" \"no\"";
      "CTRL+t" = "cycle-values blend-subtitles \"yes\" \"video\" \"no\"";
      "y"      = "cycle-values stretch-image-subs-to-screen \"yes\" \"no\"";
      "Y"      = "cycle-values stretch-dvd-subs \"yes\" \"no\"";

      "u"      = "cycle-values hwdec \"auto\" \"no\"";
      "U"      = "cycle-values vf \"format=colorlevels=full\" \"format=colorlevels=auto\" \"format=colorlevels=limited\"";

      "i"      = "script-binding stats/display-stats";
      "I"      = "script-binding stats/display-stats-toggle";
      "o"      = "cycle-values osd-level 3 1";
      "O"      = "cycle osc";
      "p"      = "cycle-values video-rotate 90 180 270 0";
      "P"      = "cycle-values video-aspect \"16:9\" \"4:3\" \"2.35:1\" \"16:10\"";

      # A / S / D / F row
      "a"      = "cycle audio";
      "A"      = "cycle-values af \"lavfi=[dynaudnorm=f=200:g=5:r=0.1]\" \"\"";
      "CTRL+a" = "script-binding auto_audio_device/toggle-switching";

      "s"      = "cycle sub";
      "S"      = "cycle sub-visibility";
      "CTRL+s" = "screenshot";

      "d"      = "cycle-values window-scale \"1.5\" \"2.0\" \"3.0\" \"0.5\" \"1.0\" ; show-text \"Scale: \${window-scale}\"";
      "D"      = "cycle edition";
      "CTRL+d" = "cycle video";

      "f"      = "cycle fullscreen ; show-text \"Scale: \${window-scale}\"";
      "F"      = "vf clr \"\" ; show-text \"Filters cleared\"";

      "g"      = "cycle-values video-sync display-resample audio ; cycle-values interpolation yes no ; show-text \"Interpolation: \${interpolation} (\${tscale})\"";
      "G"      = "cycle-values tscale \"linear\" \"catmull_rom\" \"mitchell\" \"bicubic\" \"oversample\" ; show-text \"Interpolation: \${interpolation} (\${tscale})\"";
      "CTRL+g" = "cycle-values interpolation no yes ; show-text \"Interpolation: \${interpolation} (\${tscale})\"";

      "h"      = "seek -5";
      "j"      = "seek -30";
      "J"      = "cycle deband";
      "k"      = "seek +30";
      "K"      = "cycle deinterlace";
      "l"      = "seek +5";
      "L"      = "cycle-values loop-file yes no ; show-text \"\${?=loop-file==inf:Looping enabled (file)}\${?=loop-file==no:Looping disabled (file)}\"";
      "CTRL+l" = "ab-loop";

      # Z / X / C / V / B / N / M row
      "c"      = "script-message osc-chapterlist";
      "v"      = "script-message osc-tracklist";

      "n"      = "add audio-delay +0.10";
      "N"      = "add audio-delay -0.10";
      "CTRL+n" = "set sub-delay 0";

      "m"      = "add sub-delay +0.10";
      "M"      = "add sub-delay -0.10";
      "CTRL+m" = "set sub-delay 0";

      ","  = "add sub-scale -0.05";   # decrease subtitle font size
      "<"  = "add sub-scale +0.05";   # increase subtitle font size
      "."  = "add sub-pos -1";        # move subtitles up
      ">"  = "add sub-pos +1";        # move subtitles down

      "/"  = "sub-step +1 ; show-text \"Sub Step +1 (timing adjustment)\"";
      "?"  = "sub-step -1 ; show-text \"Sub Step -1 (timing adjustment)\"";

      # Special keys
      "ESC"             = "cycle fullscreen";
      "SPACE"           = "cycle pause";
      "IDEOGRAPHIC_SPACE" = "cycle pause";
      "ENTER"           = "show-progress";
      "BS"              = "revert-seek";
      "SHIFT+BS"        = "set speed 1.0 ; set gamma 0 ; set brightness 0 ; set contrast 0 ; set saturation 0 ; set hue 0 ; show-text \"Speed/Gamma/Brightness/Contrast/Saturation/Hue resetted\"";
      "ALT+BS"          = "set video-pan-x 0 ; set video-pan-y 0 ; show-text \"Pan resetted\"";
      "META+BS"         = "set video-zoom 0 ; show-text \"Zoom resetted\"";

      # Function keys / Command Palette
      "F11"    = "script-binding console/enable";
      "Ctrl+p" = "script-message-to command_palette show-command-palette \"Command Palette\"";
      "F1"     = "script-message-to command_palette show-command-palette \"Bindings\"";
      "F2"     = "script-message-to command_palette show-command-palette \"Properties\"";
      "F3"     = "script-message-to command_palette show-command-palette \"Commands\"";
      "F4"     = "script-message-to command_palette show-command-palette \"Options\"";
      "F8"     = "script-message-to command_palette show-command-palette \"Playlist\"";
      "F9"     = "script-message-to command_palette show-command-palette \"Tracks\"";
      "Alt+a"  = "script-message-to command_palette show-command-palette \"Audio Tracks\"";
      "Alt+s"  = "script-message-to command_palette show-command-palette \"Subtitle Tracks\"";
      "Alt+b"  = "script-message-to command_palette show-command-palette \"Secondary Subtitle\"";
      "Alt+v"  = "script-message-to command_palette show-command-palette \"Video Tracks\"";
      "Alt+c"  = "script-message-to command_palette show-command-palette \"Chapters\"";
      "Alt+p"  = "script-message-to command_palette show-command-palette \"Profiles\"";
      "Alt+d"  = "script-message-to command_palette show-command-palette \"Audio Devices\"";
      "Alt+l"  = "script-message-to command_palette show-command-palette \"Subtitle Line\"";
      "Alt+t"  = "script-message-to command_palette show-command-palette \"Blu-ray Titles\"";
      "Alt+q"  = "script-message-to command_palette show-command-palette \"Stream Quality\"";
      "Alt+r"  = "script-message-to command_palette show-command-palette \"Aspect Ratio\"";
      "Alt+f"  = "script-message-to command_palette show-command-palette \"Recent Files\"";

      # Numpad — pan
      "ALT+KP8" = "add video-pan-y .05";
      "ALT+KP6" = "add video-pan-x -.05";
      "ALT+KP2" = "add video-pan-y -.05";
      "ALT+KP4" = "add video-pan-x .05";
    };
  };
}
