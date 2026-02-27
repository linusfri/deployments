{ pkgs, config, ... }:
let
  inherit (config.terraflake.input) node;

  conversions-frontend = pkgs.conversions-frontend.overrideAttrs (
    finalAttrs: previousAttrs: {
      apiUrl = "https://something.friikod.se";
    }
  );
in
{
  services.nginx = {
    virtualHosts = {
      "${node.domains.github-docs}" = {
        forceSSL = true;
        enableACME = true;

        locations."/".root = pkgs.github-doc-sync;
        locations."/".index = "testing-conventions.html";
      };
    };
    virtualHosts = {
      "${node.domains.conversions}" = {
        forceSSL = true;
        enableACME = true;

        locations."/".root = conversions-frontend;
        locations."/".index = "index.html";
      };
    };
  };
}
