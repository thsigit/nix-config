# modules/mail/default.nix
# Mailpit: local SMTP sink + web UI for testing outbound mail.
# SMTP sink at 127.0.0.1:1025, UI at mailpit.home.arpa.

{ ... }:
{
  services.mailpit.instances.default = {
    smtp = "127.0.0.1:1025";
    listen = "127.0.0.1:8025";
  };
  services.caddy.services.mailpit = { port = 8025; };
}
