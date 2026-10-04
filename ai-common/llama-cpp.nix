# ai-common/llama-cpp.nix
# llama.cpp server — 4-chat + 1-embed router (tinyllama, qwen3, qwen2.5-coder, mxbai, sailor2-1b) + Caddy, global pkgs.llama-cpp b9190.

{ config, lib, pkgs, ... }:

let
  defaults = import ../settings;
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
      "sailor2-1b" = {
        model = "${defaults.ai.models}/sailor2-1b/sailor2-1b-chat-q4_k_m.gguf";
        alias = "sailor2-1b";
        ctx-size = "4096";
        temp = "0.7";
        top-p = "0.9";
        jinja = "on";
      };
      "mxbai-embed-large" = {
        model = "${defaults.ai.models}/mxbai-embed-large/mxbai-embed-large.gguf";
        alias = "mxbai-embed-large";
        embedding = "on";
      };
    };
    extraFlags = [
      "-c" "4096"
      "--threads" "4"
      "--jinja"
    ];
  };
}
