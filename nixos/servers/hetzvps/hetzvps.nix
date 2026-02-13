{ flake, name }:

{ config, pkgs, ... }:
let
  modules = ../../modules;
  root = ../../..;
  applications = ../../applications;
in
{
  imports = [
    (import (root + /terraflake) name)
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    flake.inputs.arion.nixosModules.arion
    flake.inputs.mailserver.nixosModules.default
    ./rekey.nix
    (modules + /common.nix)
    (modules + /www.nix)
    (modules + /db.nix)
    (modules + /virtualisation.nix)
    (applications + /calc-api.nix)
    (applications + /privacy.nix)
    (applications + /mailserver.nix)
    (applications + /nextcloud.nix)
    (applications + /jellyfin.nix)
    (applications + /keycloak.nix)
    (applications + /wordpress.nix)
    (applications + /rclone-r2.nix)
    (applications + /github-docs.nix)
    (applications + /ladugardlive.nix)
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "25.05";
}
