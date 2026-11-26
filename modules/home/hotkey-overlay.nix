# modules/home/hotkey-overlay.nix
# Custom multi-column, categorized hotkey cheatsheet replacing niri's
# single-column built-in overlay on Mod+Shift+/.
{ pkgs, ... }:
let
  renderCheatsheet = pkgs.writeScript "hotkey-overlay-render" ''
    #!${pkgs.python3}/bin/python3
    import os
    import sys
    import termios
    import tty

    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    DIM    = "\033[2m"
    BLUE   = "\033[38;2;122;162;247m"
    CYAN   = "\033[38;2;125;207;255m"
    PURPLE = "\033[38;2;187;154;247m"
    GREEN  = "\033[38;2;158;206;106m"
    YELLOW = "\033[38;2;224;175;104m"
    RED    = "\033[38;2;247;118;142m"
    FG     = "\033[38;2;192;202;245m"
    MUTED  = "\033[38;2;86;95;137m"
    KEY_BG = "\033[48;2;41;46;66m"

    # 3 columns x 2 category blocks each
    COLUMNS = [
        [
            ("Apps & Menus", BLUE, [
                ("Mod + D",           "App launcher (Rofi)"),
                ("Mod + T",           "Terminal (Ghostty)"),
                ("Mod + E",           "File manager (yazi)"),
                ("Mod + Shift + E",   "File manager (Thunar)"),
                ("Mod + P",           "Display menu (Win+P)"),
                ("Mod + N",           "Notifications (SwayNC)"),
                ("Mod + V",           "Clipboard history"),
                ("Mod + .",           "Emoji picker"),
                ("Mod + X",           "Power menu"),
                ("Ctrl + Shift + Esc","Task Manager (btop)"),
                ("Alt + Tab",         "Window switcher"),
                ("Mod + Ctrl + V",    "Audio mixer"),
            ]),
            ("Screenshots & Media", GREEN, [
                ("Print / Mod+Shift+S", "Interactive screenshot"),
                ("Ctrl + Print",        "Screenshot screen"),
                ("Alt + Print",         "Screenshot window"),
                ("Vol + / - / Mute",    "Volume +/-10% / mute"),
                ("Mic Mute",            "Mute microphone"),
                ("Play / Prev / Next",  "Media controls"),
                ("Brightness + / -",    "Screen brightness +/-10%"),
            ]),
        ],
        [
            ("Windows & Columns", PURPLE, [
                ("Mod + Q",             "Close window"),
                ("Mod + O",             "Toggle overview"),
                ("Mod + H / L",         "Focus column L / R"),
                ("Mod + J / K",         "Focus win / ws down/up"),
                ("Mod + Shift + H / L", "Move column L / R"),
                ("Mod + Shift + J / K", "Move win / across ws"),
                ("Mod + Home / End",    "Focus first / last col"),
                ("Mod + Shift+Hm/End",  "Move to first / last col"),
                ("Mod + [ / ]",         "Consume / expel L / R"),
                ("Mod + ,",             "Consume into column"),
                ("Mod + Shift + Space", "Toggle floating"),
                ("Mod + Shift + V",     "Focus floating / tiling"),
                ("Mod + W",             "Toggle tabbed column"),
            ]),
            ("Sizing & Layout", CYAN, [
                ("Mod + R / Shift+R",   "Cycle width preset"),
                ("Mod + Ctrl + R",      "Reset window height"),
                ("Mod + Ctrl+Shift+R",  "Cycle height preset"),
                ("Mod + F",             "Maximize column"),
                ("Mod + Shift + F",     "Fullscreen window"),
                ("Mod + Ctrl + F",      "Expand to fill width"),
                ("Mod + C / Ctrl+C",    "Center col / visible"),
                ("Mod + - / =",         "Column width -/+10%"),
                ("Mod + Shift + - / =", "Window height -/+10%"),
            ]),
        ],
        [
            ("Workspaces & Monitors", YELLOW, [
                ("Mod + 1..9",          "Focus workspace 1-9"),
                ("Mod + Ctrl + 1..9",   "Move col to ws 1-9"),
                ("Mod + PgUp / PgDn",   "Focus ws up / down"),
                ("Mod + Ctrl+PgUp/Dn",  "Move col to ws up/dn"),
                ("Mod + Shift+PgUp/Dn", "Move ws up / down"),
                ("Mod + Ctrl + HJKL",   "Focus monitor"),
                ("Mod+Ctrl+Shift+HJKL", "Move col to monitor"),
                ("Mod + Scroll",        "Scroll ws / columns"),
            ]),
            ("System", RED, [
                ("Mod + Alt + L",       "Lock screen"),
                ("Mod + Shift + P",     "Power off monitors"),
                ("Mod + Esc",           "Toggle shortcut inhibit"),
                ("Mod + Shift + /",     "This hotkey cheatsheet"),
                ("Ctrl + Alt + Del",    "Quit Niri"),
                ("Super + Alt + S",     "Toggle screen reader"),
            ]),
        ],
    ]

    KEY_W  = 21
    DESC_W = 24
    COL_W  = KEY_W + 2 + DESC_W
    GAP    = "   "

    def render_column(sections):
        lines = []
        for idx, (title, color, entries) in enumerate(sections):
            if idx > 0:
                lines.append("")
            bar = "─" * max(1, COL_W - len(title) - 1)
            lines.append(f"{BOLD}{color}{title} {MUTED}{bar}{RESET}")
            for key, desc in entries:
                k = f"{key:<{KEY_W}}"
                d = f"{desc:<{DESC_W}}"
                lines.append(f"{KEY_BG}{BOLD}{FG} {k}{RESET} {FG}{d}{RESET}")
        return lines

    rendered = [render_column(col) for col in COLUMNS]
    max_rows = max(len(c) for c in rendered)
    blank = " " * COL_W

    sys.stdout.write("\033[2J\033[H\033[?25l")
    header = "Keyboard Shortcuts"
    hint   = "Press Esc, q, or Mod+Shift+/ to close"
    total_w = COL_W * len(rendered) + len(GAP) * (len(rendered) - 1)
    pad = max(1, total_w - len(header) - len(hint))
    sys.stdout.write(f"{BOLD}{BLUE}{header}{RESET}{' ' * pad}{DIM}{FG}{hint}{RESET}\n\n")

    for r in range(max_rows):
        row_parts = [col[r] if r < len(col) else blank for col in rendered]
        sys.stdout.write(GAP.join(row_parts) + "\n")
    sys.stdout.flush()

    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        while True:
            ch = os.read(fd, 1)
            if ch in (b"\x1b", b"q", b"Q", b"\r", b"\n", b" ", b"\x03"):
                break
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()
  '';

  hotkeyOverlay = pkgs.writeShellApplication {
    name = "hotkey-overlay";
    runtimeInputs = with pkgs; [ procps ];
    text = ''
      if pkill -f "hotkey-overlay-render" 2>/dev/null; then
        exit 0
      fi
      exec ghostty \
        --class=com.bam.hotkeys \
        --title="Keyboard Shortcuts" \
        --font-size=13 \
        --window-padding-x=22 \
        --window-padding-y=16 \
        --confirm-close-surface=false \
        -e ${renderCheatsheet}
    '';
  };
in
{
  home.packages = [ hotkeyOverlay ];

  programs.niri.settings = {
    window-rules = [
      {
        matches = [ { app-id = "^com\\.bam\\.hotkeys$"; } ];
        open-floating = true;
        default-column-width = { proportion = 0.88; };
        default-window-height = { proportion = 0.72; };
      }
    ];

    binds."Mod+Shift+Slash" = {
      hotkey-overlay.title = "Show hotkey cheatsheet";
      action.spawn = [ "hotkey-overlay" ];
      repeat = false;
    };
  };
}
