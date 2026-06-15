# modules/storage/samba.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../lib;
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
      home = {
        "path" = "/home/${defaults.user}";
        "writable" = "yes";
        "valid users" = defaults.user;
        "force user" = defaults.user;
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      repo = {
        "path" = defaults.repoDir;
        "writable" = "yes";
        "valid users" = defaults.user;
        "force user" = defaults.user;
        "create mask" = "0600";
        "directory mask" = "0700";
      };

      apps = {
        "path" = defaults.appDir;
        "writable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = defaults.user;
        "create mask" = "0644";
        "directory mask" = "0755";
      };
  
      # Public (read-only)
      books = {
        "path" = "${defaults.dataDir}/books";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = defaults.user;
        "write list" = defaults.user;
      };

      music = {
        "path" = "${defaults.dataDir}/music";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = defaults.user;
        "write list" = defaults.user;
      };

      lyrics = {
        "path" = "${defaults.dataDir}/lyrics";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = defaults.user;
        "write list" = defaults.user;
      };

#      music_store = {
#        "path" = "${defaults.dataDir}/music_store";
#        "read only" = "yes";
#        "guest ok" = "yes";
#        "valid users" = defaults.user;
#        "write list" = defaults.user;
#      };

      new_music = {
        "path" = "${defaults.dataDir}/new_music";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = defaults.user;
        "write list" = defaults.user;
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
    "d ${defaults.dataDir} 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/uploads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/downloads 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/app 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/books 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/music 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/new_music 0755 ${defaults.user} ${defaults.group} -"
 #   "d ${defaults.dataDir}/music_store 0755 ${defaults.user} ${defaults.group} -"
    "d ${defaults.dataDir}/lyrics 0755 ${defaults.user} ${defaults.group} -"
  ];

  environment.systemPackages = with pkgs; [
    samba
  ];
}
