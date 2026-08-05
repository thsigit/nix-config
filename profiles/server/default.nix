# profiles/server/default.nix
#

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/network
    ../../modules/storage
    ../../modules/security
    ../../modules/monitoring
    ../../modules/caddy
    ../../modules/media
    #../../modules/ai
  ];
}
