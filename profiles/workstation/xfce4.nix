# profiles/workstation/xfce4.nix

{ config, pkgs, callPackage, ... }:

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
    xfce4-panel-profiles
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
}
