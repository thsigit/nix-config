# modules/core/users.nix

{ config, lib, pkgs, ... }:
{
  users.users.sigit = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "ydotool" ];
    packages = with pkgs; [];
  };

  services.getty.autologinUser = "sigit";
}