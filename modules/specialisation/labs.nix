# /etc/nixos/modules/specialisation/labs.nix

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../hardware-configuration.nix
	../core/users.nix
	../security/ssh.nix 
	../storage # import seluruh rsync.nix, samba.nix, vsftpd.nix, filemount.nix
	
  ];

  networking.hostName = "labs";
  
  networking.firewall.enable = false;
  
  environment.systemPackages = with pkgs; [
    parallel
    tmux
    git
    curl
    jq
    # ollama
    # llama-cpp
  ];

  systemd.tmpfiles.rules = [
    "d /ai 0755 sigit users -"
    "d /ai/models 0755 sigit users -"
    "d /ai/projects 0755 sigit users -"
    "d /ai/datasets 0755 sigit users -"
  ];

  system.stateVersion = "25.05";
}