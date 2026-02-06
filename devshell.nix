{
  pkgs,
  terraflake,
}:

let
  inherit (pkgs) mkShell;

  tofu = pkgs.opentofu;
  scripts = (import ./scripts/tofuFlake.nix { inherit pkgs; });
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
    inherit (scripts)
      exportVars
      cleanup
      fetchTofuState
      tofuFlake
      tofuAge
      ;

    tokens = pkgs.writeShellScriptBin "tokens" ''
      echo '
        tokens_json=$(age -d -i $AGE_KEY $SECRETS)
        export DIGITALOCEAN_TOKEN="''${$(jq -r .digitalocean_token <<<"$tokens_json"):-""}";
        export TF_VAR_cloudflare_token="''${$(jq -r .cloudflare_token <<<"$tokens_json"):-""}";
        export HCLOUD_TOKEN="''${$(jq -r .hcloud_token <<<"$tokens_json"):-""}";
        export AWS_ACCESS_KEY_ID="''${$(jq -r .aws_access_key_id <<<"$tokens_json"):-""}";
        export AWS_SECRET_ACCESS_KEY="''${$(jq -r .aws_secret_access_key <<<"$tokens_json"):-""}";
        export AWS_REGION="''${$(jq -r .aws_region <<<"$tokens_json"):-""}";
      '
    '';
  };

  shellHook = ''
    export ROOT_DIR="$PWD";
    export SECRETS="$ROOT_DIR/secrets/tofu-tokens/tokens.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/rekeyed/master.age"
    export TF_DATA_DIR="$ROOT_DIR/opentofu/.terraform"

    # Parallelize tofuflake
    export NF_PAR=10

    echo '
    Provision infrastructure:

    $ source <(tokens)
    $ tofu init
    $ tofu apply

    Push configuration:

    $ tofuflake push -r

    To edit encrypted secrets:

    $ tofuAge edit

    # Reason for tofuFlake and tofuAge is that we need remote tofu state for terraflake to see.
    '
  '';
}
