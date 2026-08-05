# modules/ai/litellm/cli.nix
# CLI tools for provider management
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, pkgs, ... }:

let
  gw = config.litellm.gateway;
in lib.mkIf config.litellm.enable {
  environment.systemPackages = gw.systemPackages;
}
