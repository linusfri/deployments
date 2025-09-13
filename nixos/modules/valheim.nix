{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.linusfri.valheim;
  types = lib.types;
in
{
  options = {
    services.linusfri.valheim = {
      enable = lib.mkEnableOption "Enable valheim service.";

      user = lib.mkOption {
        type = types.str;
        default = "valheim";
      };

      home = lib.mkOption {
        type = types.str;
        default = "/var/lib/${cfg.user}";
      };

      imageName = lib.mkOption {
        type = types.str;
        default = "ghcr.io/lloesche/valheim-server";
      };

      containerMountPath = lib.mkOption {
        type = types.str;
        default = "/opt/valheim";
      };

      envFilePath = lib.mkOption {
        type = types.str;
        default = "";
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
          "valheim".service = {
            image = cfg.imageName;
            restart = "always";
            volumes = [
              "${cfg.home}/config:/config"
              "${cfg.home}/data:${cfg.containerMountPath}"
            ];
            ports = [
              "2456-2458:2456-2458/udp"
              "9001:9001/tcp"
            ];
            env_file = [ cfg.envFilePath ];
            capabilities = {
              SYS_NICE = true;
            };
            stop_grace_period = "2m";
          };
        };
      };
    };

    networking.firewall = {
      allowedUDPPortRanges = [
        {
          from = 2456;
          to = 2458;
        }
      ];
      allowedTCPPorts = [ 9001 ];
    };
  };
}
