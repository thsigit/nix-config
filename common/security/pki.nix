# common/security/pki.nix

{ config, pkgs, lib, ... }:

let
  defaults = import ../../settings;
  inherit (defaults) domain;
  sslDir = defaults.security.sslDir;

  baseDomains = [
    "*.${domain}"
    domain
  ];

  # Domain layanan yang selalu masuk SAN, terlepas dari status enable service.
  # Auto-generate dari services.caddy.services hanya menjaring service yang
  # AKTIF; service yang direferensikan di dnsmasq/hosts tapi nonaktif (mis.
  # darkstat, litellm) atau di-archive (wallabag, localai) tetap
  # perlu SAN eksplisit agar TLS valid saat diakses.
  extraDomains = [
    "darkstat.${domain}"
    "litellm.${domain}"
    "wallabag.${domain}"
    "localai.${domain}"
  ];

  caddyServices = config.services.caddy.services or { };
  lanServices = lib.filterAttrs (name: svc: svc.visibility.lan) caddyServices;
  serviceDomains = [ "homelab.${domain}" ] ++
    lib.mapAttrsToList (name: svc: "${name}.${domain}") lanServices;

  allDomains = lib.unique (baseDomains ++ serviceDomains ++ extraDomains);

  altNames =
    lib.concatStringsSep "\n"
      (lib.imap1
        (i: domain: "DNS.${toString i} = ${domain}")
        allDomains);

in

{
  environment.systemPackages = with pkgs; [ openssl ];

  users.groups.caddy = { };

  systemd.tmpfiles.rules = [
    "d ${sslDir} 0750 root caddy -"
  ];

  # ── 1. Generate & trust Homelab Internal CA ──────────────────────────────
  systemd.services.homelab-ca = {
    description = "Generate and Trust Homelab Internal CA";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    path = [ pkgs.openssl pkgs.coreutils pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -euxo pipefail

      install -d -m0750 -o root -g caddy ${sslDir}

      if [ ! -f ${sslDir}/homelab-ca.key ]; then
        openssl genrsa -out ${sslDir}/homelab-ca.key 4096
      fi

      if [ ! -f ${sslDir}/homelab-ca.crt ]; then
        openssl req -x509 -new -nodes \
          -key ${sslDir}/homelab-ca.key \
          -sha256 -days 3650 \
          -out ${sslDir}/homelab-ca.crt \
          -subj "/CN=Homelab Internal CA"

        cp ${sslDir}/homelab-ca.crt /etc/ssl/certs/homelab-ca.pem

        rm -f ${sslDir}/homelab.crt ${sslDir}/homelab.cnf.hash
        NEW_CA=1
      fi

      chmod 640 ${sslDir}/homelab-ca.key
      chmod 644 ${sslDir}/homelab-ca.crt
      chown root:caddy ${sslDir}/homelab-ca.key
      chown root:root  ${sslDir}/homelab-ca.crt

      if [ "''${NEW_CA:-0}" = "1" ]; then
        systemctl start homelab-cert.service || true
        if systemctl is-active --quiet caddy.service; then
          systemctl reload-or-restart caddy.service || true
        fi
      fi
    '';
  };

  # ── 2. Trust CA ke system store NixOS (deklaratif) ───────────────────────
  security.pki.certificateFiles = [ ./homelab-ca.crt ];

  # ── 3. Generate Homelab Wildcard Certificate ──────────────────────────────
  systemd.services.homelab-cert = {
    description = "Generate Homelab Wildcard Certificate";
    wantedBy = [ "multi-user.target" ];
    requires = [ "homelab-ca.service" ];
    after = [ "homelab-ca.service" ];
    path = [ pkgs.openssl pkgs.coreutils pkgs.systemd ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -euxo pipefail

      install -d -m0750 -o root -g caddy ${sslDir}

      cat > ${sslDir}/homelab.cnf <<EOF
[req]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[dn]
CN = *.${domain}

[req_ext]
subjectAltName = @alt_names

[v3_ext]
subjectAltName = @alt_names

[alt_names]
${altNames}
EOF

      CNF_HASH=$(sha256sum ${sslDir}/homelab.cnf | cut -d' ' -f1)
      STORED_HASH=$(cat ${sslDir}/homelab.cnf.hash 2>/dev/null || echo "")

      NEED_REGEN=0
      [ ! -f ${sslDir}/homelab.crt ] && NEED_REGEN=1
      [ "$CNF_HASH" != "$STORED_HASH" ] && NEED_REGEN=1

      if [ "$NEED_REGEN" = "1" ]; then
        if [ ! -f ${sslDir}/homelab.key ]; then
          openssl genrsa -out ${sslDir}/homelab.key 4096
        fi

        openssl req -new \
          -key ${sslDir}/homelab.key \
          -out ${sslDir}/homelab.csr \
          -config ${sslDir}/homelab.cnf

        openssl x509 -req \
          -in    ${sslDir}/homelab.csr \
          -CA    ${sslDir}/homelab-ca.crt \
          -CAkey ${sslDir}/homelab-ca.key \
          -set_serial "0x$(openssl rand -hex 8)" \
          -out   ${sslDir}/homelab.crt \
          -days 825 -sha256 \
          -extensions v3_ext \
          -extfile ${sslDir}/homelab.cnf

        echo "$CNF_HASH" > ${sslDir}/homelab.cnf.hash

        rm -f ${sslDir}/homelab.csr

        if systemctl is-active --quiet caddy.service; then
          systemctl reload-or-restart caddy.service || true
        fi
      fi

      chmod 640 ${sslDir}/homelab.key
      chmod 644 ${sslDir}/homelab.crt
      chown root:caddy ${sslDir}/homelab.key
      chown root:root  ${sslDir}/homelab.crt
    '';
  };
}
