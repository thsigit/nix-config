# commons/monitoring/cockpit.nix
# Cockpit web console on port 9090.
# TLS: cockpit's certificate-ensure wipes custom certs from ws-certs.d, so we
# force-recreate the homelab cert symlinks with tmpfiles L+ (recreated every boot).

{ config, lib, pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "L+ /etc/cockpit/ws-certs.d/50-homelab.cert - - - - /etc/ssl/homelab/homelab.crt"
    "L+ /etc/cockpit/ws-certs.d/50-homelab.key  - - - - /etc/ssl/homelab/homelab.key"
  ];
  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        ClientCertAuthentication = true;
        AllowUnencrypted = false;
        Origins = lib.mkForce "https://homelab.home.arpa:9090";
      };
    };
    plugins = [ pkgs.cockpit-files pkgs.cockpit-podman ];
  };
}
