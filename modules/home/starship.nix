{ ... }:

{
  # Same prompt as on Windows (catppuccin mocha powerline), in nushell.
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
