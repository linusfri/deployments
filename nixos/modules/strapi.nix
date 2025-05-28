{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.linusfri.strapi;
  types = lib.types;
in
{
  options = {
    services.linusfri.strapi = {
      enable = lib.mkEnableOption "Enable strapi service.";

      user = lib.mkOption {
        type = types.str;
        default = "strapiuser";
      };

      home = lib.mkOption {
        type = types.str;
        default = "/var/lib/strapiuser";
      };

      imageName = lib.mkOption {
        type = types.str;
        default = "latest";
      };

      databaseName = lib.mkOption {
        type = types.str;
        default = "strapi";
      };

      domainName = lib.mkOption {
        type = types.str;
        default = "strapi";
      };

      port = lib.mkOption {
        type = types.port;
        default = 1337;
      };

      dockerLogin = lib.mkOption {
        type = types.nullOr types.package;
        default = null;
      };

      generateEnv = lib.mkOption {
        type = types.nullOr types.package;
        default = null;
      };

      containerMountPath = lib.mkOption {
        type = types.str;
        default = "/opt/app";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      name = cfg.user;
      group = cfg.user;
      home = cfg.home;
      # extraGroups = [
      #   "wheel"
      #   "docker"
      # ];
      createHome = true;
      isSystemUser = true;
    };

    users.groups."${cfg.user}" = {
      name = cfg.user;
    };

    virtualisation.arion = {
      projects = {
        "app".settings.services = {
          "strapi".service = {
            image = cfg.imageName;
            restart = "unless-stopped";
            volumes = [
              "/var/lib/${cfg.user}/.env:${cfg.containerMountPath}/.env"
            ];
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
          name = cfg.user;
        }
      ];
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser                     auth-method
        local all       all                        trust
        host  strapi    ${cfg.user}  ::1/128       trust
        host  strapi    ${cfg.user}  127.0.0.1/32  trust
      '';
    };

    services.nginx = {
      virtualHosts = {
        "${cfg.domainName}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };
        };
      };
    };

    systemd.services = {
      docker-login = lib.mkIf (cfg.dockerLogin != null) {
        enable = true;
        description = "Log in to docker registry";
        serviceConfig = {
          ExecStart = "${cfg.dockerLogin}/bin/docker-login";
          Type = "simple";
        };
        wantedBy = [ "multi-user.target" ];
      };

      generateEnv = lib.mkIf (cfg.generateEnv != null) {
        enable = true;
        description = "Generates .env";
        serviceConfig = {
          ExecStart = "${cfg.generateEnv}/bin/generate-env";
          Type = "simple";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
