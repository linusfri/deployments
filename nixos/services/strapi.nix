{ pkgs, lib, config, ...}:
let
  cfg = config.services.linusfri.strapi;
in
{
  options = {
    services.linusfri.strapi = {
      enable = lib.mkEnableOption "Enable strapi service.";

      message = lib.mkOption {
        type = lib.types.string;
        default = "";
        example = "Hello world!";
      };
    };
  };

  config = {
    systemd.services.hello-strapi = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${cfg.message}";
    };
  };
}