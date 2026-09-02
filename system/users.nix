# system/users.nix

{ config, lib, pkgs, ... }:
let
  inherit (import ../settings) user;
in
{
  users.users.${user.name} = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "ydotool" ];
    packages = with pkgs; [];
  };

  services.getty.autologinUser = user.name;
}
