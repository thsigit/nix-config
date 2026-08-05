# modules/ai/litellm/gateway.nix
# Defines the gateway option — built by the controller package

{ config, lib, pkgs, ... }:

let
  controller = pkgs.callPackage ../../../pkgs/litellm-cli {};
  state = config.litellm.state;

in {
  options.litellm.gateway = lib.mkOption {
    type = lib.types.attrs;
    default = controller.mkGateway {
      stateDir = state.dataDir;
      providersRuntimePath = state.providersJson;
      modelsRuntimePath = state.modelsJson;
      configYamlPath = state.configYaml;
      healthJsonPath = state.healthJson;
    };
    description = "AI gateway configuration built by the controller package";
  };
}
