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

  ap = {
    interface    = "wlp2s0";
    ip           = "192.168.4.1";
    cidr         = 24;
    ssid         = "kebabtamalate";
    channel      = 6;
    band         = "2g";
    gatewayName  = "KebabTamalate";
  };

in

{
  inherit user timezone directories ai tailnet domain security network ap;
}
