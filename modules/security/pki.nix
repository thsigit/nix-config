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
    "triliumnotes.home.arpa"
  ];
  allDomains = baseDomains ++ serviceDomains;

  # Dipakai untuk SAN di cert (section [v3_ext] terpisah dari [req_ext])
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
    path = [ pkgs.openssl pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euxo pipefail

      # Generate CA key jika belum ada
      if [ ! -f ${sslDir}/homelab-ca.key ]; then
        openssl genrsa -out ${sslDir}/homelab-ca.key 4096
      fi

      # Generate CA cert jika belum ada
      # Catatan: untuk regenerate, hapus homelab-ca.crt (expire 2036)
      if [ ! -f ${sslDir}/homelab-ca.crt ]; then
        openssl req -x509 -new -nodes \
          -key ${sslDir}/homelab-ca.key \
          -sha256 -days 3650 \
          -out ${sslDir}/homelab-ca.crt \
          -subj "/CN=Homelab Internal CA"

        # NixOS tidak punya update-ca-certificates (itu Debian/Ubuntu).
        # Trust CA via security.pki.certificateFiles di configuration.nix.
        # Copy ke /etc/ssl/certs/ hanya sebagai referensi mudah, bukan trust.
        cp ${sslDir}/homelab-ca.crt /etc/ssl/certs/homelab-ca.pem
      fi

      chmod 640 ${sslDir}/homelab-ca.key
      chmod 644 ${sslDir}/homelab-ca.crt
      chown root:caddy ${sslDir}/homelab-ca.key
      chown root:root  ${sslDir}/homelab-ca.crt
    '';
  };

  # ── 2. Trust CA ke system store NixOS (deklaratif) ───────────────────────
  # Ini pengganti update-ca-certificates yang tidak ada di NixOS.
  # Dibaca saat nixos-rebuild, jadi CA harus sudah ada sebelumnya
  # (bootstrap pertama: rebuild lagi setelah homelab-ca.service jalan).
  security.pki.certificateFiles = lib.mkIf
    (builtins.pathExists "${sslDir}/homelab-ca.crt")
    [ "${sslDir}/homelab-ca.crt" ];

  # ── 3. Generate Homelab Wildcard Certificate ──────────────────────────────
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

      # Tulis config — selalu di-overwrite agar hash bisa dibandingkan
      cat > ${sslDir}/homelab.cnf <<EOF
[req]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[dn]
CN = *.home.arpa

[req_ext]
subjectAltName = @alt_names

# Section terpisah untuk signing (-extensions v3_ext)
# req_extensions hanya dibaca saat membuat CSR,
# bukan saat x509 -req mensign — pakai v3_ext untuk itu.
[v3_ext]
subjectAltName = @alt_names

[alt_names]
${altNames}
EOF

      # Deteksi perubahan domain: bandingkan hash .cnf
      CNF_HASH=$(sha256sum ${sslDir}/homelab.cnf | cut -d' ' -f1)
      STORED_HASH=$(cat ${sslDir}/homelab.cnf.hash 2>/dev/null || echo "")

      NEED_REGEN=0
      [ ! -f ${sslDir}/homelab.crt ] && NEED_REGEN=1
      [ "$CNF_HASH" != "$STORED_HASH" ] && NEED_REGEN=1

      if [ "$NEED_REGEN" = "1" ]; then
        # Generate key jika belum ada
        if [ ! -f ${sslDir}/homelab.key ]; then
          openssl genrsa -out ${sslDir}/homelab.key 4096
        fi

        # Buat CSR
        openssl req -new \
          -key ${sslDir}/homelab.key \
          -out ${sslDir}/homelab.csr \
          -config ${sslDir}/homelab.cnf

        # Sign cert — pakai -extensions v3_ext (bukan req_ext)
        # agar SAN benar-benar masuk ke cert yang dihasilkan
        openssl x509 -req \
          -in    ${sslDir}/homelab.csr \
          -CA    ${sslDir}/homelab-ca.crt \
          -CAkey ${sslDir}/homelab-ca.key \
          -set_serial "0x$(openssl rand -hex 8)" \
          -out   ${sslDir}/homelab.crt \
          -days 825 -sha256 \
          -extensions v3_ext \
          -extfile ${sslDir}/homelab.cnf

        # Simpan hash setelah berhasil
        echo "$CNF_HASH" > ${sslDir}/homelab.cnf.hash

        # Cleanup
        rm -f ${sslDir}/homelab.csr
      fi

      chmod 640 ${sslDir}/homelab.key
      chmod 644 ${sslDir}/homelab.crt
      chown root:caddy ${sslDir}/homelab.key
      chown root:root  ${sslDir}/homelab.crt
    '';
  };
}