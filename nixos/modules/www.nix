{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;
in
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "${node.domains.friikod}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.ladugard-live;
      };

      "${node.domains.ladugardlive}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.ladugard-live;
      };
    };
  };
}
