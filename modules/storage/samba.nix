# modules/storage/samba.nix

{ config, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) 
    user 
    directories;
  mediaRoot = directories.media;
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
        "path" = "/home/${user.name}";
        "writable" = "yes";
        "valid users" = user.name;
        "force user" = user.name;
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      repo = {
        "path" = "/srv/repo";
        "writable" = "yes";
        "valid users" = user.name;
        "force user" = user.name;
        "create mask" = "0600";
        "directory mask" = "0700";
      };

      appdata = {
        "path" = directories.appdata;
        "writable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = user.name;
        "create mask" = "0644";
        "directory mask" = "0755";
      };

        web = {
        "path" = "/srv/www";
        "writable" = "yes";
        "valid users" = user.name;
        "force user" = user.name;
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      # Public (read-only)
      books = {
        "path" = "${mediaRoot}/books";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = user.name;
        "write list" = user.name;
      };

      music = {
        "path" = "${mediaRoot}/music";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = user.name;
        "write list" = user.name;
      };

      lyrics = {
        "path" = "${mediaRoot}/lyrics";
        "read only" = "yes";
        "guest ok" = "yes";
        "valid users" = user.name;
        "write list" = user.name;
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
    "d ${mediaRoot} 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/books 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/music 0755 ${user.name} ${user.group} -"
    "d ${mediaRoot}/lyrics 0755 ${user.name} ${user.group} -"

    # "d ${mediaRoot}/uploads 0755 ${user.name} ${user.group} -"
    # "d ${mediaRoot}/downloads 0755 ${user.name} ${user.group} -"
  ];

  environment.systemPackages = with pkgs; [
    samba
  ];
}