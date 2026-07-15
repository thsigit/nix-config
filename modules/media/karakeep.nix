{ config, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user;
in

{
  services.karakeep = {
    enable = true;
    extraEnvironment = {
      HOST = "0.0.0.0";
      PORT = "8086";
      DISABLE_SIGNUPS = "false";
    };
  };

  services.nginx.virtualHosts."karakeep.home.arpa" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8086";
      proxyWebsockets = true;
    };
  };
}
