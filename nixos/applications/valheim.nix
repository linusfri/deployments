{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.terraflake.input) node;
in
{
  services.linusfri.valheim = {
    enable = true;
    envFilePath = config.age.secrets.valheimEnv.path;
  };
  age.secrets.valheimEnv = {
    rekeyFile = ../servers/${node.name}/secrets/valheim-env.age;
    generator.script = "passphrase";
  };
}
