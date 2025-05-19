{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  meiliPort = config.services.meilisearch.listenPort;
in
{
  services.meilisearch.enable = true;

  services.nginx = {
    virtualHosts."${node.domains.meili}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString meiliPort}";
      };
    };
  };
}