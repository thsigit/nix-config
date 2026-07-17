# modules/ai/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ollama.nix
	./hermes.nix
    ./litellm
	#./llama-cpp.nix
	./podman-vane.nix
	./podman-localai.nix
  ];
  environment.systemPackages = with pkgs; [
    github-copilot-cli openclaw 
    mistral-rs fabric-ai aichat
    llmserve llm sillytavern llmfit 
	opencode
  ];
}