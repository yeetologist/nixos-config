# Home Manager configuration for the primary user.
# `user` is injected via extraSpecialArgs in flake.nix.
{ pkgs, config, user, host, ... }:

{
  imports = [
    ./modules/home/bash.nix
    ./modules/home/git.nix
    ./modules/home/niri.nix
    ./modules/home/nvim.nix
    ./modules/home/rofi.nix
    ./modules/home/waybar.nix
    ./modules/home/mpv.nix
    ./modules/home/yazi.nix
    ./modules/home/zsh.nix
    ./modules/home/starship.nix
    ./modules/home/nushell.nix
    ./modules/home/gh.nix
    ./modules/home/zed.nix
  ];

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  home.username    = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05"; # do NOT change after first activation

  programs.home-manager.enable = true; # let HM manage itself

  home.shellAliases = {
    # NixOS
    up  = "sudo nixos-rebuild switch --refresh --flake github:yeetologist/nixos-config#${host}"; # this host
    btw = "echo 'I use NixOS, btw'";
    
    # Editor
    vim     = "nvim";
    vimdiff = "nvim -d";
    magit   = "nvim -c MagitOnly";
    e       = "$EDITOR";

    # Core utilities — verbosity & safety
    cp  = "cp -iv";
    mv  = "mv -iv";
    rm  = "rm -vI";
    mkd = "mkdir -pv";

    # Colorized commands
    l    = "ls -lahNF --color=auto --group-directories-first";
    ll   = "ls -l";
    grep = "grep --color=auto";
    diff = "diff --color=auto";
    ccat = "highlight --out-format=ansi";

    # Common abbreviations
    se  = "sudoedit";
    sc  = "systemctl";
    jc  = "journalctl -r";
    ka  = "pkill";
    sdn = "sudo shutdown -h now";
    smi = "sudo make install";
    pt  = "patch --merge -i";
    t   = "tldr";
    W   = "which -a";
    wa  = "whatis";
    z   = "zathura";
    c   = "sync;sudo sysctl vm.drop_caches=3";

    # Filesystem
    lsf = "lsblk -f";
    dft = "df -Th";

    # Process inspection
    psmem = "ps -e -orss=,args= | sort -b -k1 -nr | head";
    pscpu = "ps -e -o pcpu,cpu,nice,state,cputime,args|sort -k1,1n -nr | head";

    # History
    h      = "history -i";
    hg     = "history -i 1 | grep -i";
    hist10 = "print -l \${(o)history%% *} | uniq -c | sort -nr | head -n 10";

    # yt-dlp
    yd      = "yt-dlp";
    yt      = "yt-dlp --add-metadata --write-sub --sub-lang 'en' -N 3 -i";
    yta     = "yt-dlp --add-metadata -N 3 -x -S 'ext' -f bestaudio/best -o '~/Downloads/Music/%(title)s_%(id)s.%(ext)s'";
    ytF     = "yt-dlp -F";
    ytf     = "yt-dlp -f";
    ytamp3  = "yt-dlp --extract-audio --audio-format 'mp3' -o '~/Downloads/Music/%(title)s_%(id)s.%(ext)s' -i";
    yt4     = "yt-dlp --add-metadata -S 'ext' -f 'bestvideo[height<=480]+bestaudio/best' -N '3' --write-sub --sub-lang 'en' -i";
    yt7     = "yt-dlp --add-metadata -S 'ext' -f 'bestvideo[height<=720]+bestaudio/best' -N '3' --write-sub --sub-lang 'en' -i";
    ytvbest = "yt-dlp --add-metadata -S 'ext' -f 'bv*+ba/b' -N '3' --write-sub --sub-lang 'en' -i";
    ytmeta  = "yt-dlp --add-metadata --write-description --write-info-json --write-annotations --write-sub --sub-lang en --write-thumbnail --skip-download -i";
    ytsub   = "yt-dlp --skip-download --write-auto-sub -i";
    yten    = "yt-dlp --write-sub --sub-lang en --skip-download -i";

    # Git
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
    gac   = "git add . && git commit -v";
    grs   = "git restore --staged";
    gr    = "git restore";
    grss  = "git restore --source";
    gre   = "git remote";
    gcl   = "git clone";
    gcle  = "git clean -fdi";
    gl    = "git log --graph --branches --abbrev-commit --decorate --format=format:'%C(bold green)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold red)(%ar)%C(reset)%C(auto)%d%C(reset)%n'' %C(yellow)%s%C(reset) %C(cyan)- %an%C(reset)' --all";
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
    gh    = "git help everyday";
  };

  # ---------------------------------------------------------------------------
  # User packages
  # System-level tools live in configuration.nix; user-facing apps go here.
  # ---------------------------------------------------------------------------
  home.packages = with pkgs; [
    # Browser & desktop
    brave
    ghostty            # GPU-accelerated terminal
    xwayland-satellite # XWayland for apps that don't support Wayland yet
    swaylock           # Wayland screen locker
    orca               # screen reader
    zathura            # document viewer

    # Clipboard & desktop controls
    wl-clipboard       # wl-copy / wl-paste for Wayland
    playerctl          # MPRIS media control
    brightnessctl      # backlight control

    # Development
    gnupg
    nodejs

    # Shell utilities
    tmux
    nnn
    highlight
    tldr

    # Media
    yt-dlp

    # Text processing
    ripgrep file
  ];
}
