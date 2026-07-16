{ config, lib, pkgs, ... }:

let
  script = pkgs.writeShellScriptBin "fetch-models" ''
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.git ]}:$PATH"
    ${builtins.readFile ./fetch-models.sh}
  '';
in
{
  systemd.services.fetch-models = {
    description = "Fetch free LLM model snapshot from models.dev";
    script = "${script}/bin/fetch-models";
    serviceConfig = {
      Type = "oneshot";
      User = "sigit";
      WorkingDirectory = /srv/repo/nix-lab;
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
