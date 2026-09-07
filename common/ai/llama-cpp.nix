# common/ai/llama-cpp.nix
# llama.cpp server — 3-chat + 1-embed + 2-vision router (tinyllama, qwen3, qwen2.5-coder, mxbai, qwen2.5-vl-3b, gemma-4-E4B) + Caddy, global pkgs.llama-cpp b9190.

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
      "mxbai-embed-large" = {
        model = "${defaults.ai.models}/mxbai-embed-large/mxbai-embed-large.gguf";
        alias = "mxbai-embed-large";
        embedding = "on";
      };
      "qwen2.5-vl-3b" = {
        hf-repo = "unsloth/Qwen2.5-VL-3B-Instruct-GGUF";
        hf-file = "Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf";
        mmproj = "${defaults.ai.models}/qwen2.5-vl-3b/mmproj-F16.gguf";
        alias = "qwen2.5-vl-3b";
        ctx-size = "4096";
        jinja = "on";
      };
      "gemma-4-E4B" = {
        model = "${defaults.ai.models}/gemma-4-E4B/gemma-4-E4B-it-OBLITERATED-Q4_K_M.gguf";
        mmproj = "${defaults.ai.models}/gemma-4-E4B/gemma-4-E4B-it-OBLITERATED-mmproj-f16.gguf";
        alias = "gemma-4-E4B";
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
