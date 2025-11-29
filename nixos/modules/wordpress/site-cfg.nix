{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    appName = lib.mkOption {
      type = lib.types.str;
      description = "Application name";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "WordPress package to use";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to run WordPress as";
    };

    home = lib.mkOption {
      type = lib.types.path;
      description = "Home directory for the WordPress user";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the WordPress site";
    };

    dbName = lib.mkOption {
      type = lib.types.str;
      description = "Database name";
    };

    dbPrefix = lib.mkOption {
      type = lib.types.str;
      default = "wp_";
      description = "Database table prefix";
    };

    projectDir = lib.mkOption {
      type = lib.types.str;
      description = "Project directory name within the package";
    };

    environment = lib.mkOption {
      type = lib.types.enum [
        "development"
        "staging"
        "production"
      ];
      default = "production";
      description = "WordPress environment";
    };

    debug = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable WordPress debugging";
      };

      display = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Display debug output";
      };
    };

    ssl = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable ACME SSL certificates";
      };

      force = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Force SSL redirect";
      };
    };

    basicAuth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable basic authentication";
      };
    };

    assetProxy = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Asset proxy URL for production assets";
    };
  };
}
