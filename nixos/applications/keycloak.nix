{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  services.keycloak = {
    enable = true;
    database = {
      passwordFile = config.age.secrets.keycloakDbPassFile.path;
    };
    settings = {
      hostname = "keycloak.friikod.se";
      http-port = 9090;
      https-port = 9443;
    };
  };

  age.secrets."keycloakDbPassFile" = {
    rekeyFile = ../${node.name}/secrets/keycloak-db-pass-file.age;
    generator.script = "passphrase";
  };
}
