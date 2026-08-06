# modules/media/karakeep.nix
{ config, ... }:
let defaults = import ../../settings; in
{
  services.caddy.services.karakeep = { port = 8086; };
  services.karakeep = {
    enable = true;
    extraEnvironment = { HOST = "0.0.0.0"; PORT = "8086"; DISABLE_SIGNUPS = "false"; };
  };
}
