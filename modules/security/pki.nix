# modules/security/pki.nix 

{ config, pkgs, lib, ... }:

let
  sslDir = "/etc/ssl/homelab";

  baseDomains = [
    "*.home.arpa"
    "home.arpa"
  ];

  serviceDomains = [
    "homelab.home.arpa"
    "wallabag.home.arpa"
    "darkstat.home.arpa"
  ];

  allDomains = baseDomains ++ serviceDomains;

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

  # Generate and Trust Homelab Internal CA
  systemd.services.homelab-ca = {
    description = "Generate and Trust Homelab Internal CA";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];

    path = [ pkgs.openssl pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euxo pipefail

      # Buat CA jika belum ada
      if [ ! -f ${sslDir}/homelab-ca.key ]; then
        openssl genrsa -out ${sslDir}/homelab-ca.key 4096
      fi

      if [ ! -f ${sslDir}/homelab-ca.crt ]; then
        openssl req -x509 -new -nodes \
          -key ${sslDir}/homelab-ca.key \
          -sha256 -days 3650 \
          -out ${sslDir}/homelab-ca.crt \
          -subj "/CN=Homelab Internal CA"
          
        # inject langsung ke sistem sertifikat Linux
        # menggantikan option security.pki.certificateFiles 
        # expire pada tahun 2036, hapus .crt untuk membuat baru
        cp ${sslDir}/homelab-ca.crt /etc/ssl/certs/homelab-ca.pem
        update-ca-certificates
      fi

      chmod 640 ${sslDir}/homelab-ca.key
      chmod 644 ${sslDir}/homelab-ca.crt
      chown root:caddy ${sslDir}/homelab-ca.key
      chown root:root ${sslDir}/homelab-ca.crt
    '';
  };

  # Generate Homelab Wildcard Certificate
  systemd.services.homelab-cert = {
    description = "Generate Homelab Wildcard Certificate";
    wantedBy = [ "multi-user.target" ];
    after = [ "homelab-ca.service" ];

    path = [ pkgs.openssl pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euxo pipefail

      cat > ${sslDir}/homelab.cnf <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext
[dn]
CN = *.home.arpa
[req_ext]
subjectAltName = @alt_names
[alt_names]
${altNames}
EOF

      if [ ! -f ${sslDir}/homelab.key ]; then
        openssl genrsa -out ${sslDir}/homelab.key 4096
      fi

      if [ ! -f ${sslDir}/homelab.crt ]; then
        openssl req -new \
          -key ${sslDir}/homelab.key \
          -out ${sslDir}/homelab.csr \
          -config ${sslDir}/homelab.cnf

        openssl x509 -req \
          -in ${sslDir}/homelab.csr \
          -CA ${sslDir}/homelab-ca.crt \
          -CAkey ${sslDir}/homelab-ca.key \
          -CAcreateserial \
          -out ${sslDir}/homelab.crt \
          -days 825 -sha256 \
          -extensions req_ext \
          -extfile ${sslDir}/homelab.cnf
      fi

      chmod 640 ${sslDir}/homelab.key
      chmod 644 ${sslDir}/homelab.crt
      chown root:caddy ${sslDir}/homelab.key
      chown root:root ${sslDir}/homelab.crt

      rm -f ${sslDir}/homelab.csr ${sslDir}/homelab-ca.srl
    '';
  };
}