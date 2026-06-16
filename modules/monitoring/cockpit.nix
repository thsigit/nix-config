# modules/monitoring/cockpit.nix 

{ config, lib, pkgs, ... }:

{
  environment.etc = {
    "cockpit/ws-certs.d/50-homelab.cert".source =
      "/etc/ssl/homelab/homelab.crt";
  
    "cockpit/ws-certs.d/50-homelab.key".source =
      "/etc/ssl/homelab/homelab.key";
  };

  # Cockpit Web GUI
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        ClientCertAuthentication = false;
        AllowUnencrypted = false;
        Origins = lib.mkForce "https://homelab.home.arpa:9090";
      };
    };
  };
}