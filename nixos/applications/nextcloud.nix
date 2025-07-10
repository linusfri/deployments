{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.terraflake.input) node;

  mountPath =
    if config.services.nextcloud.enable == true then
      config.services.nextcloud.datadir
    else
      "/var/lib/nextcloud-data";

  diskPathAndUuid = "/dev/disk/by-uuid/9930cf1b-b4b5-44f9-8b10-fbb22b14740f";
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
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
    fastcgiTimeout = 3600;
    datadir = "/var/lib/nextcloud-data";
    https = true;
    hostName = node.domains.nextcloud;
    maxUploadSize = "50G";
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  fileSystems."${mountPath}" = {
    device = diskPathAndUuid;
    fsType = "ext4";
  };

  age.secrets.nextcloudAdminPass = {
    rekeyFile = ../${node.name}/secrets/nextcloud_admin_pass.age;
    generator.script = "passphrase";
  };
}
