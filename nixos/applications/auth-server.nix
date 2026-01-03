{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;

  port = 8000;

  startApp = pkgs.writeShellScriptBin "start-app" ''
    set -a
    PORT=${toString port} 
    SECRET_KEY=THIS_IS_TEST
    AUTH_ENDPOINT=keycloak.friikod.se/realms/auth-server/protocol/openid-connect

    ${pkgs.auth-server}/bin/auth_server
  '';

  user = "auth_server_user";
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
    ensureDatabases = [ "auth_server" ];
    ensureUsers = [
      {
        name = "auth_server";
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database         DBuser                           auth-method
      local all              all                              trust
      host  "auth_server"    "auth_server"  ::1/128           trust
      host  "auth_server"    "auth_server" 127.0.0.1/32       trust
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

  age.secrets."auth_server_environment" = {
    rekeyFile = ../${node.name}/secrets/auth_server_environment;
    generator.script = "passphrase";
  };
}
