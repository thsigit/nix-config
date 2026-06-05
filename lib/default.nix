# lib/default.nix

let
  # 1. Definisikan variabel internal di sini agar bisa dipakai berulang kali di bawah
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
  
  # Directories
  dataDir   = "/srv/data";
  appDir    = "/srv/app";
  dataStore = "/mnt/datadisk";

  # Timezone
  timezone = mainTz;
  
  # 2. Base environment utama (menggantikan env.nix lama)
  baseEnv = {
    PUID = mainUid;
    PGID = mainGid;
    TZ   = mainTz;
  };
  
  # 3. Custom environment (menggunakan operator // untuk menggabungkan baseEnv dengan data baru)
  transmissionEnv = {
    PUID = mainUid;
    PGID = mainGid;
    TZ   = mainTz;
    # Anda bisa menggunakan rahasia/secret di sini nanti
    USERNAME = "admin";
    PASSWORD = "admin";
  };

  qbittorrentEnv = {
    PUID = mainUid;
    PGID = mainGid;
    TZ   = mainTz;
    WEBUI_PORT = "8080";
  };
}