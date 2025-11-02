{ config, ... }: {
  age.rekey = {
    # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHLF6aEQIlwGnZHKH9M6g49eeRAxNkqHrFwu2LYHIhzY";

    masterIdentities = import ../../secrets/master-identity.nix; 

    storageMode = "local";
    # Choose a directory to store the rekeyed secrets for this host.
    # This cannot be shared with other hosts. Please refer to this path
    # from your flake's root directory and not by a direct path literal like ./secrets
    localStorageDir = ../.. + "/secrets/rekeyed/${config.networking.hostName}";
  };
}
