{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;

  user = "linus";
  group = "linus";
  bucketName = "jellyfinbucket";
in
{
  environment.systemPackages = [ pkgs.rclone ];

  # Create mount directory
  systemd.tmpfiles.rules = [
    "d /mnt/${bucketName} 0755 ${user} ${group} -"
    "d /var/log/rclone 0755 ${user} ${group} -"
  ];

  systemd.services.rclone-s3-mount = {
    description = "Rclone Mount for S3 Bucket (cloudflarer2:jellyfinbucket)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      Environment = "RCLONE_CONFIG=${config.age.secrets.rcloneConfig.path}";

      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount cloudflarer2:${bucketName} /mnt/${bucketName} \
          --allow-other \
          --default-permissions \
          --vfs-cache-mode full \
          --vfs-cache-max-size 1G \
          --vfs-cache-max-age 48h \
          --log-file /var/log/rclone/rclone.log \
          --log-level INFO
      '';

      ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/${bucketName}";

      Restart = "always";
      RestartSec = 10;
    };

    # Ensure mount directory exists
    unitConfig = {
      AssertPathIsDirectory = "/mnt/${bucketName}";
    };
  };

  age.secrets.rcloneConfig = {
    rekeyFile = ../${node.name}/secrets/rcloneConfig.age;
    generator.script = "passphrase";
  };
}
