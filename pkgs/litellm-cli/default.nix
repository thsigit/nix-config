# litellm-cli — AI gateway CLI tools package
#
# Exposes mkGateway: a single function that produces everything
# the NixOS module needs to wire up the AI gateway.
{ lib, stdenv, jq, coreutils, curl, git, pkgs }:

let
  healthLib = import ./lib/health.nix { inherit lib pkgs; };

  controller = stdenv.mkDerivation {
    name = "litellm-cli";
    src = ./.;
    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/lib $out/bin $out/data $out/scripts

      install -m644 $src/lib/*.nix $out/lib/
      install -m644 $src/data/* $out/data/
      install -m755 $src/scripts/* $out/scripts/

      for script in $src/bin/*; do
        name=$(basename "$script")
        substitute "$script" "$out/bin/$name" \
          --replace '@jq@' '${jq}' \
          --replace '@yq@' '${pkgs.yq}' \
          --replace '@coreutils@' '${coreutils}' \
          --replace '@curl@' '${curl}' \
          --replace '@git@' '${git}'
        chmod +x "$out/bin/$name"
      done
    '';

    meta = with lib; {
      description = "AI gateway CLI tools";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # Committed seed: the initial provider policy. Copied to the runtime
  # providers.json only if that file does not already exist (manual init).
  providersSeedJson = pkgs.writeText "providers-seed.json"
    (builtins.readFile ./data/providers-seed.json);

  # Committed inventory snapshot (models.dev + declared). The renderer reads the
  # runtime mirror; this is the build-time source copied into the Nix store.
  modelsJson = pkgs.writeText "models.json"
    (builtins.readFile ./data/models-dev.json);

  # Committed router configuration: capabilities + logical model definitions.
  # Copied to the runtime router.yaml only if absent (manual edits preserved).
  routerSeedPath = "${controller}/data/router-seed.yaml";

  mkGateway = {
    stateDir ? "/srv/appdata/litellm",
    modelsJsonPath ? "${controller}/data/models-dev.json",
    modelsRuntimePath ? "${stateDir}/models.json",
    providersSeedPath ? "${controller}/data/providers-seed.json",
    providersRuntimePath ? "${stateDir}/providers.json",
    routerRuntimePath ? "${stateDir}/router.yaml",
    configYamlPath ? "${stateDir}/config.yaml",
    healthJsonPath ? "${stateDir}/health.json",
    providersEnvFile ? null,
    # Owner for runtime state files. Injected by the NixOS module from the
    # machine's declared user — never hardcode a home user here.
    user ? "root",
    group ? "root",
  }:

  let
    bareDoctor = healthLib.mkDoctorScript {
      inherit stateDir;
      providersRuntimePath = providersRuntimePath;
      routerRuntimePath = routerRuntimePath;
    };
    doctorScript = pkgs.writeShellScriptBin "litellm-doctor" ''
      ${lib.optionalString (providersEnvFile != null) ''
      set -a
      if [ -f "${providersEnvFile}" ]; then
        . "${providersEnvFile}"
      fi
      set +a
      ''}
      exec "${bareDoctor}/bin/litellm-doctor" "$@"
    '';
    statusScript = healthLib.mkStatusScript { inherit stateDir; };

    wrapScript = name: script:
      pkgs.writeShellScriptBin name ''
        set -a
        ${lib.optionalString (providersEnvFile != null) ''
        if [ -f "${providersEnvFile}" ]; then
          . "${providersEnvFile}"
        fi
        ''}
        set +a
        export LITELLM_STATE_DIR="${stateDir}"
        export LITELLM_CLI_DATA="${controller}/data"
        export LITELLM_PROVIDERS_JSON="${providersRuntimePath}"
        export LITELLM_MODELS_JSON="${modelsRuntimePath}"
        export LITELLM_ROUTER_YAML="${routerRuntimePath}"
        export PATH="${lib.makeBinPath [ pkgs.jq pkgs.util-linux pkgs.yq ]}:''${PATH}"
        exec "${controller}/bin/${script}" "$@"
      '';

    renderScript = wrapScript "litellm-render" "litellm-render";
  in {
    inherit doctorScript statusScript;
    inherit renderScript;
    # Expose the committed inventory path so modules don't reach into the
    # package's internal store paths directly.
    inherit modelsJsonPath;

    # Seed the runtime providers.json from the committed seed, only if absent.
    # Manual providers.json edits (enable/disable/add) are preserved.
    activationScript = ''
      if [ ! -f ${providersRuntimePath} ]; then
        mkdir -p ${stateDir}
        cp ${providersSeedPath} ${providersRuntimePath}
        chown ${user}:${group} ${providersRuntimePath}
        echo "Created default providers.json from seed"
      fi

      # Seed the runtime router.yaml from the committed copy, only if absent.
      # Manual router.yaml edits (capabilities, logical model definitions) are
      # preserved across rebuilds.
      if [ ! -f ${routerRuntimePath} ]; then
        mkdir -p ${stateDir}
        cp ${routerSeedPath} ${routerRuntimePath}
        chown ${user}:${group} ${routerRuntimePath}
        echo "Created default router.yaml from seed"
      fi

      # Mirror the committed inventory into the runtime, but PRESERVE any
      # manual-origin entries added at runtime via litellm-add-provider --models.
      # Committed providers overlay the runtime; manual providers are kept so
      # no-rebuild additions survive a nixos-rebuild switch.
      mkdir -p ${stateDir}
      if [ -f ${modelsRuntimePath} ]; then
        _tmp=$(mktemp)
        jq -s '
          .[0] as $committed
          | .[1] as $runtime
          | ($runtime | with_entries(select(.value.source == "manual"))) as $manual
          | ($committed * $manual)
        ' ${modelsJsonPath} ${modelsRuntimePath} > "$_tmp" \
          && mv "$_tmp" ${modelsRuntimePath}
        chown ${user}:${group} ${modelsRuntimePath}
      else
        cp ${modelsJsonPath} ${modelsRuntimePath}
        chown ${user}:${group} ${modelsRuntimePath}
      fi
    '';

    fetchScript = pkgs.writeShellScriptBin "fetch-models" ''
      export PATH="${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.git ]}:$PATH"
      exec "${controller}/scripts/fetch-models.sh"
    '';

    tmpfilesRules = [
      "d ${stateDir} 0755 ${user} ${group} -"
      "d /etc/litellm 0755 root root -"
    ];

    systemPackages = [
      doctorScript
      statusScript
      renderScript
      (wrapScript "litellm-providers" "litellm-providers")
      (wrapScript "litellm-enable-provider" "litellm-enable-provider")
      (wrapScript "litellm-disable-provider" "litellm-disable-provider")
      (wrapScript "litellm-add-provider" "litellm-add-provider")
      (wrapScript "litellm-missing" "litellm-missing")
    ];
  };

in {
  inherit controller mkGateway;
}
