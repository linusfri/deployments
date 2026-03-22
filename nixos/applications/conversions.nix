{
  config,
  pkgs,
  authorizedKeys,
  ...
}:
let
  inherit (config.terraflake.input) node;

  port = 8080;
  appName = "conversions";

  envFile = config.age.secrets."${appName}_environment".path;

  importDb = pkgs.writeShellScriptBin "import-db" ''
    echo "Importing initial data..."
  
    psql -U postgres -v data_path="${pkgs.conversions}/data" -d ${appName} < ${pkgs.conversions}/db/init/init.sql
  '';

  startApp = pkgs.writeShellScriptBin "start-app" ''
    set -a
    source ${envFile}
    BACKEND_APP_URL=${node.domains.conversions}
    FRONTEND_API_URL=${node.domains.conversions}
    STATIC_UPLOAD_PATH=${home}/static
    STATIC_SERVE_PATH=/static
    PORT=${toString port}
    PGHOST="/run/postgresql"

    ${pkgs.conversions}/bin/conversions
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
    isNormalUser = true;
    packages = [ importDb ];
  };

  users.extraGroups."${appName}" = {
    name = appName;
  };

  systemd.tmpfiles.rules = [
    "d ${home}/static 0755 ${appName} ${appName} -"
    "d ${home}/data 0755 ${appName} ${appName} -"
  ];


  users.users."nginx".extraGroups = [ "conversions" ];

  services.nginx = {
    virtualHosts."${node.domains.conversions}" = {
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
    after = [
      "postgresql.service"
      "postgresql-setup.service"
    ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = appName;
      Group = appName;
      WorkingDirectory = home;
    };

    script = ''
      export DATABASE_URL="postgres://${appName}@/${appName}?host=/run/postgresql&sslmode=disable"
      ${pkgs.dbmate}/bin/dbmate --migrations-dir ${pkgs.conversions}/db/migrations up
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."${appName}-frontend" = {
    enable = true;
    description = "Copy ${appName} frontend static files to ${home}/static";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      cp -rT ${pkgs.conversions-frontend}/ ${home}/static
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
    rekeyFile = (../servers/${node.name}/secrets/${appName} + ".age");
    generator.script = "passphrase";
    owner = appName;
    group = appName;
  };
}
