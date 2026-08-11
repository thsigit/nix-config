# common/media/karakeep.nix
# Karakeep bookmark manager + meilisearch, with state on /srv/appdata so data
# survives reformats of the root/data filesystem (only /dev/sda1 "srv" persists).
#
# systemd 260 rejects absolute StateDirectory= values ("path is absolute,
# ignoring") and rejects symlinked StateDirectory (ELOOP), so the /var/lib/<name>
# state dirs are bind-mounted onto the persistent /srv/appdata/<name> dirs via
# fileSystems; systemd then creates and owns the target through the mountpoint.
{ config, lib, ... }:
{
  services.caddy.services.karakeep = { port = 8086; };

  services.karakeep = {
    enable = true;
    extraEnvironment = {
      HOST = "0.0.0.0";
      PORT = "8086";
      DISABLE_SIGNUPS = "false";
    };
  };

  systemd.services.karakeep-workers.environment.DATA_DIR = lib.mkForce "/srv/appdata/karakeep";
  systemd.services.karakeep-web.environment.DATA_DIR = lib.mkForce "/srv/appdata/karakeep";
  systemd.services.karakeep-workers.serviceConfig.EnvironmentFile = lib.mkForce [ "/srv/appdata/karakeep/settings.env" ];
  systemd.services.karakeep-web.serviceConfig.EnvironmentFile = lib.mkForce [ "/srv/appdata/karakeep/settings.env" ];

  services.meilisearch.settings = {
    db_path = "/srv/appdata/meilisearch";
    dump_dir = "/srv/appdata/meilisearch/dumps";
    snapshot_dir = "/srv/appdata/meilisearch/snapshots";
  };
  systemd.services.meilisearch.serviceConfig.WorkingDirectory = lib.mkForce "/srv/appdata/meilisearch";

  # meilisearch and karakeep-browser run DynamicUser=true, but systemd 260's
  # DynamicUser state-dir setup mounts an internal "special execution directory"
  # over StateDirectory, which fails with EEXIST when the path is already a bind
  # mount. Give both units static system users instead.
  users.users.meilisearch = { isSystemUser = true; uid = 1015; group = "meilisearch"; };
  users.groups.meilisearch = { gid = 1015; };
  users.users.karakeep-browser = { isSystemUser = true; uid = 1016; group = "karakeep-browser"; };
  users.groups.karakeep-browser = { gid = 1016; };
  systemd.services.meilisearch.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "meilisearch";
    Group = "meilisearch";
  };
  systemd.services.karakeep-browser.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "karakeep-browser";
    Group = "karakeep-browser";
  };

  fileSystems = {
    "/var/lib/karakeep" = {
      device = "/srv/appdata/karakeep";
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
    "/var/lib/karakeep-browser" = {
      device = "/srv/appdata/karakeep-browser";
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
    "/var/lib/meilisearch" = {
      device = "/srv/appdata/meilisearch";
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
  };

  # Start the bind mounts before the services so systemd StateDirectory setup
  # always sees the mounted /srv/appdata dirs (never an empty /var/lib dir).
  systemd.services.karakeep-init.after = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-init.requires = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-workers.after = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-workers.requires = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-web.after = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-web.requires = [ "var-lib-karakeep.mount" ];
  systemd.services.karakeep-browser.after = [ "var-lib-karakeep\\x2dbrowser.mount" ];
  systemd.services.karakeep-browser.requires = [ "var-lib-karakeep\\x2dbrowser.mount" ];
  systemd.services.meilisearch.after = [ "var-lib-meilisearch.mount" ];
  systemd.services.meilisearch.requires = [ "var-lib-meilisearch.mount" ];
}
