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

    providersJson = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/providers.json";
      description = "Provider policy + connection (runtime config, admin-owned)";
    };

    modelsJson = lib.mkOption {
      type = lib.types.path;
      default = "/srv/appdata/litellm/models.json";
      description = "Canonical model inventory (runtime mirror of the committed snapshot)";
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
