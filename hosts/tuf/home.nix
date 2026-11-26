# Host tuf: user apps and tools (Home Manager). Shared config: ../../home.nix.
# Toolchains per project (Go, Deno, Python versions, JDK, Dart, .NET, Playwright): a dev shell + direnv.
{ pkgs, lib, inputs, ... }:

let
  # Nushell scripts shared with Windows (private repo yeetologist/bin-scripts on the E:/data drive).
  # Secrets (alldebrid_key.txt, nextdns_keys.json) sit next to them, gitignored, never in this repo.
  binScripts = "/data/dl/Programs/bin";
  binScriptNames = [
    "find-srt" "test-dns" "sort-screenshots" "save-yt-video" "copy-rclone-yazi"
    "clean-alldebrid" "sync-alldebrid" "upload-magnet" "upload-torrents" "update-alldebrid-apikey"
    "sync-nextdns" "sync-account"
  ];
  # Wrapper, not a symlink: the scripts find lib/ and their key files next to their own path.
  binScript = name: pkgs.writeShellScriptBin name ''exec ${pkgs.nushell}/bin/nu ${binScripts}/${name}.nu "$@"'';

  # rclone mounts, replacing stream-drive.nu / ssh-mount.nu. Needs ~/.config/rclone/rclone.conf and
  # ~/.ssh/config (router, myvps) copied from Windows by hand. Control: systemctl --user start|stop rclone-<name>.
  # The --rc ports match Windows so cache-streamdrive can drive these mounts once it's ported.
  vfsFlags = [
    "--vfs-cache-mode full" "--vfs-read-chunk-size 64M" "--vfs-read-chunk-size-limit 256M"
    "--buffer-size 0" "--cache-dir /data/dl/rclone_cache_linux" "--use-mmap" "--vfs-read-ahead 64M"
    "--vfs-cache-max-size 500G" "--vfs-cache-max-age 99999h" "--vfs-fast-fingerprint"
    "--timeout 30s" "--contimeout 15s" "--low-level-retries 10" "--retries 5" "--no-modtime" "--no-checksum"
  ];
  alldebridFlags = [
    "--dir-cache-time 30s" "--attr-timeout 30s" "--vfs-read-chunk-streams 1" "--multi-thread-streams 0" "--read-only"
  ];
  sftpFlags = host: [
    "--sftp-ssh 'ssh ${host}'" "--sftp-shell-type unix" "--sftp-disable-hashcheck" "--vfs-cache-mode writes"
  ];
  rcloneMounts = {
    alldebrid_1 = { remote = "alldebrid_1:"; flags = vfsFlags ++ alldebridFlags ++ [ "--rc --rc-addr 127.0.0.1:5572 --rc-no-auth" ]; };
    alldebrid_2 = { remote = "alldebrid_2:"; flags = vfsFlags ++ alldebridFlags ++ [ "--rc --rc-addr 127.0.0.1:5573 --rc-no-auth" ]; };
    gcrypt = {
      remote = "gcrypt:";
      flags = vfsFlags ++ [
        "--dir-cache-time 99999h" "--attr-timeout 99999h" "--poll-interval 120s" "--drive-chunk-size 128M"
        "--vfs-read-chunk-streams 4" "--rc --rc-addr 127.0.0.1:5574 --rc-no-auth"
      ];
    };
    router = { remote = ":sftp:"; flags = sftpFlags "router"; };
    myvps  = { remote = ":sftp:"; flags = sftpFlags "myvps"; };
  };
in
{
  home.packages = map binScript binScriptNames ++ (with pkgs; [
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

    # CLI tools (ripgrep, file, yt-dlp, fastfetch are already shared)
    eza bat fd jq yq-go sd dust ncdu procs hyperfine tokei difftastic duckdb xh
    fzf ffmpeg imagemagick poppler-utils rclone _7zz rsync   # gh, nushell: shared modules
    dnsutils                                                  # dig, for test-dns

    # Global dev tools (nodejs is already shared in root home.nix)
    uv ruff rustup bun opencode claude-code firebase-tools supabase-cli
  ]);

  # Inline module: low-battery-alert below also sets systemd.user.services.
  imports = [{ systemd.user.services = lib.mapAttrs' (name: m: lib.nameValuePair "rclone-${name}" {
    Unit.Description = "rclone mount ${m.remote} at ~/mnt/${name}";
    Service = {
      Type = "notify";
      Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.openssh pkgs.coreutils ]}"; # fusermount3, ssh
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/mnt/${name}";
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${m.remote} %h/mnt/${name} ${lib.concatStringsSep " " m.flags}";
      ExecStop = "/run/wrappers/bin/fusermount3 -u %h/mnt/${name}";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  }) rcloneMounts // {
    # Suwayomi as an always-on service (replaces start-suwayomi-server.nu). Disabled for now; the package
    # stays in home.packages above. Web UI: http://127.0.0.1:4567
    # suwayomi = {
    #   Unit.Description = "Suwayomi manga server";
    #   Service = {
    #     ExecStart = lib.getExe pkgs.suwayomi-server;
    #     Restart = "on-failure";
    #   };
    #   Install.WantedBy = [ "default.target" ];
    # };
  }; }];

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
