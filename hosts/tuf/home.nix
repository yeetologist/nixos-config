# Host tuf: user apps and tools (Home Manager). Shared config: ../../home.nix.
# Toolchains per project (Go, Deno, Python versions, JDK, Dart, .NET, Playwright): a dev shell + direnv.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Browsers (brave is in the shared home.nix)
    firefox google-chrome

    # Dev apps
    zed-editor antigravity jetbrains-toolbox android-studio android-tools github-desktop

    # Chat, media, reading
    vesktop ayugram-desktop calibre suwayomi-server   # zotero: nixpkgs builds it on EOL Firefox ESR 140 (insecure)

    # Downloads, gaming, system UI
    qbittorrent ludusavi lsfg-vk-ui opensnitch-ui

    # CLI tools (ripgrep, file, yt-dlp, tmux, fastfetch are already shared)
    eza bat fd jq yq-go sd dust ncdu procs hyperfine tokei difftastic duckdb xh
    fzf gh ffmpeg imagemagick poppler-utils rclone _7zz rsync nushell

    # Global dev tools
    uv ruff rustup nodejs bun opencode firebase-tools supabase-cli
  ];

  programs.zoxide.enable = true;                         # `z <dir>`, hooks into zsh
  programs.direnv = { enable = true; nix-direnv.enable = true; }; # per-project dev shells on `cd`
}
