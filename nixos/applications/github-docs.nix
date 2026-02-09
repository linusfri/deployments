{ pkgs, config, ... }:
let
  inherit (config.terraflake.input) node;
in
{
  services.nginx = {
    virtualHosts = {
      "${node.domains.github-docs}" = {
        forceSSL = true;
        enableACME = true;
        
        locations."/".root = pkgs.github-doc-sync;
        locations."/".index ="testing-conventions.html";
      };
    };
  };
}