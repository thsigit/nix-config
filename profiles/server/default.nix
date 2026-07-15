# profiles/server/default.nix
#
# Placeholder — this profile is reserved for a future headless
# server machine that does not need a desktop environment.
# When ready, import the required modules from ../../modules/.
#
# Example:
#
#   imports = [
#     ../../modules/core
#     ../../modules/network
#     ../../modules/storage
#     ../../modules/security
#     ../../modules/caddy
#     # etc.
#   ];

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
    ../../modules/ai
  ];
}
