# modules/ai/litellm/secrets.nix
{ ... }:

{
  sops.secrets."litellm.env" = {
    sopsFile = ../../secrets/litellm.env;
    format = "dotenv";
  };
}