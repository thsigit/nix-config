# profiles/workstation/xfce4.nix

{ config, pkgs, callPackage, ... }:

{
  # if you use pulseaudio
  nixpkgs.config.pulseaudio = true;

  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    # Disable LightDM so SDDM can work
    displayManager.lightdm.enable = false;
  };

  services.displayManager = {
    defaultSession = "xfce";
    sddm = {
      enable = true;
      theme = "pkgs.sddm-sugar-dark";
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
    sddm-sugar-dark

    (writeShellScriptBin "xfce-setup" ''
      ${xfconf}/bin/xfconf-query \
        -c xfce4-desktop \
        -p /backdrop/screen0/monitoreDP-1/workspace0/image-style \
        -t int \
        -s 1
      
      ${xfconf}/bin/xfconf-query \
        -c xfce4-desktop \
        -p /backdrop/screen0/monitoreDP-1/workspace0/last-image \
        -t string \
        -s ${../../assets/wallpaper.jpg}
    '')
  ];

  environment.xfce.excludePackages = with pkgs; [
    mousepad
    ristretto
  ];

  environment.etc."xdg/autostart/xfce-setup.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=XFCE Setup
    Exec=xfce-setup
    OnlyShowIn=XFCE;
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

}
