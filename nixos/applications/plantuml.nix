{ pkgs, config, ... }:
let
  inherit (config.terraflake.input) node;

  user = "plantuml";
  group = "plantuml";
  home = "/var/lib/plantuml";
  listenPort = 9090;
in
{
  services.plantuml-server = {
    enable = true;
    inherit group user home listenPort;
  };

   services.nginx = {
    virtualHosts."${node.domains.plantuml}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        return = "301 /plantuml/";
      };
      locations."/plantuml/" = {
        proxyPass = "http://127.0.0.1:${toString listenPort}/plantuml/";
      };
    };
  };
}
