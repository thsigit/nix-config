# commons/db/default.nix
# PostgreSQL server for homelab services (first consumer: LiteLLM).
# DB credentials live in ${appdata}/litellm-container/database.env (0600),
# generated with a random password on first activation.

{ config, lib, pkgs, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.user) name group;
  inherit (defaults.directories) appdata;

  appdataDir = "${appdata}/litellm-container";
  dbName = "litellm";
  dbUser = "litellm";
  databaseEnv = "${appdataDir}/database.env";
in
{
  services.postgresql = {
    enable = true;
    # Live on the preserved /dev/sda1 "srv" partition so the DB survives root
    # reformats/reinstalls. The module auto-creates StateDirectory only under
    # /var/lib/postgresql, so a tmpfiles rule below creates it instead.
    dataDir = "/srv/appdata/postgresql";
    enableTCPIP = true;
    settings = {
      # Loopback only: the gateway container uses host networking and Caddy
      # proxies from the host, so nothing needs LAN exposure.
      listen_addresses = lib.mkForce "127.0.0.1";
      password_encryption = "scram-sha-256";
    };
    authentication = lib.mkBefore ''
      host ${dbName} ${dbUser} 127.0.0.1/32 scram-sha-256
    '';
    ensureDatabases = [ dbName ];
    ensureUsers = [
      { name = dbUser; ensureDBOwnership = true; }
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/appdata/postgresql 0700 postgres postgres -"
    "d ${appdataDir} 0755 ${name} ${group} -"
  ];

  # Generate a random DATABASE_URL on first activation; persists across boots.
  system.activationScripts.litellm-db-env = lib.stringAfter [ "users" "groups" ] ''
    if [ ! -f ${databaseEnv} ]; then
      mkdir -p ${appdataDir}
      pw=$(${pkgs.openssl}/bin/openssl rand -hex 32)
      umask 077
      cat > ${databaseEnv} <<EOF
DATABASE_URL=postgresql://${dbUser}:$pw@127.0.0.1:5432/${dbName}
EOF
      chown ${name}:${group} ${databaseEnv}
      chmod 0600 ${databaseEnv}
    fi
  '';

  # Keep the role password in sync with database.env after the role/db exist.
  # Runs as root (NOT postgres) because database.env is 0600 owned by the user;
  # psql is executed as postgres via runuser so local peer auth applies.
  # wantedBy multi-user.target + After=postgresql-setup: the container only has
  # After= on this unit, so without a wantedBy this oneshot would never start.
  systemd.services.litellm-db-password = {
    description = "Sync LiteLLM database role password";
    after = [ "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    path = [ config.services.postgresql.package ];
    script = ''
      set -eu
      [ -f ${databaseEnv} ] || exit 0
      url=$(grep '^DATABASE_URL=' ${databaseEnv} | cut -d= -f2-)
      pw=$(printf '%s' "$url" | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
      ${pkgs.util-linux}/bin/runuser -u postgres -- psql -d postgres -tAc "ALTER ROLE ${dbUser} WITH LOGIN PASSWORD '$pw';"
    '';
  };

  # Let the gateway wait for the password sync before connecting to the DB.
  systemd.services.podman-litellm.after = lib.mkIf (config.ai.podmanLitellm.enable or false) [
    "litellm-db-password.service"
  ];
}
