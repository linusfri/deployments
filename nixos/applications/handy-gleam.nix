{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;

  port = 8000;
  appName = "handy-gleam";

  startApp = pkgs.writeShellScriptBin "start-app" ''
    set -a
    PORT=${toString port} 
    SECRET_KEY=THIS_IS_TEST
    AUTH_ENDPOINT=keycloak.friikod.se/realms/auth-server/protocol/openid-connect

    ${pkgs.auth-server}/bin/${appName}
  '';

  user = "${appName}_user";
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

  services.nginx = {
    virtualHosts."${node.domains.auth-server}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "${appName}" ];
    ensureUsers = [
      {
        name = "${appName}";
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type  database        DBuser                         auth-method
      local  all             all                            trust
      host  "${appName}"    "${appName}"  ::1/128           trust
      host  "${appName}"    "${appName}" 127.0.0.1/32       trust
    '';
  };

  systemd.services.auth-server = {
    enable = true;
    description = "auth-server";
    serviceConfig = {
      ExecStart = "${startApp}/bin/start-app";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets."${appName}_environment" = {
    rekeyFile = ../servers/${node.name}/secrets/${appName};
    generator.script = "passphrase";
  };
}
