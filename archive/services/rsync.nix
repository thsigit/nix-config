/*
 * Status: Archived
 * Last used: 2026-07
 * Reason: Not currently needed; full rsync backup solution
 * Safe to delete after: 2026-10
 */

# modules/storage/rsync.nix

{ config, pkgs, ... }:

{
  services.rsync = {
    enable = true;
    package = pkgs.rsync;

    jobs = {

      # Backup /etc/nixos
      nixos-config = {
        sources = [ "/etc/nixos/" ];
        destination = "/mnt/datadisk/homelab/nixos/";
        user = "root";
        group = "root";
        settings = {
          archive = true;
          verbose = true;
          delete = true;
          compress = true;
        };
      };

      # Backup /srv
      srv-data = {
        sources = [ "/srv/" ];
        destination = "/mnt/datadisk/homelab/srv/";
        user = "root";
        group = "root";
        settings = {
          archive = true;
          verbose = true;
          delete = true;
        };
      };

      # Backup /home/sigit
      home-sigit = {
        sources = [ "/home/sigit/" ];
        destination = "/mnt/datadisk/homelab/home/sigit";
        user = "root";
        group = "root";
        settings = {
          archive = true;
          verbose = true;
          delete = true;
        };
      };

    };
  };
}
