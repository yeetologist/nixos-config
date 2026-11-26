{ lib, ... }:

{
  # Ported from Windows %APPDATA%\nushell. zsh stays the login shell; run `nu` when you want it.
  programs.nushell = {
    enable = true;
    # HM copies home.shellAliases here; they're zsh syntax (&&, ${...}) and stop nushell loading its config.
    shellAliases = lib.mkForce { };
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

      alias c = claude
      alias la = ls -la

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

  # Completions for external commands in nushell (as on Windows). Left out of zsh: it has its own.
  programs.carapace = {
    enable = true;
    enableZshIntegration = false;
    environment.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
  };
}
