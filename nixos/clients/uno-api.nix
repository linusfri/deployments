{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;
in
{
  age.secrets.unoapiDbpass = {
    rekeyFile = ../${node.name}/secrets/unoapi-dbpass.age;
    generator.script = "passphrase";
  };
}