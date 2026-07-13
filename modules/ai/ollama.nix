# modules/ai/ollama.nix

{ config, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    ai;
in

{
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    models = ai.models;
    # openFirewall = true;
    package = pkgs.ollama-cpu;
	environmentVariables = {
      OLLAMA_NUM_THREADS = "4";
    };
  };
}
