# modules/ai/bitrouter.nix
# BitRouter LLM gateway — consolidated service config.

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  cfg = config.services.bitrouter;
  stateDir = "${appdata}/bitrouter";

  effectiveListen = if cfg.mode == "container" then "0.0.0.0" else cfg.listenAddress;

  yamlFormat = pkgs.formats.yaml { };
  renderedConfig = yamlFormat.generate "bitrouter.yaml"
    (cfg.settings // {
      server = cfg.settings.server or { } // {
        listen = "${effectiveListen}:${toString cfg.port}";
        skip_auth = cfg.skipAuth;
      };
      database = cfg.settings.database or { } // {
        url = cfg.databaseUrl;
      };
    });

  bitrouterPackage = pkgs.callPackage ../../pkgs/bitrouter { };
in

{
  options.services.bitrouter = {
    enable = lib.mkEnableOption "BitRouter LLM gateway";

    mode = lib.mkOption {
      type = lib.types.enum [ "native" "container" ];
      default = "container";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = bitrouterPackage;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4356;
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = stateDir;
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "${stateDir}/bitrouter.yaml";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    skipAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      default = if cfg.mode == "container" then "sqlite:///var/lib/bitrouter/bitrouter.db" else "sqlite://${stateDir}/bitrouter.db";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${user.name} ${user.group} -"
    ];

    system.activationScripts.bitrouter-config = lib.stringAfter [ "users" ] ''
      mkdir -p ${cfg.stateDir}
      if [ ! -f ${cfg.configFile} ]; then
        install -m 0644 ${renderedConfig} ${cfg.configFile}
        chown ${user.name}:${user.group} ${cfg.configFile}
      fi
    '';

    systemd.services.bitrouter = lib.mkIf (cfg.mode == "native") {
      description = "BitRouter LLM gateway (native)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environmentFiles = cfg.environmentFiles;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/bitrouter serve -c ${cfg.configFile}";
        WorkingDirectory = cfg.stateDir;
        Restart = "on-failure";
        RestartSec = "3";
      };
    };

    virtualisation.oci-containers.containers.bitrouter = lib.mkIf (cfg.mode == "container") {
      image = "bitrouter:${cfg.package.version or "v1.0.0-alpha.27"}";
      imageFile = pkgs.dockerTools.buildImage {
        name = "bitrouter";
        tag = cfg.package.version or "v1.0.0-alpha.27";
        copyToRoot = pkgs.buildEnv {
          name = "bitrouter-root";
          paths = [ cfg.package pkgs.cacert ];
          pathsToLink = [ "/bin" "/etc/ssl/certs" ];
        };
        config = {
          Entrypoint = [ "/bin/bitrouter" "serve" "-c" "/etc/bitrouter/bitrouter.yaml" ];
          WorkingDir = "/var/lib/bitrouter";
          Env = [ "HOME=/var/lib/bitrouter" ];
          ExposedPorts = { "${toString cfg.port}/tcp" = { }; };
        };
      };
      ports = [ "${cfg.listenAddress}:${toString cfg.port}:4356" ];
      volumes = [
        "${cfg.configFile}:/etc/bitrouter/bitrouter.yaml:ro"
        "${cfg.stateDir}:/var/lib/bitrouter"
      ];
      environmentFiles = cfg.environmentFiles;
      autoStart = true;
    };

    services.caddy.services.bitrouter = { port = cfg.port; };
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
