{ config, lib, pkgs, ... }:

let
  serviceOpts = { name, ... }: {
    options = {
      port = lib.mkOption {
        type = lib.types.port;
        description = "Backend port to reverse-proxy to";
      };

      visibility = {
        lan = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Expose via {name}.home.arpa";
        };

        tailscale = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Expose via {name}.{tailnet}.ts.net";
        };
      };

      extraConfig = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = "Extra Caddy directives for the reverse_proxy block";
      };
    };
  };
in
{
  options.services.caddy.services = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serviceOpts);
    default = { };
    description = "Declarative service definitions for Caddy reverse proxy";
  };
}
