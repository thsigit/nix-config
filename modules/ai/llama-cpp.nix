# modules/ai/llama-cpp-config.nix
#
# Enable and configure llama.cpp server.
# Values parameterized via settings/default.nix.

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
in
{
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp;
    host = "127.0.0.1";
    port = 8080;
    modelsDir = defaults.ai.models;
    modelsPreset = null;
    extraFlags = [];
    openFirewall = false;
  };
}
