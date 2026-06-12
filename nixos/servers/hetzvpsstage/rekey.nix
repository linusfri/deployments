{ config, ... }:
let
  root = ../../..;
in
{
  age.rekey = {
    # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGd3ksiZjGXEvqx0p6clQIJWdsM+QqkgT9rZG5FQgkC5";

    masterIdentities = import (root + /secrets/master-identity.nix);

    storageMode = "local";
    # Choose a directory to store the rekeyed secrets for this host.
    # This cannot be shared with other hosts. Please refer to this path
    # from your flake's root directory and not by a direct path literal like ./secrets
    localStorageDir = root + "/secrets/rekeyed/${config.networking.hostName}";
  };
}
