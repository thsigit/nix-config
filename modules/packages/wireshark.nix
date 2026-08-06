# programs/wireshark.nix

{ config, lib, pkgs, ... }:

{
  programs.wireshark = {
    enable = true;
    package = lib.mkDefault pkgs.wireshark-cli;
    dumpcap.enable = true;
  };
}
