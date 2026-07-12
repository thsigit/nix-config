# lib/default.nix

let
  mainUser  = "sigit";
  mainGroup = "users";
  mainUid   = "1000";
  mainGid   = "100";
  mainTz    = "Asia/Makassar";
in
{
  # User & Group
  user  = mainUser;
  group = mainGroup;
  uid   = mainUid;
  gid   = mainGid;

  # Timezone
  timezone = mainTz;
  
  baseEnv = {
    PUID = mainUid;
    PGID = mainGid;
    TZ   = mainTz;
  };

  qbittorrentEnv = {
    PUID = mainUid;
    PGID = mainGid;
    TZ   = mainTz;
    WEBUI_PORT = "8080";
  };

  # Directories
  mediaDir   = "/srv/media";
  appdataDir = "/srv/appdata";
  repoDir    = "/srv/repo";

}