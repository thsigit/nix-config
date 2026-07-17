# modules/ai/litellm/models.nix
# Generates model data and writes to /srv/appdata/litellm/ for runtime use

{ config, lib, pkgs, ... }:

let
  dataDir = "/srv/appdata/litellm";
  jsonData = builtins.fromJSON (builtins.readFile ./models-dev.json);
  openProviders = import ./providers-open.nix;
  restrictedProviders = import ./providers-restricted.nix;

  mkEntry = providerKey: prefix: envVar: modelId: apiBase: {
    model_name = modelId;
    litellm_params = {
      model = if prefix == null then modelId else "${prefix}/${modelId}";
      api_base = apiBase;
      api_key = "os.environ/${envVar}";
    };
  };

  genModels = providers: lib.mapAttrsToList (providerKey: cfg:
    let
      provider = jsonData.${providerKey} or null;
      apiBase = cfg.api or (provider.api or null);
      envVar = cfg.env or cfg;
      prefix = cfg.prefix or null;
    in
    if apiBase == null then [ ]
    else if provider == null then [ ]
    else
    let modelIds = cfg.models or (builtins.attrNames provider.models);
    in map (modelId:
      mkEntry providerKey prefix envVar modelId apiBase
    ) modelIds
  ) providers;

  openModelList = lib.flatten (genModels openProviders);
  restrictedModelList = lib.flatten (genModels restrictedProviders);

  # Manual models (not from models.dev)
  manualModels = import ./providers-manual.nix;

  # Full model list for all providers
  allModels = openModelList ++ restrictedModelList ++ manualModels;

  allConfiguredKeys = builtins.attrNames openProviders
    ++ builtins.attrNames restrictedProviders;

  missingProviders = lib.filterAttrs (name: value:
    ! (builtins.elem name allConfiguredKeys)
  ) (builtins.mapAttrs (name: value:
    builtins.length (builtins.attrNames value.models)
  ) jsonData);

  # All known providers (for the "all enabled" default)
  allKnownProviders = builtins.attrNames openProviders
    ++ builtins.attrNames restrictedProviders;

  defaultEnabled = lib.genAttrs allKnownProviders (_: true);

  modelsJson = pkgs.writeText "models.json" (builtins.toJSON allModels);
  missingJson = pkgs.writeText "missing-providers.json"
    (builtins.toJSON (builtins.mapAttrs (name: count:
      { free_models = count; }
    ) missingProviders));

in
{
  warnings = lib.optional (missingProviders != { })
    ("litellm: providers with free models but no configured API key: "
    + lib.concatStringsSep ", " (builtins.attrNames missingProviders));

  # Write models.json to /srv/appdata/litellm/
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 sigit users -"
    "C+ ${dataDir}/models.json 0644 sigit users - ${modelsJson}"
    "e+ ${dataDir}/providers-enabled.json 0644 sigit users - - -"  # create if missing
    "d /etc/litellm 0755 root root -"
    "C /etc/litellm/missing-providers.json 0644 root root - ${missingJson}"
  ];

  # Write default providers-enabled.json (only if missing)
  # The 'e+' in tmpfiles means: create if doesn't exist, don't overwrite
  # We need a separate activation script for the JSON default
  system.activationScripts.litellm-providers-enabled = lib.mkAfter ''
    if [ ! -f ${dataDir}/providers-enabled.json ]; then
      echo '{"aihubmix":true,"cohere":true,"nvidia":true,"openrouter":true,"kenari":true,"zai":true,"fireworks-ai":true}' > ${dataDir}/providers-enabled.json
      chown sigit:users ${dataDir}/providers-enabled.json
      echo "Created default providers-enabled.json"
    fi
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "litellm-missing" ''
      if [ -f /etc/litellm/missing-providers.json ]; then
        ${pkgs.jq}/bin/jq -r '
          to_entries[] | "\(.key): \(.value.free_models) free models"
        ' /etc/litellm/missing-providers.json
      else
        echo "No missing providers data found."
      fi
    '')
  ];
}
