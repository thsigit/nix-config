# modules/ai/litellm/activation.nix
# Build-time artifacts and activation scripts
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, pkgs, ... }:

let
  gw = config.litellm.gateway;
in lib.mkIf config.litellm.enable {
  systemd.tmpfiles.rules = gw.tmpfilesRules;

  system.activationScripts.litellm = gw.activationScript;
}
