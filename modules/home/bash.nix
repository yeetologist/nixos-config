{ config, ... }:

{
  # Bash — fallback shell (used by scripts and login sessions)
  programs.bash = {
    enable = true;
    historyFile = "$HOME/.cache/bash/history"; # keep home dir clean

    shellAliases = {
      
    };
  };

  # Ensure the bash history directory exists before HM writes .bashrc
  home.activation.mkBashCacheDir = config.lib.dag.entryBefore [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/bash"
  '';
}

