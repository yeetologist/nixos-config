{ pkgs, config, lib, ... }:

{
  programs.zsh = {
    enable                    = true;
    enableCompletion          = true;
    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;

    # -------------------------------------------------------------------------
    # Shell options  (setopt)
    # -------------------------------------------------------------------------
    setOptions = [
      "AUTO_CD"
      "INTERACTIVE_COMMENTS"
      # History deduplication
      "EXTENDED_HISTORY"
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_ALL_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_FIND_NO_DUPS"
      "HIST_SAVE_NO_DUPS"
      "HIST_BEEP"
    ];

    # -------------------------------------------------------------------------
    # History
    # -------------------------------------------------------------------------
    history = {
      size       = 10000;
      save       = 10000;
      path       = "$HOME/.cache/zsh/history";
      extended   = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # -------------------------------------------------------------------------
    # Oh-My-Zsh
    # -------------------------------------------------------------------------
    oh-my-zsh = {
      enable  = true;
      plugins = [ "git" "sudo" ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # -------------------------------------------------------------------------
    # Shell aliases
    # -------------------------------------------------------------------------
    shellAliases = {

    };
  };

  # ---------------------------------------------------------------------------
  # NNN environment variables  (sessionVariables → /etc/set-environment)
  # ---------------------------------------------------------------------------
  home.sessionVariables = {
    NNN_FIFO       = "/tmp/nnn.fifo";
    NNN_ARCHIVE    = "\\.(gz|tar|xz|rar|zip|zst)$";
    NNN_COLORS     = "3162";
    NNN_TMPFILE    = "/tmp/.lastd";
    NNN_PREVIEWDIR = "$XDG_CACHE_HOME/nnn/previews";
    NNN_PLUG = builtins.concatStringsSep ";" [
      "b:!realpath \"$nnn\">>/home/bam/.config/shell/shortcutrc*"
      "c:!code \"$nnn\"*"
      "n:!nvim -c VimwikiIndex"
      "v:!mpv \"$nnn\"*"
      "w:!setbg \"$nnn\"*"
      "*:togglex"
      "3:mp3conv"
      "d:diffs"
      "D:dups"
      "e:fzplug"
      "f:fixname"
      "i:imgview"
      "I:imgur"
      "k:pskill"
      "m:cmusq"
      "M:mimelist"
      "o:fzopen"
      "O:organize"
      "p:preview-tabbed"
      "P:preview-tui"
      "r:ringtone"
      "s:suedit"
      "S:splitjoin"
      "V:addtoplaylist"
      "x:xdgdefault"
    ];
    NNN_BMS = builtins.concatStringsSep ";" [
      "a:$HOME/dl/Videos/Animes"
      "b:$HOME/.local/bin"
      "c:$HOME/.config"
      "C:$HOME/.cache"
      "d:$HOME/dl"
      "D:$HOME/Documents"
      "e:$HOME/dl/Videos/Essential"
      "g:$HOME/dl/git-clone"
      "j:$HOME/dl/jd"
      "l:$HOME/.local"
      "m:$HOME/dl/Music"
      "M:/mnt"
      "n:$HOME/dl/Novel"
      "p:$HOME/dl/Programs"
      "P:$HOME/dl/Pictures"
      "s:$HOME/dl/Videos/Series"
      "S:$HOME/.local/src"
      "t:$HOME/dl/Torrent"
      "v:$HOME/dl/Videos"
      "w:$HOME/dl/Pictures/Wallpapers"
      "y:$HOME/dl/Videos/Youtube"
    ];
  };
  
  # Zsh config lives in ./modules/home/zsh.nix
  # Ensure the zsh history directory exists before HM activation writes the .zshrc
  home.activation.mkZshCacheDir = config.lib.dag.entryBefore [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/zsh"
  '';

  # Link the powerlevel10k configuration
  home.file.".p10k.zsh".source = ./.p10k.zsh;

  # Powerlevel10k instant prompt must be loaded at the very beginning of .zshrc
  programs.zsh.initContent = lib.mkMerge [
    # Replaces initExtraFirst
    (lib.mkBefore ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '')
    # Replaces initExtra
    ''
      # Source p10k config
      [[ ! -f ./.p10k.zsh ]] || source ./.p10k.zsh
      
      # Greeting
      # fastfetch

      # -----------------------------------------------------------------------
      # Completion styling
      # -----------------------------------------------------------------------
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[-_.]=* r:|=*' 'm:{a-z}={A-Z} r:|[-_.]=* r:|=*'
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*:descriptions' format "$fg[yellow]%B--- %d%b"
      zstyle ':completion:*:messages'     format '%d'
      zstyle ':completion:*:warnings'     format "$fg[red]No matches for:$reset_color %d"
      zstyle ':completion:*:corrections'  format '%B%d (errors: %e)%b'
      zstyle ':completion:*' group-name   ""
      # Include hidden files in completion
      _comp_options+=(globdots)

      # -----------------------------------------------------------------------
      # Vi mode
      # -----------------------------------------------------------------------
      bindkey -v
      export KEYTIMEOUT=1

      # Vim keys in tab-complete menu
      bindkey -M menuselect 'h' vi-backward-char
      bindkey -M menuselect 'k' vi-up-line-or-history
      bindkey -M menuselect 'l' vi-forward-char
      bindkey -M menuselect 'j' vi-down-line-or-history
      bindkey -v '^?' backward-delete-char

      # Cursor shape: block in normal mode, beam in insert mode
      function zle-keymap-select {
        if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
          echo -ne '\e[1 q'
        elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || \
             [[ ''${KEYMAP} = "" ]] || [[ $1 = 'beam' ]]; then
          echo -ne '\e[5 q'
        fi
      }
      zle -N zle-keymap-select

      zle-line-init() {
        zle -K viins
        echo -ne "\e[5 q"
      }
      zle -N zle-line-init
      echo -ne '\e[5 q'             # beam cursor on startup
      preexec() { echo -ne '\e[5 q'; } # beam cursor before each command

      # -----------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------
      bindkey -s '^o' 'n\n'                          # open nnn
      bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'   # fzf cd
      bindkey -s '^p' 'ping -c 2 google.com\n'
      bindkey '^[[P' delete-char
      # Edit current line in $EDITOR (ctrl-e)
      autoload edit-command-line; zle -N edit-command-line
      bindkey '^e' edit-command-line

      # -----------------------------------------------------------------------
      # NNN wrapper — cd on quit
      # -----------------------------------------------------------------------
      n() {
        nnn -HQdexr "$@"
        [ -f "$NNN_TMPFILE" ] && . "$NNN_TMPFILE" && rm -f "$NNN_TMPFILE" > /dev/null
      }
    ''
  ];
}
