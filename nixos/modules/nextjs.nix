{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.linusfri.nextjs;
  types = lib.types;
in
{
  options = {
    services.linusfri.nextjs = {
      enable = lib.mkEnableOption "Enable strapi service.";

      user = lib.mkOption {
        type = types.str;
        default = "nextuser";
      };

      home = lib.mkOption {
        type = types.str;
        default = "/var/lib/nextuser";
      };

      domainName = lib.mkOption {
        type = types.str;
        default = "";
      };

      port = lib.mkOption {
        type = types.port;
        default = 3000;
      };

      startScript = lib.mkOption {
        type = types.package;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      name = cfg.user;
      group = cfg.user;
      home = cfg.home;
      createHome = true;
      isSystemUser = true;
    };

    users.groups."${cfg.user}" = {
      name = cfg.user;
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
      next = lib.mkIf (cfg.startScript != null) {
        enable = true;
        description = "Start next app";
        serviceConfig = {
          ExecStart = "${cfg.startScript}/bin/start-next-app";
          Type = "simple";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  };

}
