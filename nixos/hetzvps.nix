{ flake, name }:

{ config, pkgs, ... }: {
  imports = [
    (import ../terraflake name)
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    flake.inputs.arion.nixosModules.arion
    ./modules/common.nix
    ./modules/www.nix
    ./modules/db.nix
    ./modules/virtualisation.nix
    ./applications/calc-api.nix
    ./applications/auth-server.nix
    # (import ./applications/strapi.nix { imageVersion = flake.inputs.strapi.rev; })
    ./hetzvps/rekey.nix
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "24.11";
}
