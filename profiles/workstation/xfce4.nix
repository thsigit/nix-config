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

    # Dark mode
    $XFCONF -c xfce4-panel -p /panels/dark-mode -t bool -s true

    # Panel 1: top-right vertical (launchers, tasklist)
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

    # Panel 2: bottom-left vertical (whisker menu, systray, tasklist, etc)
    $XFCONF -c xfce4-panel -p /panels/panel-2/mode -t int -s 1
    $XFCONF -c xfce4-panel -p /panels/panel-2/size -t int -s 48
    $XFCONF -c xfce4-panel -p /panels/panel-2/length -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-2/position -t string \
      -s "p=2;x=1341;y=384"
    $XFCONF -c xfce4-panel -p /panels/panel-2/position-locked -t bool -s false
    $XFCONF -c xfce4-panel -p /panels/panel-2/background-style -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-2/icon-size -t int -s 0
    $XFCONF -c xfce4-panel -p /panels/panel-2/automatically-increase-size \
      -t bool -s false
    $XFCONF -c xfce4-panel -p /panels/panel-2/enter-opacity -t int -s 100
    $XFCONF -c xfce4-panel -p /panels/panel-2/leave-opacity -t int -s 100

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
      # Panel 1 (top-right): launcher, tasklist, launcher, launcher
      $XFCONF -c xfce4-panel -p /panels/panel-1/plugin-ids \
        -t int -s 1 -t int -s 3 -t int -s 4 -t int -s 5

      $XFCONF -c xfce4-panel -p /plugins/plugin-1 -s "launcher"
      $XFCONF -c xfce4-panel -p /plugins/plugin-1/items \
        -t string -s "17860075383.desktop"

      $XFCONF -c xfce4-panel -p /plugins/plugin-3 -s "tasklist"
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/show-labels \
        -t bool -s true
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/show-handle \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-3/grouping \
        -t int -s 1

      $XFCONF -c xfce4-panel -p /plugins/plugin-4 -s "launcher"
      $XFCONF -c xfce4-panel -p /plugins/plugin-4/items \
        -t string -s "17860075765.desktop"

      $XFCONF -c xfce4-panel -p /plugins/plugin-5 -s "launcher"
      $XFCONF -c xfce4-panel -p /plugins/plugin-5/items \
        -t string -s "17860077366.desktop"
    fi

    if [ -z "$P2_PLUGINS" ]; then
      # Panel 2 (bottom-left): whisker-menu, separator, tasklist, separator,
      #   separator, systray, showdesktop, power-manager, pulseaudio, separator, directorymenu
      $XFCONF -c xfce4-panel -p /panels/panel-2/plugin-ids \
        -t int -s 6 -t int -s 14 -t int -s 12 -t int -s 15 \
        -t int -s 13 -t int -s 11 -t int -s 9 -t int -s 8 \
        -t int -s 7 -t int -s 16 -t int -s 10

      $XFCONF -c xfce4-panel -p /plugins/plugin-6 -s "whiskermenu"
      $XFCONF -c xfce4-panel -p /plugins/plugin-6/menu-width -t int -s 450
      $XFCONF -c xfce4-panel -p /plugins/plugin-6/view-mode -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-7 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-7/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-8 -s "power-manager-plugin"

      $XFCONF -c xfce4-panel -p /plugins/plugin-9 -s "pulseaudio"
      $XFCONF -c xfce4-panel -p /plugins/plugin-9/enable-keyboard-shortcuts \
        -t bool -s true

      $XFCONF -c xfce4-panel -p /plugins/plugin-10 -s "showdesktop"
      $XFCONF -c xfce4-panel -p /plugins/plugin-10/show-on-hover \
        -t bool -s false

      $XFCONF -c xfce4-panel -p /plugins/plugin-11 -s "systray"
      $XFCONF -c xfce4-panel -p /plugins/plugin-11/icon-size -t int -s 0
      $XFCONF -c xfce4-panel -p /plugins/plugin-11/single-row \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-11/square-icons \
        -t bool -s false

      $XFCONF -c xfce4-panel -p /plugins/plugin-12 -s "tasklist"
      $XFCONF -c xfce4-panel -p /plugins/plugin-12/show-handle \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-12/show-labels \
        -t bool -s true

      $XFCONF -c xfce4-panel -p /plugins/plugin-13 -s "windowmenu"
      $XFCONF -c xfce4-panel -p /plugins/plugin-13/all-workspaces \
        -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-13/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-14 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-14/expand -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-14/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-15 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-15/expand -t bool -s true
      $XFCONF -c xfce4-panel -p /plugins/plugin-15/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-16 -s "separator"
      $XFCONF -c xfce4-panel -p /plugins/plugin-16/expand -t bool -s false
      $XFCONF -c xfce4-panel -p /plugins/plugin-16/style -t int -s 0

      $XFCONF -c xfce4-panel -p /plugins/plugin-17 -s "notification-plugin"

      $XFCONF -c xfce4-panel -p /plugins/plugin-18 -s "directorymenu"
      $XFCONF -c xfce4-panel -p /plugins/plugin-18/base-directory \
        -t string -s "/home/sigit"
      $XFCONF -c xfce4-panel -p /plugins/plugin-18/items \
        -t string -s "17860074631.desktop"
    fi

    # ── Disable power manager tray icon ────────────────────────────
    $XFCONF -c xfce4-power-manager -p /xfce4-power-manager/show-tray-icon \
      -t int -s 0
    $XFCONF -c xfce4-power-manager -p \
      /xfce4-power-manager/brightness-switch-restore-on-exit \
      -t int -s 1

    # ── Window manager tweaks ──────────────────────────────────────
    $XFCONF -c xfwm4 -p /general/use_compositing -t bool -s true
    $XFCONF -c xfwm4 -p /general/show_frame_shadow -t bool -s true
    $XFCONF -c xfwm4 -p /general/workspace_count -t int -s 4

    # ── Desktop icons ──────────────────────────────────────────────
    $XFCONF -c xfce4-desktop -p /desktop-icons/style -t int -s 0

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

  programs.xfconf.enable = true;
  programs.thunar.enable = true;

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
