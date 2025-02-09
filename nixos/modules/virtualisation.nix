{ config, pkgs, ... }:
let
  inherit (config.terraflake.input) node;
  config = "";
in

{
  users.users.root.extraGroups = [ "docker" ];

  virtualisation = {
    docker.enable = true;
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
