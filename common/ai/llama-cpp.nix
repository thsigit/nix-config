# common/ai/llama-cpp.nix
# llama.cpp server — multi-model router with Caddy + tuned presets (global pkgs.llama-cpp 0.4.0 via flake.nix overlay).

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
in
{
  services.caddy.services.llama = {
    port = 8080;
    visibility = { lan = true; tailscale = true; };
  };

  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    modelsDir = defaults.ai.models;
    modelsPreset = {
      tinyllama = {
        model = "${defaults.ai.models}/tinyllama/tinyllama.gguf";
        alias = "tinyllama";
        ctx-size = "4096";
        temp = "0.7";
        top-p = "0.9";
        jinja = "on";
      };
      gemma3n = {
        model = "${defaults.ai.models}/gemma3n/gemma3n.gguf";
        alias = "gemma3n";
        ctx-size = "4096";
        jinja = "on";
      };
      "mxbai-embed-large" = {
        model = "${defaults.ai.models}/mxbai-embed-large/mxbai-embed-large.gguf";
        alias = "mxbai-embed-large";
        embedding = "on";
      };
      "qwen2.5-coder" = {
        model = "${defaults.ai.models}/qwen2.5-coder/qwen2.5-coder.gguf";
        alias = "qwen2.5-coder";
        ctx-size = "4096";
        jinja = "on";
      };
      qwen3 = {
        model = "${defaults.ai.models}/qwen3/qwen3.gguf";
        alias = "qwen3";
        ctx-size = "4096";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
        jinja = "on";
      };
      "qwen3-vl" = {
        model = "${defaults.ai.models}/qwen3-vl/qwen3-vl.gguf";
        alias = "qwen3-vl";
        ctx-size = "4096";
        temp = "1.0";
        jinja = "on";
      };
      translategemma = {
        model = "${defaults.ai.models}/translategemma/translategemma.gguf";
        alias = "translategemma";
        ctx-size = "4096";
        jinja = "on";
      };
    };
    extraFlags = [
      "-c" "4096"
      "--threads" "4"
      "--jinja"
    ];
  };
}
