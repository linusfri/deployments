{ pkgs
, terraflake
, agenix
}:

let
  inherit (pkgs) mkShell;

  terraform = pkgs.terraform.withPlugins
    (ps: builtins.attrValues {
      inherit (ps) digitalocean cloudflare;
    });
in
mkShell rec {
  buildInputs = builtins.attrValues {
    inherit (pkgs) jq git;
    inherit terraflake agenix terraform;

    editSecret = pkgs.writeShellScriptBin "editSecret" ''
      ( cd $(dirname $SECRETS);
        ${agenix}/bin/agenix ''${1:--e} $(basename $SECRETS) -i "$AGE_KEY"
      )
    '';
  };

  shellHook = ''
    export ROOT_DIR="$PWD";
    export SECRETS="$ROOT_DIR/secrets/secrets.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/age-key"

    secret() { (editSecret -d | jq -r "$*") || true; }

    export DIGITALOCEAN_TOKEN="''${DIGITALOCEAN_TOKEN:-$(secret .digitalocean_token)}"
    export CLOUDFLARE_API_TOKEN="''${CLOUDFLARE_API_TOKEN:-$(secret .cloudflare_token)}"
    # Parallelize terraflake
    export NF_PAR=10

    echo '
    Provision infrastructure:

    $ terraform init
    $ terraform apply

    Push configuration:

    $ terraflake push -r

    To edit encrypted secrets:

    $ editSecret
    '
  '';
}
