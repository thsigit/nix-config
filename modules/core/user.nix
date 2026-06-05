# modules/core/user.nix

{ config, lib, pkgs, ... }:

{  # User Account
  users.users.sigit = {
    isNormalUser = true;
    description = "Sigit Prasetyo";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "podman" "ydotool" ];
    packages = with pkgs; [];
  };
  
  # Otomatis login ke TTY
  services.getty.autologinUser = "sigit";  
}