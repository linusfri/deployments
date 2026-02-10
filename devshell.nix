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
      tokens_json=$(age -d -i $AGE_KEY $SECRETS)

      # Format: "json_key:ENV_VAR_NAME"
      # The selector in the json file comes first
      # and then the actual variable name to export
      variable_pairs_to_export=(
        "cloudflare_token:TF_VAR_cloudflare_token"
        "hcloud_token:HCLOUD_TOKEN"
        "aws_access_key_id:AWS_ACCESS_KEY_ID"
        "aws_secret_access_key:AWS_SECRET_ACCESS_KEY"
        "aws_region:AWS_REGION"
      )

      # Overwrite the file each time this is run
      > $ROOT_DIR/.tokens.sh

      for pair in "''${variable_pairs_to_export[@]}"; do
        json_key="''${pair%%:*}"
        env_var="''${pair##*:}"
        value=$(jq -r ".$json_key // \"\"" <<<"$tokens_json")
        echo "export $env_var=\"$value\"" >> $ROOT_DIR/.tokens.sh
      done

      echo "Tokens exported to .tokens.sh"
    '';

    setEnvironment = pkgs.writeShellScriptBin "set-environment" ''
      GREEN="\033[0;32m"
      RED="\033[0;31m"
      RESET="\033[0m"

      if [[ -f "$ROOT_DIR/.tokens.sh" ]]; then
        echo -e "''${GREEN}.tokens.sh found, setting environment.''${RESET}"
        source $ROOT_DIR/.tokens.sh
      else
        echo -e "''${RED}.tokens.sh not found, run 'tokens''${RESET}"
      fi
    '';
  };

  shellHook = ''
    export ROOT_DIR="$PWD";
    export SECRETS="$ROOT_DIR/secrets/tofu-tokens/tokens.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/rekeyed/master.age"

    # Parallelize tofuflake
    export NF_PAR=10

    # Set environment if .tokens.sh exists
    source set-environment

    echo '
    Provision infrastructure:

    $ tokens
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
