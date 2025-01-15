{
  nixConfig = {
    warn-dirty = false;
    sandbox = "relaxed";
  };

  description = "Demo Terraflake deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    terraflake.url = "github:icetan/nixiform/terraflake";
    terraflake.inputs.nixpkgs.follows = "nixpkgs";

    # Encryption for secrets
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Bravomedia service templates
    templates.url = "git+ssh://git@bitbucket.org/bravomedia/templates";

    # NixOS version
    nixos.url = "github:NixOS/nixpkgs/release-24.11";

    lgl-site.url = "git+ssh://git@github.com/linusfri/ladugardLive";
    uno-api.url = "github:linusfri/uno_api";
    weland-wp.url = "git+ssh://git@bitbucket.org/bravomedia/weland-wp?rev=471d338d2f4584a9c31ed8c8fcc61b529d95a7e8";
    calc-api.url = "git+ssh://git@github.com/linusfri/calc_api";
  };

  outputs = { self, nixpkgs, nixos, flake-utils, terraflake, agenix, agenix-rekey, ... }@inputs:
    let
      tfvars = nixpkgs.lib.importJSON ./terraform.tfvars.json;
      # Architecture of the nodes
      system = "x86_64-linux";
      name = "vps1";
    in
    {
      # Attrset of NixOS configurations.
      nixosConfigurations = {
        ${name} = nixos.lib.nixosSystem {
          inherit system;
          modules = [
            # Add module for local package overlays
            (import ./nixos/modules/overlay.nix { inherit (inputs) nixpkgs lgl-site uno-api calc-api weland-wp; })
            # Add module that configures a generic monitor node
            (import ./nixos/vps1.nix { flake = self; inherit name; })
          ];
        };
      };

      # Setup agenix-rekey
      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nodes = self.nixosConfigurations // {
          tofuTokens = nixos.lib.nixosSystem {
            inherit system;
            modules = [
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
              ({ config, ... }:
              let
                name = "tofu-tokens";
              in
              {
                age.rekey = {
                  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAf9Wqvahm9Fm2twattmjSccCLsqpqMHrIft868NWaAd";
                  masterIdentities = import ./secrets/master-identity.nix;
                  storageMode = "local";
                  localStorageDir = ./. + "/secrets/rekeyed/${name}";
                };
                age.secrets.tokens.rekeyFile = ./secrets/${name}/tokens.json.age;
              })
            ];
          };
        };
        # Use age instead of rage
        agePackage = p: p.age;
      };
    }

    // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ agenix-rekey.overlays.default ];
        };
      in
      {
        # Export Nix package set that terraflake should use to bootstrap itself
        terraflake = {
          pkgs = pkgs;
          # provisioner = "terraform-local";
        };
        # Create development environment from ./devshell.nix
        devShells.default = import ./devshell.nix {
          inherit pkgs;
          inherit (terraflake.packages.${system}) terraflake;
        };
      }
    ));
}
