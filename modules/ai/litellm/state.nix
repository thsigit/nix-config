# modules/ai/litellm/state.nix
# Single source of truth for all runtime file paths

{ lib, ... }:

{
  options.litellm.state = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm";
      description = "Base directory for litellm runtime state";
    };

    modelsJson = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/models.json";
      description = "Full model inventory (generated at build time)";
    };

    providersEnabledJson = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/providers-enabled.json";
      description = "Which providers are enabled (runtime config)";
    };

    configYaml = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/config.yaml";
      description = "Generated LiteLLM config (written by renderer)";
    };

    healthJson = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/health.json";
      description = "Provider health state (written by doctor)";
    };
  };
}
