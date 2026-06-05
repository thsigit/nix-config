# modules/monitoring/cockpit.nix 

{ config, lib, pkgs, ... }:

{
  # Cockpit Web GUI
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        ClientCertAuthentication = true;
        AllowUnencrypted = false;
        Origins = lib.mkForce "https://home.arpa:9090";
      };
    };
  };
}