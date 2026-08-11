# profiles/workstation/home.nix
# Home-manager user config for sigit.
{ config, lib, pkgs, ... }:

let
  wallpaper = ../../assets/wallpaper.jpg;
in
{
  home = {
    username = "sigit";
    homeDirectory = "/home/sigit";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "thsigit";
      user.email = "th.sigit@gmail.com";
      safe.directory = [ "/srv/repo/nix-config" ];
    };
  };

  # Save the current XFCE panel config declaratively.
  home.file = {
    ".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" = {
      source = ./xfce4-panel.xml;
      force = true;
    };
    ".config/xfce4/panel/launcher-13/17860240691.desktop" = {
      source = ./panel/launcher-13/17860240691.desktop;
      force = true;
    };
    ".config/xfce4/panel/launcher-14/17860240832.desktop" = {
      source = ./panel/launcher-14/17860240832.desktop;
      force = true;
    };
    ".config/xfce4/panel/launcher-15/17860241034.desktop" = {
      source = ./panel/launcher-15/17860241034.desktop;
      force = true;
    };
    ".config/xfce4/panel/launcher-16/17860241426.desktop" = {
      source = ./panel/launcher-16/17860241426.desktop;
      force = true;
    };
    ".config/autostart/Deskflow.desktop" = {
      source = ./autostart/Deskflow.desktop;
      force = true;
    };
    ".config/mimeapps.list" = {
      source = ./mimeapps.list;
      force = true;
    };
  };

  # Declarative XFCE settings via xfconf.
  xfconf.settings = {
    "xfce4-desktop" = {
      "backdrop/screen0/monitoreDP-1/workspace0/last-image" = "${wallpaper}";
      "backdrop/screen0/monitoreDP-1/workspace0/image-style" = 3;
      "backdrop/screen0/monitoreDP-1/workspace0/image-show" = true;
    };
  };
}
