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
    ./hetzvps/rekey.nix
    ./applications/calc-api.nix
    ./applications/auth-server.nix
    ./applications/mailserver.nix
    ./applications/nextcloud.nix
    ./applications/jellyfin.nix
    ./applications/keycloak.nix
    ./applications/wordpress.nix
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "25.05";
}
