# modules/storage/samba.nix
{ config, pkgs, ... }:
let
  defaults = import ../../settings;
  inherit (defaults) user;
  inherit (defaults.directories) appdata media;
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
      home = { "path" = "/home/${user.name}"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      repo = { "path" = "/srv/repo"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; "create mask" = "0600"; "directory mask" = "0700"; };
      appdata = { "path" = appdata; "writable" = "yes"; "read only" = "no"; "guest ok" = "yes"; "force user" = user.name; };
      web = { "path" = "/srv/www"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      books = { "path" = "${media}/books"; "read only" = "yes"; "guest ok" = "yes"; "valid users" = user.name; "write list" = user.name; };
      music = { "path" = "${media}/music"; "read only" = "yes"; "guest ok" = "yes"; "valid users" = user.name; "write list" = user.name; };
      lyrics = { "path" = "${media}/lyrics"; "read only" = "yes"; "guest ok" = "yes"; "valid users" = user.name; "write list" = user.name; };
      desktop = { "path" = "${media}/desktop"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      documents = { "path" = "${media}/documents"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      downloads = { "path" = "${media}/downloads"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      pictures = { "path" = "${media}/pictures"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      projects = { "path" = "${media}/projects"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      public = { "path" = "${media}/public"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      templates = { "path" = "${media}/templates"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
      videos = { "path" = "${media}/videos"; "writable" = "yes"; "valid users" = user.name; "force user" = user.name; };
    };
  };
  services.samba-wsdd = { enable = true; openFirewall = true; hostname = "homelab"; };
  systemd.tmpfiles.rules = [
    "d ${media} 0755 ${user.name} ${user.group} -"
    "d ${media}/books 0755 ${user.name} ${user.group} -"
    "d ${media}/music 0755 ${user.name} ${user.group} -"
    "d ${media}/lyrics 0755 ${user.name} ${user.group} -"
  ];
  environment.systemPackages = [ pkgs.samba ];
}
