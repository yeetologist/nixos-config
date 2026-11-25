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
  };
}
