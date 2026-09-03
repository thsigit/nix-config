# common/ap/opennds.nix
{ config, pkgs, lib, opennds, ... }:

let
  defaults = import ../../settings;
  inherit (defaults.ap) interface gatewayName;

  openndsPkg = pkgs.callPackage opennds { };

  cfg = config.services.opennds;

  # NOTE: fwhook_enabled is '0' (captive portal BYPASSED). openNDS 11 nft client-
  # tracking (nds_mangle/ndsOUT) conflicts with the base system iptables-compat
  # NAT (networking.nat), leaving mangle empty and rejecting all pre-auth traffic.
  # fwhook_enabled '0' makes openNDS transparent and delegates firewall/NAT to
  # NixOS so AP clients get internet. Set '1' only after the hybrid nft/iptables
  # issue is fixed (see OPENNDS-DEBUG-NOTE.md).

  # Generate the UCI-style config file. faskey is omitted here and appended at
  # runtime (see systemd.services.opennds.preStart) so it is never baked into
  # the Nix store.
  configFile = pkgs.writeText "opennds" ''
    config opennds 'setup'
        option enabled '1'
        option debuglevel '${toString cfg.debugLevel}'
        option gatewayinterface '${cfg.interface}'
        option gatewayname '${cfg.gatewayName}'
        option gatewayport '2050'
        option maxclients '${toString cfg.maxClients}'
        option sessiontimeout '${toString cfg.sessionTimeout}'
        option preauthidletimeout '30'
        option authidletimeout '120'
        option checkinterval '15'
        option login_option_enabled '${toString cfg.loginOption}'
        option themespec_path '/usr/lib/opennds/theme_voucher.sh'
        option allow_preemptive_authentication '1'
        option webroot '/etc/opennds/htdocs'
        option binauth '/usr/lib/opennds/binauth_log.sh'
        option custombinauth '/srv/appdata/opennds/binauth-voucher.sh'
        option fwhook_enabled '0'
        option dhcp_default_url_enable '1'
        option enable_serial_number_suffix '1'
        option dhcp_leases_file '/var/lib/dnsmasq/dnsmasq.leases'
  '';
in
{
  options.services.opennds = {
    interface = lib.mkOption {
      type = lib.types.str;
      default = interface;
      description = "Network interface for the captive portal";
    };
    gatewayName = lib.mkOption {
      type = lib.types.str;
      default = gatewayName;
      description = "Name displayed on the captive portal";
    };
    debugLevel = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Debug level (0-3)";
    };
    maxClients = lib.mkOption {
      type = lib.types.int;
      default = 250;
      description = "Maximum number of clients";
    };
    sessionTimeout = lib.mkOption {
      type = lib.types.int;
      default = 1440;
      description = "Session timeout in minutes (0 = no timeout)";
    };
    loginOption = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Login option (0 = click to continue, 1 = click+info, 2 = username/email, 3 = custom theme)";
    };
  };

  # Gated on the bundle switch (services.ap.enable) like the other ap modules,
  # so removing/commenting any one module leaves the rest building. Runtime data
  # lives under /srv/appdata/opennds; secrets come from sops.
  #
  # NOTE: this must NOT use system.activationScripts — that was the confirmed
  # trigger of the "no usable init" boot failure (see freeradius.nix history).
  # Instead, all setup (resource copy + config write with faskey) runs in the
  # opennds.service preStart, which executes after boot and after sops secrets
  # are decrypted.
  config = lib.mkIf config.services.ap.enable {
    environment.systemPackages = [ openndsPkg ];

    systemd.services.opennds = {
      description = "openNDS Captive Portal";
      after = [ "network-online.target" "hostapd.service" "dnsmasq.service" ];
      wants = [ "network-online.target" ];
      requires = [ "hostapd.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ opennds ] ++ (with pkgs; [
        coreutils
        gawk
        gnugrep
        gnused
        procps
        inetutils
        kmod
        iproute2
        iptables
        nftables
        bash
        curl
        wget
        dnsmasq
      ]) ++ [ "${openndsPkg}/lib/opennds" ];

      # PreStart does all runtime setup that used to live in an activation
      # script: copy static splash/theme/shell resources into place and write
      # /etc/config/opennds with the sops-decrypted faskey. Runs as root right
      # before the daemon starts (after boot + sops activation), is idempotent
      # (re-copy/rewrite are harmless), and avoids touching the activation path
      # that caused the boot failure.
      preStart = ''
        set -euo pipefail

        mkdir -p /tmp/opennds /tmp/ndslog
        mkdir -p /etc/opennds/htdocs/images
        mkdir -p /usr/lib/opennds
        mkdir -p /etc/config
        mkdir -p /run/ndscids

        # Copy custom binauth script (may not exist yet -> tolerate)
        cp -f /srv/appdata/opennds/binauth-voucher.sh /usr/lib/opennds/binauth-voucher.sh 2>/dev/null || true
        chmod +x /usr/lib/opennds/binauth-voucher.sh 2>/dev/null || true

        # Copy custom voucher theme (may not exist yet -> tolerate)
        cp -f /srv/appdata/opennds/theme_voucher.sh /usr/lib/opennds/theme_voucher.sh 2>/dev/null || true
        chmod +x /usr/lib/opennds/theme_voucher.sh 2>/dev/null || true

        # Copy splash resources
        cp -f ${openndsPkg}/etc/opennds/htdocs/splash.css /etc/opennds/htdocs/ 2>/dev/null || true
        cp -f ${openndsPkg}/etc/opennds/htdocs/images/splash.jpg /etc/opennds/htdocs/images/ 2>/dev/null || true

        # Copy shell scripts
        for script in ${openndsPkg}/lib/opennds/*; do
          cp -f "$script" /usr/lib/opennds/
          chmod +x "/usr/lib/opennds/$(basename "$script")"
        done

        # Create symlink for theme script the C binary expects.
        # ndscfg/ndsctl are already on PATH via the package (bin/ndsctl wrapper
        # + ndscfg in lib/opennds); do NOT symlink into /usr/local/bin — NixOS
        # has no /usr/local/bin and it aborted the whole activation script.
        ln -sf theme_click-to-continue-basic.sh /usr/lib/opennds/theme_click-to-continue.sh

        # Write config with the runtime faskey from sops
        cat ${configFile} > /etc/config/opennds
        cat >> /etc/config/opennds << FASKY
            option faskey '$(cat ${config.sops.secrets."opennds-faskey".path})'
FASKY
      '';

      serviceConfig = {
        # Run in foreground (-f); systemd tracks the process directly.
        Type = "exec";
        ExecStart = "${openndsPkg}/bin/opennds -f";
        ExecStop = "${openndsPkg}/bin/ndsctl stop";
        Restart = "on-failure";
        RestartSec = 20;
        StartLimitIntervalSec = 30;
        StartLimitBurst = 5;
        RuntimeDirectory = "opennds";
        RuntimeDirectoryMode = "0755";
      };
    };

    systemd.tmpfiles.rules = [
      "d /run/ndscids 0755 root root -"
      "d /tmp/opennds 0755 root root -"
      "d /srv/appdata/opennds 0755 root root -"
      "d /tmp/ndslog 0755 root root -"
    ];
  };
}
