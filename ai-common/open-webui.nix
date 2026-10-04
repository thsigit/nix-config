# ai-common/open-webui.nix
# Open WebUI — nixpkgs service + Caddy vhost (8081 -> chat.home.arpa).
# Always-on leaf (no enable toggle) following mrtg-style standard.
# Upstream module: services.open-webui (nixpkgs). Unfree license — predicate
# is handled in system/default.nix + profiles/workstation/default.nix.

{ config, lib, pkgs, ... }:

let
  port = 8081;
in
{
  services.caddy.services.chat = {
    inherit port;
    visibility = { lan = true; tailscale = true; };
  };

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = port;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      # Pre-wire to the local LiteLLM gateway (OpenAI-compatible). Admin adds
      # the LITELLM_MASTER_KEY in the WebUI Settings -> Connections if needed;
      # keeping the key out of the store avoids baking secrets into the closure.
      OPENAI_API_BASE_URL = "http://127.0.0.1:4000/v1";
      WEBUI_NAME = "Homelab";
      WEBUI_URL = "http://127.0.0.1:${toString port}";
      DEFAULT_USER_ROLE = "admin";
      ENABLE_SIGNUP = "True";
      ENABLE_COMMUNITY_SHARING = "False";
      DEFAULT_MODELS = "nvidia/openai/gpt-oss-120b";
      WHISPER_API_BASE_URL = "http://127.0.0.1:8090/v1";
    };
  };

  # Ensure Open WebUI starts after the LiteLLM gateway so the default
  # OPENAI_API_BASE_URL is reachable on first boot.
  systemd.services.open-webui.after = [ "litellm.service" "network.target" ];
}
