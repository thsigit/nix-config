# common/media/karakeep.nix
# Karakeep bookmark manager + meilisearch, with state on ${appdata} so data
# survives reformats of the root/data filesystem (only the "srv" partition
# persists).
#
# systemd 260 rejects absolute StateDirectory= values ("path is absolute,
# ignoring") and rejects symlinked StateDirectory (ELOOP), so the /var/lib/<name>
# state dirs are bind-mounted onto the persistent ${appdata}/<name> dirs via
# fileSystems; systemd then creates and owns the target through the mountpoint.
# meilisearch and karakeep-browser use static system users (DynamicUser=false)
# because systemd 260's DynamicUser state-dir setup mounts an internal "special
# execution directory" over StateDirectory, which fails with EEXIST when the path
# is already a bind mount.

{ config, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.directories) appdata;
  karakeepData = "${appdata}/karakeep";
  browserData = "${appdata}/karakeep-browser";
  meiliData = "${appdata}/meilisearch";
  meiliUid = 1015;
  karakeepUid = 1016;
in
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

  systemd.services.karakeep-workers.environment.DATA_DIR = lib.mkForce karakeepData;
  systemd.services.karakeep-web.environment.DATA_DIR = lib.mkForce karakeepData;
  systemd.services.karakeep-workers.serviceConfig.EnvironmentFile = lib.mkForce [ "${karakeepData}/settings.env" ];
  systemd.services.karakeep-web.serviceConfig.EnvironmentFile = lib.mkForce [ "${karakeepData}/settings.env" ];

  services.meilisearch.settings = {
    db_path = meiliData;
    dump_dir = "${meiliData}/dumps";
    snapshot_dir = "${meiliData}/snapshots";
  };
  systemd.services.meilisearch.serviceConfig.WorkingDirectory = lib.mkForce meiliData;

  # systemd 260 DynamicUser incompatibility -> explicit static users
  # (see header comment). Fixed UIDs are arbitrary; kept as named constants.
  users.users.meilisearch = { isSystemUser = true; uid = meiliUid; group = "meilisearch"; };
  users.groups.meilisearch = { gid = meiliUid; };
  users.users.karakeep-browser = { isSystemUser = true; uid = karakeepUid; group = "karakeep-browser"; };
  users.groups.karakeep-browser = { gid = karakeepUid; };
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
      device = karakeepData;
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
    "/var/lib/karakeep-browser" = {
      device = browserData;
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
    "/var/lib/meilisearch" = {
      device = meiliData;
      fsType = "none";
      options = [ "bind" ];
      noCheck = true;
    };
  };

  # Start the bind mounts before the services so systemd StateDirectory setup
  # always sees the mounted state dirs (never an empty /var/lib dir).
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
