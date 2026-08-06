# modules/ai/default.nix
#
# Enable / disable each service by commenting its import line.
# Each entry is a directory or file owning a single service:
#   ./litellm-podman  — LiteLLM gateway (Podman container + config layer)
#   ./bitrouter       — BitRouter gateway (container mode)
#   ./ollama.nix      — Ollama
#   ./llama-cpp.nix   — llama.cpp server
#   ./podman-vane.nix — Vane
#   ./litellm         — (reference only; systemd-native LiteLLM, disabled)

{ config, lib, pkgs, ... }:

{
  imports = [
    #./ollama.nix
    #./litellm-podman
    ./bitrouter
    ./podman-vane.nix
    ./llama-cpp.nix
    # ./litellm  # systemd-native LiteLLM reference (disabled by default)
  ];
  environment.systemPackages = with pkgs; [
    github-copilot-cli mistral-rs fabric-ai aichat
    llmserve llm llmfit opencode
  ];
}
