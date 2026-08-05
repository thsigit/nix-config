/*
 * Status: Archived
 * Last used: 2026-07
 * Reason: Superseded by ollama; kept as reference for services.llama-cpp usage
 * Safe to delete after: 2026-10
 */

# modules/ai/llama-cpp.nix
{ config, pkgs, lib, ... }:

{
  services.llama-cpp = {
    enable = true;

    package = pkgs.llama-cpp;

    settings = {
      model = "{aliases}";

      host = "127.0.0.1";
      port = 8080;

      ctx-size = 8192;

      threads = 12;

      # CPU-only; adjust if using GPU offload later
      n-gpu-layers = 0;

      # Optional performance tweaks
      batch-size = 512;
      ubatch-size = 512;

      # Embeddings if you later use RAG
      embedding = true;
    };
  };

  systemd.services.llama-cpp = {
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
}