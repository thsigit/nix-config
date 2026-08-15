# common/ai/litellm-podman-helper.nix
#
# Restart the LiteLLM Podman container whenever the rendered
# LiteLLM configuration changes.
#
{ config, pkgs, ... }:

let
  configFile = config.services.litellm-cli.configFile;
in
{
  systemd.paths."podman-litellm-config" = {
    description = "Restart LiteLLM Podman container on config change";

    wantedBy = [ "paths.target" ];

    pathConfig = {
      PathChanged = [ configFile ];
      Unit = "podman-litellm-config.service";
    };
  };

  systemd.services."podman-litellm-config" = {
    description = "Restart LiteLLM Podman container on config change";

    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        "${pkgs.systemd}/bin/systemctl try-restart podman-litellm.service";
    };
  };
}
