# modules/ai/litellm.nix
# LiteLLM AI gateway — systemd-native runtime (upstream services.litellm).
# State/configurable settings live under ${appdata}/litellm (no /var/lib).
# Container variant: ./litellm-container.nix (disabled reference).

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata;

  stateDir = "${appdata}/litellm";
in
{
  services.caddy.services.litellm = { port = 4000; };

  services.litellm = {
    enable = true;
    stateDir = stateDir;
    host = "127.0.0.1";
    port = 4000;
    openFirewall = false;

    environmentFile = config.sops.secrets."litellm.env".path;

    environment = {
      LITELLM_DISABLE_CHAT_CACHE = "true";
    };

    settings = {
      general_settings = {
        master_key = "os.environ/LITELLM_MASTER_KEY";
      };

      litellm_settings = {
        json_logs = true;
        drop_params = true;
      };

      # router_settings = { };
      # model_list = [ ];
    };
  };

  # Run as the declared user (not the upstream DynamicUser) so the state dirs
  # under ${appdata} are writable; drop the upstream /var/lib StateDirectory.
  systemd.services.litellm.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce user.name;
    StateDirectory = lib.mkForce [ ];
  };

  # Appended after the upstream ui/tiktoken-cache rules for the same paths,
  # so these ownership/mode settings win.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 ${user.name} ${user.group} -"
    "d ${stateDir}/ui 0700 ${user.name} ${user.group} -"
    "d ${stateDir}/tiktoken-cache 0700 ${user.name} ${user.group} -"
  ];
}
