# modules/ai/llama-cpp.nix
# llama.cpp server — enable + config only (definition upstream).

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
in
{
  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    modelsDir = defaults.ai.models;
  };
}
