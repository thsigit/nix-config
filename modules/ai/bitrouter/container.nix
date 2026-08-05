# modules/ai/bitrouter/container.nix
# Container run mode — wraps the SAME bitrouter package into a Podman image.
#
# Active only when services.bitrouter.mode == "container".
# The image is built from cfg.package via dockerTools, so binary + config
# are identical to native mode.

{ config, pkgs, lib, ... }:

let
  cfg = config.services.bitrouter;

  bitrouterImage = pkgs.dockerTools.buildImage {
    name = "bitrouter";
    tag = cfg.package.version or "v1.0.0-alpha.27";
    copyToRoot = pkgs.buildEnv {
      name = "bitrouter-root";
      paths = [ cfg.package pkgs.cacert ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Entrypoint = [ "/bin/bitrouter" "serve" "-c" "/etc/bitrouter/bitrouter.yaml" ];
      WorkingDir = "/var/lib/bitrouter";
      Env = [
        "HOME=/var/lib/bitrouter"
        "XDG_DATA_HOME=/var/lib/bitrouter/.local/share"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      ExposedPorts = { "${toString cfg.port}/tcp" = { }; };
    };
  };
in

{
  config = lib.mkIf (cfg.enable && cfg.mode == "container") {
    virtualisation.oci-containers.containers.bitrouter = {
      image = "bitrouter:${cfg.package.version or "v1.0.0-alpha.27"}";
      imageFile = bitrouterImage;
      ports = [ "${cfg.listenAddress}:${toString cfg.port}:4356" ];
      volumes = [
        "${cfg.configFile}:/etc/bitrouter/bitrouter.yaml:ro"
        "${cfg.stateDir}:/var/lib/bitrouter"
      ];
      environmentFiles = cfg.environmentFiles;
      autoStart = true;
    };

    # Reverse proxy: bitrouter.home.arpa -> 127.0.0.1:<port>
    services.caddy.services.bitrouter = {
      port = cfg.port;
    };
  };
}
