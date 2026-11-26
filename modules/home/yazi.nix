{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;

    # Inject all optional runtime dependencies directly into Yazi
    extraPackages = with pkgs; [
      _7zz-rar        # RAR archive support
      ffmpeg          # Video thumbnails
      jq              # JSON preview
      poppler         # PDF preview
      fd              # File searching
      ripgrep         # File content searching
      fzf             # Subtree navigation
      zoxide          # Smart directory jumping
      resvg           # SVG rendering
      imagemagick     # Image manipulation and preview
    ];

    # Ported from Windows %APPDATA%\yazi\config (Windows openers swapped for Linux ones).
    settings = {
      mgr.show_hidden = true;
      opener = {
        open = [ { run = "xdg-open %s1"; desc = "Open"; orphan = true; } ];
        play = [ { run = "mpv %s"; desc = "Play with mpv"; orphan = true; } ];
        edit = [
          { run = "zeditor %s"; desc = "Zed"; orphan = true; }
          { run = "zeditor --wait %s"; desc = "Zed (block)"; block = true; }
        ];
      };
      open.prepend_rules = [
        { url = "*.{mp4,mkv,avi,mov,webm,flv,wmv,mpg,mpeg,m4v,3gp,mp3,flac,wav,ogg,m4a,opus,aac,wma}"; use = "play"; }
        { url = "*.{jpg,jpeg,png,gif,webp,bmp,tiff,ico,heic,svg}"; use = "open"; }
      ];
    };

    keymap.mgr.prepend_keymap = [
      { on = [ "Q" ]; run = ''shell 'ghostty --working-directory="$PWD" -e nu' --orphan; quit''; desc = "Exit Yazi and open nushell here"; }
      { on = [ "c" "r" ]; run = ''shell 'nu /data/dl/Programs/bin/copy-rclone-yazi.nu %s' --block''; desc = "Rclone copy selection (bypass VFS cache)"; }
    ];
  };
}
