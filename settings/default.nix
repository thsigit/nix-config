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
    models = "/srv/ai/models";
  };

  tailnet = "basa-komodo";
  domain = "home.arpa";

  security = {
    sslDir = "/etc/ssl/homelab";
  };

  network = {
    lanInterface = "enp0s31f6";
    lanIp = "192.168.1.3";
    lanPrefix = 24;
    lanCidr = "192.168.1.0/24";
    gateway = "192.168.1.1";
  };

in

{
  inherit user timezone directories ai tailnet domain security network;
}
