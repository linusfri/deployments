{ pkgs, config, ... }:
let
  inherit (config.terraflake.input) node;
in
{
  services.nginx = {
    virtualHosts = {
      "${node.domains.ladugardlive}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".root = pkgs.ladugard-live;
      };
    };
  };
}
