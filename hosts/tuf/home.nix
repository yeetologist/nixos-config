# Host tuf: user apps and tools (Home Manager). Shared config: ../../home.nix.
# Toolchains per project (Go, Deno, Python versions, JDK, Dart, .NET, Playwright): a dev shell + direnv.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Browsers (brave is in the shared home.nix)
    firefox google-chrome

    # Dev apps
    antigravity jetbrains-toolbox android-studio android-tools github-desktop

    # Chat, media, reading
    vesktop ayugram-desktop calibre suwayomi-server   # zotero: nixpkgs builds it on EOL Firefox ESR 140 (insecure)

    # Downloads, gaming, system UI
    qbittorrent lsfg-vk-ui opensnitch-ui

    # CLI tools (ripgrep, file, yt-dlp, tmux, fastfetch are already shared)
    eza bat fd jq yq-go sd dust ncdu procs hyperfine tokei difftastic duckdb xh
    fzf ffmpeg imagemagick poppler-utils rclone _7zz rsync   # gh, nushell: shared modules

    # Global dev tools
    uv ruff rustup nodejs bun opencode firebase-tools supabase-cli
  ];

  programs.zoxide.enable = true;                         # `z <dir>`, hooks into nushell
  programs.direnv = { enable = true; nix-direnv.enable = true; }; # per-project dev shells on `cd`

  programs.zed-editor.package = pkgs.zed-editor; # settings come from modules/home/zed.nix

  # Ported from Windows %APPDATA%\yt-dlp\config (E:\ -> /data/). The cookies file is a login: it
  # stays on /data, not in this repo. Plugins (streamcash): copy to ~/.config/yt-dlp/plugins/.
  programs.yt-dlp = {
    enable = true;
    settings = {
      add-metadata = true;
      sponsorblock-mark = "all";
      yes-playlist = true;
      concurrent-fragments = 8;
      embed-subs = true;
      sub-langs = "en";
      write-auto-subs = true;
      merge-output-format = "mkv";
      cookies = "/data/dl/Video/Jd/yt/cookie";
      format = "bestvideo[height<=?1080]+bestaudio/best";   # prefer VP9/AV1 up to 1080p
      format-sort = "res,vcodec:av01,vcodec:vp9";
      output = "/data/dl/Video/Jd/yt/%(title)s[%(id)s].%(ext)s";
    };
  };

  # Game save backups (daily), ported from Windows; Steam roots moved to Linux paths.
  services.ludusavi = {
    enable = true;
    settings = {
      manifest.url = "https://raw.githubusercontent.com/mtkennerly/ludusavi-manifest/master/data/manifest.yaml";
      roots = [
        { store = "steam"; path = "~/.local/share/Steam"; }
        { store = "steam"; path = "/data/SteamLibrary"; }
      ];
      backup.path = "/data/ludusavi-backup";
      restore.path = "/data/ludusavi-backup";
    };
  };
}
