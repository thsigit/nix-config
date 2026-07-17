# modules/ai/litellm/models.nix
# Generates model data and writes to runtime directory for renderer

{ config, lib, pkgs, ... }:

let
  state = config.litellm.state;
  jsonData = builtins.fromJSON (builtins.readFile ./models-dev.json);
  openProviders = import ./providers-open.nix;
  restrictedProviders = import ./providers-restricted.nix;

  mkEntry = providerKey: prefix: envVar: modelId: apiBase: {
    model_name = "${providerKey}/${modelId}";
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

  systemd.tmpfiles.rules = [
    "d ${state.dataDir} 0755 sigit users -"
    "d /etc/litellm 0755 root root -"
  ];

  # Activation scripts ensure files are synced on every rebuild
  system.activationScripts.litellm-state = lib.mkAfter ''
    # Copy models.json (always updated)
    cp ${modelsJson} ${state.modelsJson}
    chown sigit:users ${state.modelsJson}

    # Create providers-enabled.json only if missing (preserves manual changes)
    if [ ! -f ${state.providersEnabledJson} ]; then
      echo '{"aihubmix":true,"cohere":true,"nvidia":true,"openrouter":true,"kenari":true,"zai":true,"fireworks-ai":true}' > ${state.providersEnabledJson}
      chown sigit:users ${state.providersEnabledJson}
      echo "Created default providers-enabled.json"
    fi

    # Copy missing providers data
    cp ${missingJson} /etc/litellm/missing-providers.json
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
