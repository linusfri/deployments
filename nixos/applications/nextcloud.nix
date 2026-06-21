{
  config,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  services.linusfri.nextcloud = {
    enable = true;
    hostName = node.domains.nextcloud;
    adminpassFile = config.age.secrets.nextcloudAdminPass.path;

    s3 = {
      bucket = "nextcloudbucket";
      key = "4d23100824c5df222d14fc527c4b929a";
      secretFile = config.age.secrets.cloudflares3SecretKey.path;
      hostname = "912391589165daea759d3cdcea0c7ced.r2.cloudflarestorage.com";
      region = "auto";
    };
  };

  age.secrets.nextcloudAdminPass = {
    rekeyFile = ../servers/${node.name}/secrets/nextcloud_admin_pass.age;
    generator.script = "passphrase";
  };

  age.secrets.cloudflares3SecretKey = {
    rekeyFile = ../servers/${node.name}/secrets/cloudflares3_secret_key.age;
    generator.script = "passphrase";
  };

  
}
