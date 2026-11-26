# Host tuf: user apps and tools (Home Manager). Shared config: ../../home.nix.
# Toolchains per project (Go, Deno, Python versions, JDK, Dart, .NET, Playwright): a dev shell + direnv.
{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Browsers (brave is in the shared home.nix)
    firefox google-chrome

    # Dev apps
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
    t3code jetbrains-toolbox android-studio android-tools github-desktop

    # Chat, media, reading
    vesktop ayugram-desktop calibre suwayomi-server   # zotero: nixpkgs builds it on EOL Firefox ESR 140 (insecure)

    # Downloads, gaming, system UI
    qbittorrent lsfg-vk-ui opensnitch-ui

    # CLI tools (ripgrep, file, yt-dlp, tmux, fastfetch are already shared)
    eza bat fd jq yq-go sd dust ncdu procs hyperfine tokei difftastic duckdb xh
    fzf ffmpeg imagemagick poppler-utils rclone _7zz rsync   # gh, nushell: shared modules

    # Global dev tools
    uv ruff rustup nodejs bun opencode claude-code firebase-tools supabase-cli
  ];

  programs.zoxide.enable = true;                         # `z <dir>`, hooks into nushell
  programs.direnv = { enable = true; nix-direnv.enable = true; }; # per-project dev shells on `cd`

  # Laptop-only desktop services: Bluetooth tray applet, idle suspend, and low-battery alerts.
  services.blueman-applet.enable = true;
  services.swayidle.timeouts = [
    {
      timeout = 1800; # 30 min: suspend laptop
      command = "systemctl suspend";
    }
  ];

  systemd.user.services.low-battery-alert = {
    Unit.Description = "Send critical notification on low battery";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellApplication {
        name = "low-battery-alert";
        runtimeInputs = with pkgs; [ libnotify coreutils ];
        text = ''
          state="/tmp/low-battery-notified"
          for bat in /sys/class/power_supply/BAT*; do
            [[ -r "$bat/capacity" && -r "$bat/status" ]] || continue
            cap=$(cat "$bat/capacity")
            status=$(cat "$bat/status")
            if [[ "$status" != "Discharging" ]]; then
              rm -f "$state"
              exit 0
            fi
            prev=$(cat "$state" 2>/dev/null || echo 100)
            if (( cap <= 7 && prev > 7 )); then
              notify-send -u critical "Battery critical ($cap%)" "Plug in charger now."
              echo 7 > "$state"
            elif (( cap <= 15 && prev > 15 )); then
              notify-send -u critical "Battery low ($cap%)" "Plug in charger soon."
              echo 15 > "$state"
            fi
          done
        '';
      }}/bin/low-battery-alert";
    };
  };

  systemd.user.timers.low-battery-alert = {
    Unit.Description = "Check laptop battery level every 2 minutes";
    Timer = {
      OnBootSec = "1m";
      OnUnitActiveSec = "2m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

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
