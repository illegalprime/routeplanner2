{ config, lib, pkgs, ...}:
with lib;
let
  cfg = config.services.routeplanner;
in
{
  options.services.routeplanner = {
    port = mkOption { type = types.int; default = 8989; };
    useSSL = mkOption { type = types.bool; default = true; };
    forceSSL = mkOption { type = types.bool; default = true; };
    virtualhost = mkOption { type = types.str; };
  };

  config = {
    services.nginx.virtualHosts."${cfg.virtualhost}" = {
      enableACME = cfg.useSSL;
      forceSSL = cfg.useSSL && cfg.forceSSL;
      locations."/" = {
        proxyPass = "http://localhost:${toString cfg.port}/";
        proxyWebsockets = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 cfg.port ];

    services.cloudflare-dyndns.records = [
      {
        type = "A";
        name = cfg.virtualhost;
        content = "@ip@";
        proxied = false;
      }
    ];
  };
}
