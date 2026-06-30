# modules/ai/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ollama.nix
	./hermes.nix
	./podman-newapi.nix
  ];
}