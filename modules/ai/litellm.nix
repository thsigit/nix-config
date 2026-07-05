# modules/ai/litellm.nix
{ config, pkgs, lib, ... }:

{
  services.litellm = {
    enable = true;

    host = "127.0.0.1";
    port = 4000;

    # Example:
    # OPENAI_API_KEY=...
    # OPENROUTER_API_KEY=...
    # ANTHROPIC_API_KEY=...
    environmentFile = "/run/secrets/litellm.env";

    settings = {
      model_list = [
        {
          model_name = "local-qwen";

          litellm_params = {
            model = "openai/local-qwen";
            api_base = "http://127.0.0.1:8080/v1";
            api_key = "dummy";
          };
        }

        {
          model_name = "openrouter-free";

          litellm_params = {
            model = "openrouter/openai/gpt-oss-20b:free";
            api_key = "os.environ/OPENROUTER_API_KEY";
          };
        }

        {
          model_name = "claude-sonnet";

          litellm_params = {
            model = "anthropic/claude-sonnet-4";
            api_key = "os.environ/ANTHROPIC_API_KEY";
          };
        }

        {
          model_name = "gpt-4o-mini";

          litellm_params = {
            model = "openai/gpt-4o-mini";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }
      ];

      router_settings = {
        num_retries = 2;
        timeout = 60;

        fallbacks = [
          {
            local-qwen = [
              "openrouter-free"
              "claude-sonnet"
              "gpt-4o-mini"
            ];
          }
        ];
      };

      general_settings = {
        master_key = "change-me";
      };
    };
  };

  systemd.services.litellm.serviceConfig = {
    Restart = "always";
    RestartSec = 5;
  };
}