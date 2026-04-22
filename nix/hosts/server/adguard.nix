# nix/hosts/server/adguard.nix
# AdGuard Home — network-wide DNS ad-blocker.
# Listens on all interfaces (LAN + Tailscale).
# Web UI: http://<server-ip>:3000
# DNS: <server-ip>:53
#
# After first deploy, open the Web UI to complete initial setup
# (create admin user and password).

{ ... }:

{
  services.adguardhome = {
    enable   = true;
    mutableSettings = true;  # Allow UI to persist config changes

    settings = {
      # --- DNS BIND ---
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port       = 53;

        # Upstream DNS servers (encrypted)
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
        ];

        # Bootstrap DNS (needed to resolve upstream DoH hostnames)
        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        # Rate limiting (queries per second per client, 0 = unlimited)
        ratelimit = 0;
      };

      # --- WEB UI ---
      http = {
        address = "0.0.0.0:3000";
      };

      # --- FILTERING ---
      filtering = {
        protection_enabled  = true;
        filtering_enabled   = true;
        safe_browsing_enabled = false;  # Optional, can enable via UI
        parental_enabled    = false;
      };

      filters = [
        # AdGuard DNS filter (default, comprehensive)
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"; name = "AdGuard DNS filter"; id = 1; }
        # AdAway default blocklist
        { enabled = true; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt"; name = "AdAway Default Blocklist"; id = 2; }
      ];
    };
  };

  # --- FIREWALL ---
  networking.firewall = {
    allowedTCPPorts = [ 53 3000 ];
    allowedUDPPorts = [ 53 ];
  };
}
