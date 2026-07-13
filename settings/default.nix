# settings/default.nix

let

  user = {
    name = "sigit";
    group = "users";
    uid = "1000";
    gid = "100";
  };

  timezone = "Asia/Makassar";

  directories = {
    media   = "/srv/media";
    appdata = "/srv/appdata";
  };

  ai = {
    root = "/srv/ai";
    models = "/srv/ai/models";
  };

in

{
  inherit user timezone directories ai;

  baseEnv = {
    PUID = user.uid;
    PGID = user.gid;
    TZ   = timezone;
  };

  qbittorrentEnv = {
    WEBUI_PORT = "8080";
  };
}