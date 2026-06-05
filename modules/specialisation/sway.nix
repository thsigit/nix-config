# /etc/nixos/modules/specialisation/sway.nix

{ config, pkgs, lib, ... }:

{
  programs.sway.enable = true;
  services.seatd.enable = true;
  programs.waybar.enable = true;

  security.polkit.enable = true;
  services.greetd.enable = true;
  services.greetd.settings.default_session.command =
  "${pkgs.sway}/bin/sway";  
  
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
  };

  environment.systemPackages = with pkgs; [
    foot
    fuzzel
    wl-clipboard
    deskflow
    grim
    slurp
  ];
}