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
    ./clients/uno-api.nix
    ./clients/calc-api.nix
    ./clients/enshrouded.nix
    ./vps1/rekey.nix
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "24.05";
}
