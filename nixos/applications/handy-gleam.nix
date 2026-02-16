{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;

  port = 8000;
  appName = "handy-gleam";

  envFile = config.age.secrets."${appName}_environment".path;

  startApp = pkgs.writeShellScriptBin "start-app" ''
    set -a
    source ${envFile}
    PORT=${toString port}

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

  systemd.services."${appName}-migrate" = {
    enable = true;
    description = "Run database migrations for ${appName}";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "${appName}";
      Group = "${appName}";
      WorkingDirectory = home;
    };

    environment = {
      PGHOST = "/run/postgresql";
    };

    script = ''
      export DATABASE_URL="postgres://${appName}@/${appName}?host=/run/postgresql&sslmode=disable"
      ${pkgs.dbmate}/bin/dbmate up
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."${appName}" = {
    enable = true;
    description = "${appName}";
    after = [ "${appName}-migrate.service" ];
    requires = [ "${appName}-migrate.service" ];
    
    serviceConfig = {
      ExecStart = "${startApp}/bin/start-app";
      Type = "simple";
      User = user;
      Group = user;
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets."${appName}_environment" = {
    rekeyFile = ../servers/${node.name}/secrets/${appName};
    generator.script = "passphrase";
  };
}
