# commons/network/zerotier.nix
{ config, pkgs, lib, ... }:
{
  services.zerotierone = { enable = true; };
}
