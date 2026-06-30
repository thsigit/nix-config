# modules/ai/ollama.nix
{ config, pkgs, lib, ... }:

{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    models = "/srv/ai/models";
    openFirewall = true;
    package = pkgs.ollama-cpu;
	environmentVariables = {
      OLLAMA_NUM_THREADS = "4";
    };
  };
}
