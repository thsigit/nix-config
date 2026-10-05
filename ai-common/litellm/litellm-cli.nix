# ai-common/litellm/litellm-cli.nix
#
# Local wiring for the independent `services.litellm-cli` module (imported
# from the litellm-cli repo). Self-enabling leaf: importing this file enables
# the admin CLI + config editor layer.
#
# Static config contract:
#   The LiteLLM config.yaml is a STATIC, hand-maintained file living at
#   ai-common/litellm/config.yaml and copied to ${config.services.litellm-cli.configFile}
#   at activation by the native runtime module (./litellm.nix). litellm-cli
#   only EDITS that static file manually; it never renders or seeds anything.
#
# Persistence contract:
#   dataDir (persistent) → usage_logger.py (callback module), survives reinstall
#   /run/litellm-cli     → health.json (ephemeral, rebuilt each boot)
{ config, lib, litellmCli, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
in
{
  imports = [ (litellmCli + "/module.nix") ];

  services.litellm-cli = {
    enable = true;
    # runs as the regular user so `litellm-cli` works without sudo
    dataDir = "${appdata}/litellm";
    user = defaults.user.name;
    group = defaults.user.group;
    providersEnvFile = config.sops.secrets."providers.env".path;

    # No scheduled provider health check. The upstream module defaults
    # doctor.enable to true, which installs an hourly systemd timer
    # (Persistent=true, so it also fires after downtime). That contradicts
    # this tool's own documented contract -- litellm-cli's header states it
    # "is never invoked by a rebuild, systemd unit, or activation script".
    # It also sat permanently in `systemctl --failed`: from 2026-09-02 to
    # 2026-10-05 it ran 849 times with 595 failures and 0 successes, because
    # doctor.sh called `yq -o=json` against kislyuk's yq and died under
    # `set -euo pipefail` before checking anything. The underlying yq bug is
    # fixed upstream in litellm-cli 682415d, so `litellm-cli debug doctor`
    # works when run by hand; we simply do not want it on a timer.
    doctor.enable = false;
  };
}
