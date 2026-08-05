# modules/ai/bitrouter/settings.nix
# BitRouter service options — single source of truth for both run modes.
#
# services.bitrouter.mode chooses how the SAME package + config are run:
#   "native"    — systemd service running the binary directly (service.nix)
#   "container" — Podman container wrapping the same binary (container.nix)

{ config, pkgs, lib, ... }:

let
  defaults = import ../../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  cfg = config.services.bitrouter;

  stateDir = "${appdata}/bitrouter";

  # In container mode the daemon must bind 0.0.0.0 so the port-mapped host
  # traffic (which arrives on the container's eth0, not loopback) reaches it.
  # The host-side publish stays pinned to cfg.listenAddress in container.nix.
  effectiveListen = if cfg.mode == "container" then "0.0.0.0" else cfg.listenAddress;

  # Render the user-supplied settings attrset to a bitrouter.yaml store path.
  yamlFormat = pkgs.formats.yaml { };
  renderedConfig = yamlFormat.generate "bitrouter.yaml"
    (cfg.settings // {
      server = cfg.settings.server or { } // {
        listen = "${effectiveListen}:${toString cfg.port}";
        # Credential-less requests are disabled by default — clients must pass
        # a brvk_ virtual key (bitrouter key sign). skip_auth defaults to false
        # in code; the option flips it for trusted single-tenant deployments.
        skip_auth = cfg.skipAuth;
      };
      # Pin the daemon to the persistent state-dir DB. Without this the daemon
      # creates ./bitrouter.db next to the config file (container ephemeral
      # layer), while `bitrouter key sign` writes to the stateDir DB — so
      # virtual keys never match. cwd-relative would resolve to /etc/bitrouter.
      database = cfg.settings.database or { } // {
        url = cfg.databaseUrl;
      };
    });
in

{
  options.services.bitrouter = {
    enable = lib.mkEnableOption "BitRouter LLM gateway";

    mode = lib.mkOption {
      type = lib.types.enum [ "native" "container" ];
      default = "container";
      description = "Run BitRouter as a systemd service (native) or a Podman container.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "BitRouter package (prebuilt release binary).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4356;
      description = "Listen port for the OpenAI/Anthropic-compatible API.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP proxy to.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = stateDir;
      description = "Runtime state: config, control socket, sqlite db.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "${stateDir}/bitrouter.yaml";
      description = "Rendered bitrouter.yaml consumed by both run modes.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Files with KEY=VALUE provider keys (sops), loaded into the process env.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''BitRouter config (bitrouter.yaml) as an attrset. Keys: server, providers, models, presets, variants, policy, registry.'';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open cfg.port in the firewall.";
    };

    skipAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Admit credential-less requests. Disabled by default: clients must present a brvk_ virtual key (Authorization: Bearer).";
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      # Container mode mounts ${stateDir} -> /var/lib/bitrouter, so the daemon
      # inside the container can only reach the DB via its internal path.
      # Native mode runs the binary on the host, so it uses the host path.
      # Both resolve to the same physical file (the mounted volume).
      default = if cfg.mode == "container" then "sqlite:///var/lib/bitrouter/bitrouter.db" else "sqlite://${stateDir}/bitrouter.db";
      description = "Database URL used for virtual keys / policy state. Must match the path `bitrouter key sign` writes to.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # State dir for both modes.
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${user.name} ${user.group} -"
    ];

    # Seed the runtime config.yaml from the rendered settings if absent
    # (preserves manual edits, same pattern as litellm-config).
    system.activationScripts.bitrouter-config = lib.stringAfter [ "users" ] ''
      mkdir -p ${cfg.stateDir}
      if [ ! -f ${cfg.configFile} ]; then
        install -m 0644 ${renderedConfig} ${cfg.configFile}
        chown ${user.name}:${user.group} ${cfg.configFile}
      fi
    '';
  };
}
