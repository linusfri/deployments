{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit ( config.terraflake.input ) node;
in
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "linus";
    group = "linus";
  };

  services.nginx = {
    virtualHosts."${node.domains.jellyfin}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString 8096}";
      };
    };
  };
}
