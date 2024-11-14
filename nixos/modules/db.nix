{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node nodes;
in
{
  services.mysql = {
    enable = true;

    package = pkgs.mysql84;
  };
}
