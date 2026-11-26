{ lib, host, ... }:

{
  # Login and interactive shell (users.users.<user>.shell in configuration.nix).
  # Config ported from Windows %APPDATA%\nushell; aliases ported from the old zsh setup.
  programs.nushell = {
    enable = true;

    # Load the NixOS + Home Manager environment (PATH, EDITOR, XDG_*) when nu is the login shell.
    loadSessionVariables = true;

    # Start niri after logging in on tty1; other TTYs and SSH stay plain shells.
    extraLogin = ''
      if (tty) == "/dev/tty1" and ($env.WAYLAND_DISPLAY? | is-empty) {
          exec niri-session -l
      }
    '';

    # Only nushell-safe aliases. cp/mv/rm/ls/grep/history aliases from zsh are dropped:
    # nushell has its own builtins for those. mkForce: HM would otherwise copy home.shellAliases.
    shellAliases = lib.mkForce {
      # NixOS
      up  = "sudo nixos-rebuild switch --refresh --flake github:yeetologist/nixos-config#${host}";
      btw = "echo 'I use NixOS, btw'";

      # Editor
      vim     = "nvim";
      vimdiff = "nvim -d";
      magit   = "nvim -c MagitOnly";
      e       = "nvim";

      # Common abbreviations
      se  = "sudoedit";
      sc  = "systemctl";
      jc  = "journalctl -r";
      ka  = "pkill";
      sdn = "sudo shutdown -h now";
      bios = "systemctl reboot --firmware-setup"; # restart-into-bios on Windows
      smi = "sudo make install";
      pt  = "patch --merge -i";
      t   = "tldr";
      wa  = "whatis";
      lsf = "lsblk -f";
      dft = "df -Th";

      # yt-dlp
      yd      = "yt-dlp";
      yt      = "yt-dlp --add-metadata --write-sub --sub-lang en -N 3 -i";
      yta     = "yt-dlp --add-metadata -N 3 -x -S ext -f bestaudio/best -o '~/Downloads/Music/%(title)s_%(id)s.%(ext)s'";
      ytF     = "yt-dlp -F";
      ytf     = "yt-dlp -f";
      ytamp3  = "yt-dlp --extract-audio --audio-format mp3 -o '~/Downloads/Music/%(title)s_%(id)s.%(ext)s' -i";
      yt4     = "yt-dlp --add-metadata -S ext -f 'bestvideo[height<=480]+bestaudio/best' -N 3 --write-sub --sub-lang en -i";
      yt7     = "yt-dlp --add-metadata -S ext -f 'bestvideo[height<=720]+bestaudio/best' -N 3 --write-sub --sub-lang en -i";
      ytvbest = "yt-dlp --add-metadata -S ext -f 'bv*+ba/b' -N 3 --write-sub --sub-lang en -i";
      ytmeta  = "yt-dlp --add-metadata --write-description --write-info-json --write-annotations --write-sub --sub-lang en --write-thumbnail --skip-download -i";
      ytsub   = "yt-dlp --skip-download --write-auto-sub -i";
      yten    = "yt-dlp --write-sub --sub-lang en --skip-download -i";

      # Git (old `gh = git help everyday` dropped: it shadowed the GitHub CLI)
      gs    = "git status -sb";
      gc    = "git commit -v";
      gca   = "git commit -v --amend";
      gcf   = "git config --global";
      ga    = "git add";
      gpl   = "git pull";
      gpom  = "git pull origin master";
      gpu   = "git push --set-upstream";
      gpuom = "git push -u origin master";
      gd    = "git diff";
      gds   = "git diff --staged";
      gcm   = "git checkout master";
      gnb   = "git checkout -b";
      grs   = "git restore --staged";
      gr    = "git restore";
      grss  = "git restore --source";
      gre   = "git remote";
      gcl   = "git clone";
      gcle  = "git clean -fdi";
      gt    = "git ls-tree -r master --name-only";
      gb    = "git branch";
      gbr   = "git branch remote";
      gfr   = "git remote update";
      gm    = "git merge";
      gf    = "git fetch origin";
      gst   = "git stash";
      gfa   = "git fetch --all";
      grf   = "git reflog";
      grh   = "git reset --hard HEAD~";

      c  = "claude";
      la = "ls -la";
    };

    extraConfig = ''
      $env.config.show_banner = false
      $env.config.edit_mode = "vi"

      $env.config.history.file_format = "sqlite"
      $env.config.history.isolation = true

      $env.config.completions.algorithm = "fuzzy"
      $env.config.completions.external.enable = true

      # Ctrl+W opens the history menu (15 rows, shown even on an empty prompt)
      $env.config.keybindings = (
          $env.config.keybindings | append [
              {
                  name: ctrl_w_history_menu
                  modifier: control
                  keycode: char_w
                  mode: [emacs vi_insert vi_normal]
                  event: { send: menu name: history_menu }
              }
          ]
      )
      $env.config.menus = (
          $env.config.menus
          | upsert ($env.config.menus | enumerate | where item.name == "history_menu" | get index.0) { |m|
              $m | upsert only_buffer_difference false | upsert type.page_size 15
          }
      )

      # Aliases that need more than one command
      def gac [] { git add .; git commit -v }
      def gl [] {
          ^git log --graph --branches --abbrev-commit --decorate --all $"--format=format:%C\(bold green\)%h%C\(reset\) - %C\(bold cyan\)%aD%C\(reset\) %C\(bold red\)\(%ar\)%C\(reset\)%C\(auto\)%d%C\(reset\)%n          %C\(yellow\)%s%C\(reset\) %C\(cyan\)- %an%C\(reset\)"
      }

      # `y` (yazi, cd on exit) comes from programs.yazi's nushell integration.

      # mpv wrapper: load audio_history.lua only for audio files (copy the script from the Windows backup)
      def --wrapped mpv [...args] {
          let is_audio = ($args | any { |a| ($a | into string) =~ '(?i)\.(m4b|mp3|m4a|opus|ogg|flac|wav|aac)$' })
          if $is_audio {
              let script = ($env.HOME | path join ".config" "mpv" "scripts" "audio_history.lua")
              ^mpv --load-scripts=no $"--script=($script)" ...$args
          } else {
              ^mpv ...$args
          }
      }
    '';
  };

  # Completions for external commands in nushell (as on Windows).
  programs.carapace = {
    enable = true;
    environment.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
  };
}
