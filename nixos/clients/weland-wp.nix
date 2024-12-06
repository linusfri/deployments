{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  user = "weland";
  dbName = "weland";
  home = "/var/lib/${user}";
in
{
  users.extraUsers.${user} = {
    name = user;
    group = user;
    home = home;
    createHome = true;
    isSystemUser = true;
  };

  users.extraGroups."${user}" = {
    name = user;
  };
  
  services.mysql = {
    initialDatabases = [{ name = "${dbname}"; }];
    ensureDatabases = [dbname];
    ensureUsers = [
      {
        name = user;
        ensurePermissions = {
          "${dbname}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx = {
    virtualHosts."${node.domains.weland-wp}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8080";
      };
    };
  };
}