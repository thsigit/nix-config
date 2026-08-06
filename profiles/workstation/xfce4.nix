# profiles/workstation/xfce4.nix

{ config, pkgs, callPackage, ... }:

let
  wallpaper = ../../assets/wallpaper.jpg;

  xfce-setup = pkgs.writeShellScript "xfce-theme-setup" ''
    export PATH="${pkgs.xfconf}/bin:${pkgs.xfce4-panel}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:$PATH"

    sleep 2

    XFCONF="xfconf-query"

    # ── Theme & appearance ──────────────────────────────────────────
    $XFCONF -c xsettings -p /Net/ThemeName -s "Adwaita-dark"
    $XFCONF -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
    $XFCONF -c xsettings -p /Gtk/FontName -s "Sans 10"
    $XFCONF -c xsettings -p /Gtk/MonospaceFontName -s "Monospace 10"
    $XFCONF -c xfwm4 -p /general/theme -s "Adwaita-dark"

    # Mouse cursor
    $XFCONF -c xsettings -p /Gtk/CursorThemeName -s "Bibata-Modern-Ice"
    $XFCONF -c xsettings -p /Gtk/CursorThemeSize -s 24

    # ── Desktop background ─────────────────────────────────────────
    for screen in screen0 screen1; do
      for monitor in $($XFCONF -c xfce4-desktop -l 2>/dev/null | \
        grep "/backdrop/$screen/" | sed 's|/backdrop/\([^/]*\)/\([^/]*\)/.*|\2|' | \
        sort -u || true); do
        $XFCONF -c xfce4-desktop \
          -p "/backdrop/$screen/$monitor/workspace0/image-style" \
          -t int -s 1 2>/dev/null || true
        $XFCONF -c xfce4-desktop \
          -p "/backdrop/$screen/$monitor/workspace0/last-image" \
          -t string -s "${wallpaper}" 2>/dev/null || true
      done
    done

    # ── Panel configuration ────────────────────────────────────────
    # Reset panels to clean state
    $XFCONF -c xfce4-panel -p /panels -r 2>/dev/null || true

    # Panel 1: top-right vertical (tasklist, clock)
    $XFCONF -c xfce4-panel -p /panels/panel-1/mode -t int -s 1
    $XFCONF -c xfce4-panel -p /panels/panel-1/size -t int -s 48
    $XFCONF -c xfce4-panel -p /panels/panel-1/length -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-1/position -t string \
      -s "p=8;x=1920;y=0"
    $XFCONF -c xfce4-panel -p /panels/panel-1/position-locked -t bool -s true
    $XFCONF -c xfce4-panel -p /panels/panel-1/background-style -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-1/icon-size -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-1/automatically-increase-size \
      -t bool -s false
    $XFCONF -c xfce4-panel -p /panels/panel-1/enter-opacity -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-1/leave-opacity -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-1/flat-buttons -t bool -s true

    # Panel 2: bottom-left vertical (whisker menu, systray)
    $XFCONF -c xfce4-panel -p /panels/panel-2/mode -t int -s 1
    $XFCONF -c xfce4-panel -p /panels/panel-2/size -t int -s 48
    $XFCONF -c xfce4-panel -p /panels/panel-2/length -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-2/position -t string \
      -s "p=6;x=0;y=0"
    $XFCONF -c xfce4-panel -p /panels/panel-2/position-locked -t bool -s true
    $XFCONF -c xfce4-panel -p /panels/panel-2/background-style -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-2/icon-size -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-2/automatically-increase-size \
      -t bool -s false
    $XFCONF -c xfce4-panel -p /panels/panel-2/enter-opacity -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-2/leave-opacity -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-2/flat-buttons -t bool -s true

    # ── Panel plugins ──────────────────────────────────────────────
    # Discover existing plugin IDs
    get_plugins() {
      $XFCONF -c xfce4-panel -p /panels/$1/plugin-ids 2>/dev/null | \
        tr '\n' ' '
    }

    P1_PLUGINS=$(get_plugins panel-1)
    P2_PLUGINS=$(get_plugins panel-2)

    # Only set up plugins if panels are empty
    if [ -z "$P1_PLUGINS" ]; then
      # Panel 1 (top-right): clock, separator, tasklist, separator, actions
      $XFCONF -c xfce4-panel -p /panels/panel-1/plugin-ids \
        -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 5

      $XFCONF -c xfce4-panel -p /plugins/plugin-1 -s "clock"
      $XFCONF -c xfce4-panel -p /plugins/plugin-1/digital-format \
        -t string -s "%R"

      $XFCONF -c xfce4-panel -p /plugins/plugin-2 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-2/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-3 -s "tasklist"
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/show-labels \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/show-wireframes \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/grouping \
        -t int -s 1

      $XFCONF -c xfce4-panel -p /plugins/plugin-4 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-4/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-5 -s "actions"
    fi

    if [ -z "$P2_PLUGINS" ]; then
      # Panel 2 (bottom-left): whisker-menu, separator, systray
      $XFCONF -c xfce4-panel -p /panels/panel-2/plugin-ids \
        -t int -s 6 -t int -s 7 -t int -s 8

      $XFCONF -c xfce4-panel -p /plugins/plugin-6 -s "whisker-menu"

      $XFCONF -c xfce4-panel -p /plugins/plugin-7 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-7/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-8 -s "systray"
    fi

    # ── Disable screen blanking / power manager tray ───────────────
    $XFCONF -c xfce4-power-manager -p /xfce4-power-manager/show-tray-icon \
      -t int -s 0

    # ── Window manager tweaks ──────────────────────────────────────
    $XFCONF -c xfwm4 -p /general/use_compositing -t bool -s true
    $XFCONF -c xfwm4 -p /general/show_frame_shadow -t bool -s true

    # ── Desktop icons ──────────────────────────────────────────────
    $XFCONF -c xfce4-desktop -p /desktop-icons/style -t int -s 0
  '';
in
{
  nixpkgs.config.pulseaudio = true;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager.lightdm.enable = false;
  };

  services.displayManager = {
    defaultSession = "xfce";
    sddm = {
      enable = true;
      extraPackages = [ pkgs.sddm-astronaut ];
      theme = "sddm-astronaut";
    };
    autoLogin = {
      enable = true;
      user = "sigit";
    };
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  environment.systemPackages = with pkgs; [
    xinit
    xfce4-whiskermenu-plugin
    bibata-cursors
    papirus-icon-theme
    arc-theme
    plano-theme
    vimix-icon-theme	
  ];

  environment.xfce.excludePackages = with pkgs; [
    mousepad
    ristretto
  ];

  environment.etc."xdg/autostart/xfce-theme-setup.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=XFCE Theme Setup
    Exec=${xfce-setup}
    OnlyShowIn=XFCE;
    X-GNOME-Autostart-enabled=true;
    NoDisplay=true;
  '';
}
