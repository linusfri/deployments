{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.linusfri.nextcloud;
  types = lib.types;
in
{
  options = {
    services.linusfri.nextcloud = {
      enable = lib.mkEnableOption "Enable nextcloud service.";

      package = lib.mkOption {
        type = types.package;
        default = pkgs.nextcloud32;
        description = "The Nextcloud package to use.";
      };

      hostName = lib.mkOption {
        type = types.str;
        description = "The domain the Nextcloud instance is served from.";
      };

      dataDir = lib.mkOption {
        type = types.str;
        default = "/var/lib/nextcloud-data";
        description = "Directory holding the Nextcloud data.";
      };

      maxUploadSize = lib.mkOption {
        type = types.str;
        default = "50G";
        description = "Maximum upload size.";
      };

      adminpassFile = lib.mkOption {
        type = types.path;
        description = "Path to the file holding the admin password.";
      };

      s3 = {
        bucket = lib.mkOption {
          type = types.str;
          description = "Name of the S3 bucket used as primary object storage.";
        };

        key = lib.mkOption {
          type = types.str;
          description = "S3 access key id.";
        };

        secretFile = lib.mkOption {
          type = types.path;
          description = "Path to the file holding the S3 secret access key.";
        };

        hostname = lib.mkOption {
          type = types.str;
          description = "S3 endpoint hostname.";
        };

        region = lib.mkOption {
          type = types.str;
          default = "auto";
          description = "S3 region.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 nextcloud nextcloud -"
    ];

    services.nextcloud = {
      enable = true;
      package = cfg.package;
      database = {
        createLocally = true; # Uses socket authentication
      };
      config = {
        adminpassFile = cfg.adminpassFile;
        dbtype = "mysql";
      };
      settings = {
        log_type = "file";
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];
      };
      phpOptions = {
        "max_execution_time" = "3600";
        "max_input_time" = "3600";
      };
      fastcgiTimeout = 300;
      extraApps = {
        inherit (cfg.package.packages.apps)
          news
          contacts
          calendar
          tasks
          onlyoffice
          deck
          polls
          ;
        spreed = pkgs.fetchNextcloudApp {
          sha256 = "sha256:fe690208a194a08a91ba65481cbf9f3ca938cb434e91d56f93bd4cce4f3cf413";
          url = "https://github.com/nextcloud-releases/spreed/releases/download/v22.0.4/spreed-v22.0.4.tar.gz";
          license = "gpl3";
        };
      };
      datadir = cfg.dataDir;
      https = true;
      hostName = cfg.hostName;
      maxUploadSize = cfg.maxUploadSize;

      config.objectstore.s3 = {
        enable = true;
        bucket = cfg.s3.bucket;
        autocreate = false;
        key = cfg.s3.key;
        secretFile = cfg.s3.secretFile;
        hostname = cfg.s3.hostname;
        useSsl = true;
        port = 443;
        usePathStyle = false;
        region = cfg.s3.region;
      };
    };

    services.nginx.virtualHosts.${cfg.hostName} = {
      forceSSL = true;
      enableACME = true;
    };
  };
}
