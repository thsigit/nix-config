# programs/openssl.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openssl mkcert sops
  ];
}
