{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      core = {
        autocrlf = "input";
      };
    };
  };
}
