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

  systemd.services.auth-server = {
    enable = true;
    description = "auth-server";
    serviceConfig = {
      ExecStart = "${startApp}/bin/start-app";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };
}