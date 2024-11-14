name:

{ config, pkgs, ... }: {
  imports = [
    (import ../terraflake name)

    ./modules/common.nix
    ./modules/www.nix
    ./modules/db.nix
    ./vps1/rekey.nix
  ];

  # Set the initial NixOS version, don't touch this after first
  # `$ terraflake push`
  system.stateVersion = "24.05";
}
