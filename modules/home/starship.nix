{ ... }:

{
  # Same prompt as on Windows (catppuccin mocha powerline). Hooks into zsh and nushell.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
