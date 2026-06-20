# modules/ai/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ollama.nix
  ];
}