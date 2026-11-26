# modules/home/zathura.nix
# PDF viewer config ported from bam-dotfiles, with Tokyo Night dark palette.
{ ... }:

{
  programs.zathura = {
    enable = true;

    options = {
      sandbox = "none";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
      selection-clipboard = "clipboard";
      adjust-open = "width";
      window-title-basename = true;

      # Dark mode page recolor ON by default (press `i` to toggle original colors)
      recolor = true;
      recolor-keephue = true;
      recolor-lightcolor = "#1a1b26";
      recolor-darkcolor = "#c0caf5";

      # Tokyo Night UI colors
      default-bg = "#1a1b26";
      default-fg = "#c0caf5";
      statusbar-bg = "#1a1b26";
      statusbar-fg = "#c0caf5";
      inputbar-bg = "#1a1b26";
      inputbar-fg = "#c0caf5";
      notification-bg = "#1a1b26";
      notification-fg = "#c0caf5";
      notification-error-bg = "#f7768e";
      notification-error-fg = "#1a1b26";
      notification-warning-bg = "#e0af68";
      notification-warning-fg = "#1a1b26";
      completion-bg = "#1a1b26";
      completion-fg = "#a9b1d6";
      completion-group-bg = "#1a1b26";
      completion-group-fg = "#7aa2f7";
      completion-highlight-bg = "#292e42";
      completion-highlight-fg = "#c0caf5";
      index-bg = "#1a1b26";
      index-fg = "#c0caf5";
      index-active-bg = "#292e42";
      index-active-fg = "#7aa2f7";
      highlight-color = "rgba(224, 175, 104, 0.45)";
      highlight-active-color = "rgba(122, 162, 247, 0.55)";
      render-loading = true;
      render-loading-bg = "#1a1b26";
      render-loading-fg = "#c0caf5";
    };

    mappings = {
      "[" = "navigate previous";
      "]" = "navigate next";
      u   = "scroll half-up";
      d   = "scroll half-down";
      D   = "toggle_page_mode";
      r   = "reload";
      R   = "rotate";
      K   = "zoom in";
      J   = "zoom out";
      i   = "recolor";
      p   = "print";
    };
  };
}
