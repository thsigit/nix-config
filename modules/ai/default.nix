# modules/ai/default.nix 

{ config, lib, pkgs, ... }:

{
  imports = [
    ./ollama.nix
	./hermes.nix
    #./litellm.nix
	#./llama-cpp.nix
	#./vane.nix
	#./local-ai.nix
  ];
  environment.systemPackages = with pkgs; [
    claude-code qwen-code codex github-copilot-cli opencode openclaw 
    mistral-rs fabric-ai aichat
    llmserve llm sillytavern llmfit 
  ];
}