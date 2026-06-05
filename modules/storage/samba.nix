# modules/storage/samba.nix

{ config, pkgs, lib, ... }:

let
  cfg = {
    user = "sigit";
    group = "users";
    dataDir = "/srv/data";
	repoDir = "/srv/repo";
  };
in
{
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "homelab";

        "security" = "user";
        "use sendfile" = "yes";

        "bind interfaces only" = "no";
        "hosts allow" = "192.168.1.0/24 127.0.0.1";

        "guest account" = "nobody";
        "map to guest" = "bad user";
		
		"browseable" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      # Private (read-only)
      repo = {
        "path" = cfg.repoDir;
        "writable" = "yes";
        "read only" = "no";
        "valid users" = cfg.user;		
        "force user" = cfg.user;
        "create mask" = "0600";
        "directory mask" = "0700";
	    };
	  
      # Public (read-only)
      shared = {
        "path" = cfg.dataDir;
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = cfg.user;
        "write list" = cfg.user;
      };

      datadisk = {
        "path" = "/mnt/datadisk";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = cfg.user;
        "force group" = cfg.group;
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
	hostname = "homelab";
  };

  # Pastikan direktori ada (infra responsibility)
  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0755 ${cfg.user} ${cfg.group} -"
    "d ${cfg.dataDir}/uploads 0755 ${cfg.user} ${cfg.group} -"
    "d ${cfg.dataDir}/downloads 0755 ${cfg.user} ${cfg.group} -"
  ];

  environment.systemPackages = with pkgs; [
    samba
  ];
}
