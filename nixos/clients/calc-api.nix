{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  port = 8081;

  startApp = pkgs.writeShellScriptBin "start-app" ''
    PORT=${toString port} ${pkgs.calc-api}/bin/calc_api
  '';

  user = "calc_api_user";
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
    virtualHosts."${node.domains.calc-api}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
      };
    };
  };

  systemd.services.calc-api = {
    enable = true;
    description = "uno-api";
    serviceConfig = {
      ExecStart = "${startApp}/bin/start-app";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };
}