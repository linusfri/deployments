{ flake, name }:

{ config, pkgs, ... }:
let
  modulesFolderPath = ../../modules;
  root = ../../..;
  applicationsFolderPath = ../../applications;

  applicationFileNames = [
    "calc-api.nix"
    "privacy.nix"
    "mailserver.nix"
    "nextcloud.nix"
    "jellyfin.nix"
    "keycloak.nix"
    "wordpress.nix"
    "rclone-r2.nix"
    "github-docs.nix"
    "ladugardlive.nix"
    "handy-gleam.nix"
    "conversions.nix"
    "plantuml.nix"
  ];

  moduleFileNames = [
    "common.nix"
    "www.nix"
    "db.nix"
    "virtualisation.nix"
    "authorized-keys.nix"
    "nextcloud.nix"
  ];

  mkFullPaths = folderPath: fileNames: map (fileName: folderPath + "/${fileName}") fileNames;

in
{
  imports = [
    (import (root + /terraflake) name)
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    flake.inputs.arion.nixosModules.arion
    flake.inputs.mailserver.nixosModules.default
    ./rekey.nix
  ]
  ++ mkFullPaths applicationsFolderPath applicationFileNames
  ++ mkFullPaths modulesFolderPath moduleFileNames;

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "25.05";
}
