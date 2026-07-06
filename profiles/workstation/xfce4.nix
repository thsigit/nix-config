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
  };

  services.displayManager = {
    defaultSession = "xfce";
    sddm = {
	  enable = true;
      theme = "pkgs.sddm-sugar-dark";
      # autoLogin.relogin = true;
    };
    autoLogin = {
      enable = true;
      user = "sigit";
    }; 
  };

  environment.systemPackages = with pkgs; [
    xfce4-whiskermenu-plugin
  ];

  environment.xfce.excludePackages = with pkgs; [
    mousepad
    ristretto
  ];
}