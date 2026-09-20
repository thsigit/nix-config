# Admin API for ai.home.arpa dashboard — editable config + provider toggle
# Auth via LITELLM_MASTER_KEY (Bearer), sqlite not needed for session (stateless)
{ config, pkgs, ... }:
{
  systemd.services.litellm-admin-api = {
    description = "LiteLLM admin API (127.0.0.1:8091 /api/config)";
    after = [ "network.target" "litellm.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${config.services.litellm-cli.package}/data/admin_api.py";
      Restart = "always";
      RestartSec = 5;
      User = "sigit";
      Group = "users";
    };
  };
}
