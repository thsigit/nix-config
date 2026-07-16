{ config, lib, pkgs, ... }:

let
  jsonData = builtins.fromJSON (builtins.readFile ./models-dev.json);
  freeProviders = import ./free-providers.nix;
  nonfreeProviders = import ./nonfree-models.nix;
  manualModels = import ./manual-models.nix;

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
    else map (modelId:
      mkEntry providerKey prefix envVar modelId apiBase
    ) (builtins.attrNames provider.models)
  ) providers;

  freeModelList = lib.flatten (genModels freeProviders);

  nonfreeModelList = lib.flatten (lib.mapAttrsToList (providerKey: cfg:
    let
      provider = jsonData.${providerKey} or null;
      apiBase = cfg.api or (provider.api or null);
      prefix = cfg.prefix or null;
    in
    if apiBase == null then [ ]
    else map (modelId:
      mkEntry providerKey prefix cfg.env modelId apiBase
    ) cfg.models
  ) nonfreeProviders);

  modelList = freeModelList ++ nonfreeModelList ++ manualModels;

  configuredKeys = builtins.attrNames freeProviders
    ++ builtins.attrNames nonfreeProviders;

  missingProviders = lib.filterAttrs (name: value:
    ! (builtins.elem name configuredKeys)
  ) (builtins.mapAttrs (name: value:
    builtins.length (builtins.attrNames value.models)
  ) jsonData);
in
{
  services.litellm.settings.model_list = modelList;

  warnings = lib.optional (missingProviders != { })
    ("litellm: providers with free models but no configured API key: "
    + lib.concatStringsSep ", " (builtins.attrNames missingProviders));

  environment.etc."litellm/missing-providers.json" = {
    text = builtins.toJSON (builtins.mapAttrs (name: count:
      { free_models = count; }
    ) missingProviders);
  };

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
