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
    www     = "/srv/www";
  };

  ai = {
    root = "/srv/ai";
    models = "/srv/ai/models";
    repo = "/srv/repo/nix-config";
  };

  tailnet = "basa-komodo";
  domain = "home.arpa";

  network = {
    lanInterface = "enp0s31f6";
    lanIp = "192.168.1.3";
    lanPrefix = 24;
    gateway = "192.168.1.1";
  };

in

{
  inherit user timezone directories ai tailnet domain network;

  baseEnv = {
    PUID = user.uid;
    PGID = user.gid;
    TZ   = timezone;
  };

  qbittorrentEnv = {
    WEBUI_PORT = "8080";
  };
}
