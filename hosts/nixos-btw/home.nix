# VMware-only Home Manager bits: host <-> guest clipboard under niri.
{ pkgs, lib, ... }:
let
  # vmusr only syncs the X clipboard and has no window, so xwayland-satellite never bridges it.
  # shortcut: text only, trailing newlines dropped; replace if images/files must cross.
  clipSync = pkgs.writeShellScript "clip-sync" ''
    export PATH=${lib.makeBinPath [ pkgs.wl-clipboard pkgs.xclip pkgs.clipnotify pkgs.coreutils ]}:$PATH
    # Wayland -> X (both selections, vmusr picks either when handing to the host)
    wl-paste -t text --watch sh -c 'new=$(cat); [ "$new" = "$(xclip -o -sel clipboard 2>/dev/null)" ] || { printf %s "$new" | xclip -sel primary; printf %s "$new" | xclip -sel clipboard; }' &
    # X (vmusr, host) -> Wayland
    while clipnotify -s clipboard; do
      new=$(xclip -o -sel clipboard 2>/dev/null) || continue
      [ "$new" = "$(wl-paste -n 2>/dev/null)" ] || printf %s "$new" | wl-copy
    done
  '';
in
{
  # niri starts xwayland-satellite itself and sets DISPLAY; vmusr syncs the clipboard through it.
  # Lists merge with spawn-at-startup in modules/home/niri.nix.
  programs.niri.settings.spawn-at-startup = [
    { command = [ "sh" "-c" "sleep 2 && vmtoolsd -n vmusr" ]; }
    { command = [ "${clipSync}" ]; }
  ];
}
