# modules/ai/litellm/maintenance.nix
# Health check timer and model fetch timer
#
# Gated by config.litellm.enable (default false) — runtime moved to podman-litellm.

{ config, lib, pkgs, ... }:

let
  gw = config.litellm.gateway;
  defaults = import ../../../settings;
in lib.mkIf config.litellm.enable {
  systemd.services.litellm-doctor = {
    description = "LiteLLM provider health check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${gw.doctorScript}/bin/litellm-doctor";
    };
  };

  systemd.timers.litellm-doctor = {
    description = "Periodic provider health check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.services.fetch-models = {
    description = "Fetch free LLM model snapshot from models.dev";
    script = "${gw.fetchScript}/bin/fetch-models";
    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = defaults.ai.repo;
    };
  };

  systemd.timers.fetch-models = {
    description = "Daily fetch of free LLM model snapshot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
