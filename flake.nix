{
  nixConfig = {
    warn-dirty = false;
  };
  description = "Demo Terraflake deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    terraflake.url = "github:icetan/nixiform/terraflake";
    terraflake.inputs.nixpkgs.follows = "nixpkgs";

    # Encryption for secrets
    agenix.url = "github:ryantm/agenix";

    # NixOS version
    nixos.url = "github:NixOS/nixpkgs/24.05";

    lgl-site.url = "git+ssh://git@github.com/linusfri/ladugardLive";
  };

  outputs = { self, nixpkgs, nixos, flake-utils, terraflake, agenix, ... }@inputs:
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
            (import ./nixos/modules/overlay.nix { inherit (inputs) nixpkgs lgl-site; })
            # Add module that configures a generic monitor node
            (import ./nixos/vps1.nix name)
            agenix.nixosModules.default
          ];
        };
      };
    }

    // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # Some problems with opentofu so need to use `terraform` and it is
          # no longer free as in speach
          config.allowUnfree = true;
        };
      in
      {
        # Export Nix package set that terraflake should use to bootstrap itself
        terraflake = {
          pkgs = pkgs;
          provisioner = "terraform-local";
        };
        # Create development environment from ./devshell.nix
        devShells.default = import ./devshell.nix {
          inherit pkgs;
          inherit (terraflake.packages.${system}) terraflake;
          inherit (agenix.packages.${system}) agenix;
        };
      }
    ));
}
