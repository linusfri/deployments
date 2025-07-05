{pkgs, config, lib, ...}:
let
  inherit (config.terraflake.input) node;
in
{
  services.linusfri.plex = {
    enable = true;
    domain = node.domains.plex;
  };
}