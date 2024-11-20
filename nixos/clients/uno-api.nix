{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  startApp = pkgs.writeShellScriptBin "start-app" ''
    DATABASE_URL=$(cat ${config.age.secrets.database-url.path}) ${pkgs.uno-api}/bin/uno_api
  '';
in
{
  services.mysql = {
    initialDatabases = [{ name = "uno"; }];
    ensureDatabases = ["uno"];
    ensureUsers = [
      {
        name = "uno_user";
        ensurePermissions = {
          "uno.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx = {
    virtualHosts."${node.domains.uno-api}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8080";
      };
    };
  };

  systemd.services.uno-api = {
    enable = true;
    description = "uno-api";
    serviceConfig = {
      ExecStart = "${startApp}/bin/start-app";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets.database-url = {
    rekeyFile = ../${node.name}/secrets/unoapi-dburl.age;
  };

  age.secrets.database-password = {
    rekeyFile = ../${node.name}/secrets/unoapi-dbpass.age;
    generator.script = "passphrase";
  };

  age.secrets.app-thing = {
    rekeyFile = ../${node.name}/secrets/app-thing.age;
    generator.script = "passphrase";
  };

}