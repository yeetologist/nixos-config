{ lib, ... }:

{
  # Editor preferences from Windows. Private keys (agent, language_models, edit_predictions,
  # proxy, server_url, ssh_connections) stay out of this public repo: add them in Zed's UI.
  # No package by default, so hosts without Zed (the VM) get only the settings file;
  # hosts/tuf sets the package.
  programs.zed-editor = {
    enable = true;
    package = lib.mkDefault null;
    mutableUserSettings = true; # changes made in Zed's UI keep working
    userSettings = {
      theme = { mode = "dark"; light = "One Light"; dark = "Ayu Dark"; };
      icon_theme = { mode = "dark"; light = "Zed (Default)"; dark = "Zed (Default)"; };
      ui_font_size = 15;
      buffer_font_size = 14;
      soft_wrap = "editor_width";
      autosave = "on_focus_change";
      line_ending = "enforce_lf";
      cli_default_open_behavior = "existing_window";
      telemetry = { diagnostics = false; metrics = false; anthropic_retention = false; };
      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        shell.program = "nu";
      };
      languages.Python = {
        language_servers = [ "ty" "!basedpyright" "..." ];
        formatter.language_server.name = "ruff";
        code_actions_on_format."source.organizeImports.ruff" = true;
      };
    };
  };
}
