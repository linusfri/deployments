{ flake, name }:

{ config, pkgs, ... }: {
  imports = [
    (import ../terraflake name)
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    flake.inputs.arion.nixosModules.arion
    flake.inputs.mailserver.nixosModules.default
    ./modules/common.nix
    ./modules/www.nix
    ./modules/db.nix
    ./modules/virtualisation.nix
    ./modules/strapi.nix
    ./modules/nextjs.nix
    ./modules/plex.nix
    ./modules/valheim.nix
    ./hetzvps/rekey.nix
    ./applications/calc-api.nix
    ./applications/auth-server.nix
    ./applications/mailserver.nix
    ./applications/nextcloud.nix
    ./applications/jellyfin.nix
    ./applications/valheim.nix
    # (import ./applications/strapi.nix { imageName = "ghcr.io/linusfri/strapi-master:${pkgs.strapiHashProd}"; })
    # ./applications/next.nix
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "24.11";
}
