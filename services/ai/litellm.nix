# services/ai/litellm.nix
# LiteLLM gateway (Podman) — consolidated service config.

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user ai;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/litellm";
  configFile = "${appdataDir}/config.yaml";

  controller = pkgs.callPackage ../../pkgs/litellm-cli { };
  gw = controller.mkGateway {
    stateDir = appdataDir;
    configYamlPath = configFile;
    providersEnvFile = config.sops.secrets."providers.env".path;
    user = user.name;
    group = user.group;
  };
in

{
  options.ai.podmanLitellm.enable = lib.mkEnableOption "LiteLLM gateway (Podman)";
  options.ai.litellmConfig.enable = lib.mkEnableOption "LiteLLM config layer";

  config = lib.mkMerge [
    (lib.mkIf (config.ai.podmanLitellm.enable or false) {
      services.caddy.services.litellm = { port = 4000; };

      virtualisation.oci-containers.containers.litellm = {
        image = "ghcr.io/berriai/litellm:v1.92.0";
        extraOptions = [
          "--network" "host"
          "--cap-drop=ALL"
          "--security-opt=no-new-privileges"
          "--health-cmd=python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:4000/health/liveliness', timeout=5)\""
          "--health-interval=30s"
          "--health-retries=3"
          "--health-start-period=15s"
        ];
        podman = { sdnotify = "healthy"; };
        volumes = [
          "${configFile}:/app/config.yaml:ro"
          "${appdataDir}/data:/app/data"
          "${appdataDir}/logs:/app/logs"
        ];
        cmd = [ "--config" "/app/config.yaml" "--host" "127.0.0.1" "--port" "4000" ];
        environment = { LITELLM_DISABLE_CHAT_CACHE = "true"; };
        environmentFiles = [ config.sops.secrets."litellm.env".path ];
        autoStart = true;
      };

      systemd.services."podman-litellm".serviceConfig.RemainAfterExit = true;

      systemd.tmpfiles.rules = [
        "d ${ai.root} 0755 ${user.name} ${user.group} -"
        "d ${appdataDir} 0755 ${user.name} ${user.group} -"
        "d ${appdataDir}/data 0755 ${user.name} ${user.group} -"
        "d ${appdataDir}/logs 0755 ${user.name} ${user.group} -"
      ];

      system.activationScripts.podman-litellm-config = lib.stringAfter [ "users" ] ''
        set -euo pipefail
        if [ ! -f ${configFile} ]; then
          mkdir -p ${appdataDir}
          cat > ${configFile} <<YAML
model_list: []
litellm_settings:
  drop_params: true
  json_logs: true
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
YAML
          chown ${user.name}:${user.group} ${configFile}
        fi
      '';
    })

    (lib.mkIf (config.ai.litellmConfig.enable or false) {
      environment.systemPackages = gw.systemPackages;

      systemd.tmpfiles.rules = [
        "d ${appdataDir} 0755 ${user.name} ${user.group} -"
      ];

      system.activationScripts.litellm-config = lib.stringAfter [ "users" ] ''
        set -euo pipefail
        PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH"
        ${gw.activationScript}
        LITELLM_STATE_DIR=${appdataDir} \
          LITELLM_PROVIDERS_JSON=${appdataDir}/providers.json \
          LITELLM_MODELS_JSON=${appdataDir}/models.json \
          LITELLM_ROUTER_YAML=${appdataDir}/router.yaml \
          LITELLM_CONFIG_YAML=${configFile} \
          PATH="${lib.makeBinPath [ pkgs.jq pkgs.yq ]}:$PATH" \
          ${gw.renderScript}/bin/litellm-render
      '';

      systemd.services.litellm-doctor = {
        description = "LiteLLM provider health check";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${gw.doctorScript}/bin/litellm-doctor";
          EnvironmentFile = config.sops.secrets."providers.env".path;
        };
      };

      systemd.timers.litellm-doctor = {
        description = "Hourly LiteLLM provider health check";
        wantedBy = [ "timers.target" ];
        timerConfig = { OnCalendar = "hourly"; Persistent = true; RandomizedDelaySec = "5m"; };
      };
    })
  ];
}
