{ pkgs, ... }:

{
  sops = {

    age.keyFile = "/home/sigit/.config/sops/age/keys.txt";

    secrets.ai_providers = {
      sopsFile = ../../secrets/ai-providers.yaml;
      format = "yaml";
    };

  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}