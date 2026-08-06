# programs/mpv.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mpv yt-dlp
  ];
}
