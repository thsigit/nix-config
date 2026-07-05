# modules/ai/localai.nix
{ config, pkgs, lib, ... }:

let
  # Ganti dengan path absolut yang diinginkan
  modelsPath = "/home/youruser/localai/models";
  dataPath = "/home/youruser/localai/data";
in
{

  # Definisi container
  virtualisation.oci-containers.containers.localai = {
    image = "localai/localai:latest";
    ports = [ "8080:8080" ];
    volumes = [
      "${modelsPath}:/models"
      "${defaults.appdataDir}/localai/models:/models"
      "${defaults.appdataDir}/localai/data:/data"
      "${defaults.appdataDir}/localai/backends:/backends"
      "${defaults.appdataDir}/localai/configuration:/configuration"
    ];
    autoStart = true;
    extraOptions = [
      "--interactive"  # -i flag
      "--tty"          # -t flag
    ];
  };
  systemd.tmpfiles.rules = [
    "d ${defaults.appdataDir}/localai 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/models 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/data 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/backends 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.appdataDir}/localai/configuration 0755 ${defaults.user} ${defaults.group} -"
  ];
}