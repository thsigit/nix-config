# Stats for ai.home.arpa dashboard — sqlite + usage.jsonl ingester
# Provides /srv/appdata/litellm/admin.db and static /srv/www/ai/ui/playground/stats.json
# No Caddy proxy needed (whitelisted via @frontend path /ui/playground/*)
{ config, pkgs, ... }:
let
  db = "/srv/appdata/litellm/admin.db";
  out = "/srv/www/ai/ui/playground/stats.json";
  jsonl = "/srv/appdata/litellm/usage.jsonl";
in
{
  systemd.services.litellm-stats-writer = {
    description = "LiteLLM stats writer (usage.jsonl -> sqlite -> stats.json)";
    after = [ "litellm.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 /srv/appdata/litellm/stats_writer.py";
      Restart = "always";
      RestartSec = 5;
      User = "sigit";
      Group = "users";
    };
  };
  systemd.services.litellm-stats-api = {
    description = "LiteLLM stats API (127.0.0.1:8089 /api/stats)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 /srv/appdata/litellm/stats_api.py";
      Restart = "always";
      RestartSec = 5;
      User = "sigit";
      Group = "users";
    };
  };
}
