# common/packages/wireshark.nix

{ config, lib, pkgs, ... }:

{
  programs.wireshark = {
    enable = true;
    package = lib.mkDefault pkgs.tshark;
  };
}
