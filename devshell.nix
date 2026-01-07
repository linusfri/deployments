{
  pkgs,
  terraflake,
}:

let
  inherit (pkgs) mkShell;

  tofu = pkgs.opentofu;
in
mkShell {
  buildInputs = builtins.attrValues {
    inherit (pkgs)
      jq
      git
      agenix-rekey
      age
      mkpasswd
      bind
      ;
    inherit terraflake tofu;

    tokens = pkgs.writeShellScriptBin "tokens" ''
      echo '
        tokens_json=$(age -d -i $AGE_KEY $SECRETS)
        export DIGITALOCEAN_TOKEN="''${$(jq -r .digitalocean_token <<<"$tokens_json"):-""}";
        export TF_VAR_cloudflare_token="''${$(jq -r .cloudflare_token <<<"$tokens_json"):-""}";
        export HCLOUD_TOKEN="''${$(jq -r .hcloud_token <<<"$tokens_json"):-""}";
      '
    '';

    decryptTfState = pkgs.writeShellScriptBin "decrypt-tf-state" ''
      echo '
        tf_state=$(age -d -i $AGE_KEY $TF_STATE)

        if [[ ! -f terraform.tfstate ]]; then
          echo "$tf_state" > terraform.tfstate
        fi
      '
    '';
  };

  shellHook = ''
    export ROOT_DIR="$PWD";
    export SECRETS="$ROOT_DIR/secrets/tofu-tokens/tokens.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/rekeyed/master.age"
    export TF_STATE="$ROOT_DIR/secrets/tofu-tokens/tfstate.age"

    # Parallelize terraflake
    export NF_PAR=10

    echo '
    Provision infrastructure:

    $ source <(tokens)
    $ tofu init
    $ tofu apply

    Push configuration:

    $ terraflake push -r

    To edit encrypted secrets:

    $ agenix edit

    To decrypt terraform state:

    $ source <(decrypt-tf-state)
    '
  '';
}
