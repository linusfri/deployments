{ config, pkgs, authorizedKeys, ... }:
let
  inherit (config.terraflake.input) node;

  port = 8000;
  appName = "handygleam";

  envFile = config.age.secrets."${appName}_environment".path;

  startApp = pkgs.writeShellScriptBin "start-app" ''
    set -a
    source ${envFile}
    PORT=${toString port}
    PGHOST="/run/postgresql"

    ${pkgs.handygleam}/bin/handygleam
  '';

  home = "/var/lib/${appName}";
in
{
  users.extraUsers.${appName} = {
    name = appName;
    group = appName;
    home = home;
    openssh.authorizedKeys.keys = authorizedKeys;
    createHome = true;
    isSystemUser = true;
  };

  users.extraGroups."${appName}" = {
    name = appName;
  };

  services.nginx = {
    virtualHosts."${node.domains.handygleam}" = {
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
        ensureDBOwnership = true;
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
    after = [ "postgresql.service" "postgresql-setup.service" ];
    requires = [ "postgresql.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = appName;
      Group = appName;
      WorkingDirectory = home;
    };

    script = ''
      export DATABASE_URL="postgres://${appName}@/${appName}?host=/run/postgresql&sslmode=disable"
      ${pkgs.dbmate}/bin/dbmate --migrations-dir ${pkgs.handygleam}/db/migrations up
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
      User = appName;
      Group = appName;
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets."${appName}_environment" = {
    rekeyFile = ../servers/${node.name}/secrets/${appName};
    generator.script = "passphrase";
    owner = appName;
    group = appName;
  };
}