{
  pkgs,
  config,
  ...
}:
let
  inherit (config.terraflake.input) node;

  dataDir = "/var/lib/nextcloud-data";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 nextcloud nextcloud -"
  ];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    database = {
      createLocally = true; # Uses socket authentication
    };
    config = {
      adminpassFile = config.age.secrets.nextcloudAdminPass.path;
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
      inherit (config.services.nextcloud.package.packages.apps)
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
    datadir = dataDir;
    https = true;
    hostName = node.domains.nextcloud;
    maxUploadSize = "50G";

    config.objectstore.s3 = {
      enable = true;
      bucket = "nextcloudbucket";
      autocreate = false;
      key = "4d23100824c5df222d14fc527c4b929a";
      secretFile = config.age.secrets.cloudflares3SecretKey.path;
      hostname = "912391589165daea759d3cdcea0c7ced.r2.cloudflarestorage.com";
      useSsl = true;
      port = 443;
      usePathStyle = false;
      region = "auto";
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  age.secrets.nextcloudAdminPass = {
    rekeyFile = ../${node.name}/secrets/nextcloud_admin_pass.age;
    generator.script = "passphrase";
  };

  age.secrets.cloudflares3SecretKey = {
    rekeyFile = ../${node.name}/secrets/cloudflares3_secret_key.age;
    generator.script = "passphrase";
  };
}
