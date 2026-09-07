# common/ai/whisper.nix
# whisper.cpp server — STT via whisper-server (8082 -> whisper.home.arpa).
# Always-on leaf, similar to llama-cpp/open-webui.
# Model: ggml-base (~142MB) in /srv/ai/models/whisper, auto-downloaded on activation.
# Check logs: journalctl -u whisper.service

{ config, lib, pkgs, ... }:
let
  defaults = import ../../settings;
  port = 8090;
  modelDir = "${defaults.ai.models}/whisper";
  modelFile = "${modelDir}/ggml-base.bin";
in
{
  services.caddy.services.whisper = {
    inherit port;
    visibility = { lan = true; tailscale = true; };
  };

  systemd.services.whisper = {
    description = "whisper.cpp server (STT)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.whisper-cpp}/bin/whisper-server --host 127.0.0.1 --port ${toString port} --model ${modelFile} --convert --inference-path /inference --request-path /";
      Restart = "on-failure";
      RestartSec = "5s";
      DynamicUser = false;
      User = defaults.user.name;
      Group = defaults.user.group;
    };

    # Ensure ffmpeg is available for --convert (mp3/ogg -> wav)
    path = [ pkgs.ffmpeg ];
  };

  # Auto-fetch ggml-base if missing (first boot). Uses upstream download script -> HuggingFace.
  system.activationScripts.whisper-model = lib.stringAfter [ "users" ] ''
    set -euo pipefail
    mkdir -p ${modelDir}
    chown ${defaults.user.name}:${defaults.user.group} ${modelDir}
    if [ ! -f ${modelFile} ]; then
      echo "[whisper] downloading ggml-base to ${modelFile} ..."
      ${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model base ${modelDir}
      chown ${defaults.user.name}:${defaults.user.group} ${modelFile}
      chmod 0644 ${modelFile}
    fi
  '';

  environment.systemPackages = [ pkgs.whisper-cpp pkgs.ffmpeg ];

  systemd.tmpfiles.rules = [
    "d ${modelDir} 0755 ${defaults.user.name} ${defaults.user.group} -"
  ];
}
