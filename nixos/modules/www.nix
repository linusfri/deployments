{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;
in
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "${node.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.mjaumjau-site;
      };
    };
  };
}
