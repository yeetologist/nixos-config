{ ... }:

{
  # Login (hosts.yml) stays out of the repo: run `gh auth login` once per machine.
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };
}
