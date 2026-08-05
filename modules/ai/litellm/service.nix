# modules/ai/litellm/service.nix
# LiteLLM systemd service + Caddy integration
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, pkgs, ... }:

let
  gw = config.litellm.gateway;
in lib.mkIf config.litellm.enable {
  services.caddy.services.litellm.port = 4000;

  services.litellm = {
    enable = true;
    package = pkgs.litellm;
    host = "127.0.0.1";
    port = 4000;

    openFirewall = false;

    environmentFile = config.sops.secrets."litellm.env".path;

    environment = {
      LITELLM_DISABLE_CHAT_CACHE = "true";
    };
  };

  systemd.services.litellm.serviceConfig.ReadWritePaths = [
    config.litellm.state.dataDir
  ];

  # mkForce: nixpkgs services.litellm has no --config support; we need it for controller-rendered config.yaml.
  systemd.services.litellm.serviceConfig.ExecStart = lib.mkForce
    "${lib.getExe config.services.litellm.package} --host \"${config.services.litellm.host}\" --port ${toString config.services.litellm.port} --config ${config.litellm.state.configYaml}";

  systemd.services.litellm.serviceConfig.ExecStartPre = lib.mkAfter [
    "+${gw.renderScript}/bin/litellm-render"
  ];
}
