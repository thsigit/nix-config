# common/ai/litellm-podman-helper.nix
# LiteLLM Podman restart helper (mrtg-style: always-on when imported).
#
# Watches the podman module's config.yaml and restarts the `podman-litellm`
# container whenever it changes, so a re-render of the gateway inventory/
# policy takes effect without a full system switch.
{ config, pkgs, lib, ... }:

let
  configFile = config.services.litellm-cli.configFile;
in
{
  config = {
    systemd.paths."podman-litellm-config" = {
      description = "Restart podman-litellm on rendered config change";
      wantedBy = [ "paths.target" ];
      pathConfig = {
        PathChanged = [ configFile ];
        Unit = "podman-litellm-config.service";
      };
    };
    systemd.services."podman-litellm-config" = {
      description = "Restart podman-litellm when config.yaml changes";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl try-restart podman-litellm.service";
      };
    };
  };
}
