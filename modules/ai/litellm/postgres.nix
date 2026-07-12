# modules/ai/litellm/postgres.nix

{ config, lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;

    ensureDatabases = [ "litellm" ];

    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];
  };
}