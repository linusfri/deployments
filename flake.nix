{
  nixConfig = {
    warn-dirty = false;
    sandbox = "relaxed";
  };

  description = "Demo Terraflake deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    # terraflake.url = "github:icetan/nixiform?rev=1e237a2d806cd303ef308626a6a63ae963bbe056";
    terraflake.url = "github:icetan/nixiform";
    terraflake.inputs.nixpkgs.follows = "nixpkgs";

    # Encryption for secrets
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # Arion
    arion.url = "github:hercules-ci/arion";

    # NixOS version
    nixos.url = "github:NixOS/nixpkgs/release-25.05";

    lgl-site.url = "git+ssh://git@github.com/linusfri/ladugardLive";
    strapi = {
      url = "git+ssh://git@github.com/linusfri/strapi_docknix";
    };
    uno-api.url = "github:linusfri/uno_api";
    calc-api.url = "git+ssh://git@github.com/linusfri/calc_api";
    auth-server.url = "git+ssh://git@github.com/linusfri/Gleam-auth-server";

    # Mail
    mailserver.url = "git+https://gitlab.com/simple-nixos-mailserver/nixos-mailserver.git";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos,
      flake-utils,
      terraflake,
      agenix,
      agenix-rekey,
      ...
    }@inputs:
    let
      tfvars = nixpkgs.lib.importJSON ./terraform.tfvars.json;
      # Architecture of the nodes
      system = "x86_64-linux";
      name = "hetzvps";
    in
    {
      # Attrset of NixOS configurations.
      nixosConfigurations = {
        ${name} = nixos.lib.nixosSystem {
          inherit system;
          modules = [
            # Add module for local package overlays
            (import ./nixos/modules/overlay.nix {
              inherit (inputs)
                nixpkgs
                lgl-site
                uno-api
                calc-api
                auth-server
                strapi
                ;
            })
            # Add module that configures a generic monitor node
            (import ./nixos/hetzvps.nix {
              flake = self;
              inherit name;
            })
          ];
        };
      };

      # Setup agenix-rekey
      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations // {
          tofuTokens = nixos.lib.nixosSystem {
            inherit system;
            modules = [
              agenix.nixosModules.default
              agenix-rekey.nixosModules.default
              (
                { config, ... }:
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
                }
              )
            ];
          };
        };
        # Use age instead of rage
        agePackage = p: p.age;
      };
    }

    // (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ agenix-rekey.overlays.default ];
        };
      in
      {
        # Create development environment from ./devshell.nix
        devShells.default = import ./devshell.nix {
          inherit pkgs;
          inherit (terraflake.packages.${system}) terraflake;
        };
      }
    ));
}
