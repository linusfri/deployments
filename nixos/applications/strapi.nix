{
  imageVersion ? "latest",
}:
{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;

  user = "strapi_user";
  home = "/var/lib/${user}";

  dockerLogin = pkgs.writeShellScriptBin "docker-login" ''
    PATH="${pkgs.lib.makeBinPath [ pkgs.docker ]}:$PATH"
    GHCR_PASS=$(cat ${config.age.secrets.ghcrPass.path})
    docker login ghcr.io -u linusfri -p "$GHCR_PASS"

    if [[ $? == 0 ]]; then
      echo "Docker login succeded for linusfri."
      exit 0
    fi
  '';
in
{
  users.users.${user} = {
    name = user;
    group = user;
    home = home;
    extraGroups = [
      "wheel"
      "docker"
    ];
    createHome = true;
    isSystemUser = true;
  };

  users.groups."${user}" = {
    name = user;
  };

  virtualisation.arion = {
    projects = {
      "app".settings.services = {
        "strapi".service = {
          image = "ghcr.io/linusfri/strapi:${imageVersion}";
          restart = "unless-stopped";
          environment = {
            DATABASE_CLIENT = "postgres";
            DATABASE_HOST = "localhost";
            DATABASE_PORT = "5432";
            DATABASE_NAME = "strapi";
            DATABASE_USERNAME = "${user}";
            DATABASE_SSL = "false";
            DATABASE_FILENAME = "";
          };
          network_mode = "host";
        };
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "strapi" ];
    ensureUsers = [
      {
        name = user;
        ensureClauses = {
          superuser = true;
        };
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser                 auth-method
      local all       all                    trust
      host  all       all     ::1/128        trust
      host  all       all     127.0.0.1/32   trust
    '';
  };

   services.nginx = {
    virtualHosts."${node.domains.strapi}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString 1337}";
      };
    };
  };

  systemd.services.docker-login = {
    enable = true;
    description = "Log in to ghcr.io";
    serviceConfig = {
      ExecStart = "${dockerLogin}/bin/docker-login";
      Type = "simple";
    };
    wantedBy = [ "multi-user.target" ];
  };

  age.secrets.ghcrPass = {
    rekeyFile = ../${node.name}/secrets/ghcr_pass.age;
    generator.script = "passphrase";
  };

  age.secrets.dbPass = {
    rekeyFile = ../${node.name}/secrets/db_pass.age;
    generator.script = "passphrase";
  };
}
