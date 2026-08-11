# common/ap/freeradius.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.freeradius;
  ap = config.services.ap.interface;
  certsDir = "/srv/appdata/freeradius/certs";

  configDir = pkgs.runCommand "freeradius-config" { } ''
    cp -r ${cfg.package}/etc/raddb $out
    chmod -R +w $out

    # Fix BlastRADIUS: require Message-Authenticator from localhost
    sed -i "s/^#.*require_message_authenticator = no/	require_message_authenticator = yes/" $out/clients.conf

    # AP client + secret come from a runtime file (sops) so the secret is not
    # baked into the Nix store. See the preStart seed below.
    echo '$INCLUDE /srv/appdata/freeradius/clients.conf' >> $out/clients.conf

    # Enable PEAP as default EAP type
    sed -i 's/^	default_eap_type = md5/	default_eap_type = peap/' $out/mods-available/eap

    # Point EAP TLS at the runtime certs dir (generated at activation, see
    # activationScripts.freeradius-certs) so the private key is never baked
    # into /nix/store. Replace the literal 'certdir'/'cadir' path tokens.
    sed -i \
      -e 's|''${certdir}/server\.pem|${certsDir}/server.pem|g' \
      -e 's|''${cadir}/ca\.pem|${certsDir}/ca.pem|g' \
      -e 's|''${cadir}|${certsDir}|g' \
      $out/mods-available/eap

    # Include runtime users file (editable without rebuild)
    echo '$INCLUDE /srv/appdata/freeradius/users' >> $out/mods-config/files/authorize
  '';
in
{
  config = lib.mkIf config.services.ap.enable {
    services.freeradius = {
      enable = true;
      inherit configDir;
    };

    networking.firewall.allowedUDPPorts = [ 1812 1813 ];
    environment.systemPackages = [ cfg.package ];

    # Dir must be writable by the radius user: preStart (runs as radius) seeds
    # the runtime clients.conf + users files here.
    systemd.tmpfiles.rules = [
      "d /srv/appdata/freeradius 0750 radius radius -"
      "d ${certsDir} 0700 radius radius -"
    ];

    # Generate EAP server certs at activation (not build), so the private key is
    # owned by radius and not world-readable in /nix/store.
    system.activationScripts.freeradius-certs = stringAfter [ "users" ] ''
      set -euo pipefail
      if [ ! -f ${certsDir}/server.pem ]; then
        mkdir -p ${certsDir}
        cd ${certsDir}
        openssl genrsa -out ca.key 2048
        openssl req -x509 -new -key ca.key -out ca.pem -days 3650 \
          -subj "/CN=homelab.home.arpa/O=KebabTamalate/OU=Homelab"
        openssl genrsa -out server.key 2048
        openssl req -new -key server.key -out server.csr \
          -subj "/CN=homelab.home.arpa/O=KebabTamalate/OU=Homelab"
        openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 3650
        # FreeRADIUS expects private key AND certificate in server.pem
        cat server.key server.crt > server.pem
        openssl dhparam -out dh 2048
        rm -f server.csr server.key server.crt ca.srl
        chmod 600 ca.key server.pem
        chown -R radius:radius ${certsDir}
      fi
    '';

    # Seed runtime files on first start. The service runs as `radius`, so this
    # preStart also runs as `radius` — the files must be writable by that user.
    # lib.mkBefore so the seed runs BEFORE the module's radiusd -C config check
    # (otherwise the missing $INCLUDE'd file fails the check on first boot).
    systemd.services.freeradius.preStart = lib.mkBefore ''
      if [ ! -f /srv/appdata/freeradius/clients.conf ]; then
        cat > /srv/appdata/freeradius/clients.conf << EOF
client ap-${ap} {
  ipaddr = 192.168.4.1
  secret = $(cat ${config.sops.secrets."radius-secret".path})
  shortname = kebabtamalate-ap
  nas_type = other
  proto = udp
}
EOF
        chmod 640 /srv/appdata/freeradius/clients.conf
      fi
      if [ ! -f /srv/appdata/freeradius/users ]; then
        cat > /srv/appdata/freeradius/users << 'EOF2'
# Runtime FreeRADIUS users — edit this file directly, then:
#   sudo systemctl reload freeradius
# Format: <username> Cleartext-Password := "<password>"
EOF2
        cat ${config.sops.secrets."radius-users".path} >> /srv/appdata/freeradius/users
        chmod 640 /srv/appdata/freeradius/users
      fi
    '';
  };
}
