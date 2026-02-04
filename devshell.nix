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

    ensureGitHooks = pkgs.writeShellScriptBin "ensure-git-hooks" ''
      if git rev-parse --git-dir >/dev/null 2>&1; then
        repo_root="$(git rev-parse --show-toplevel)"
        hooks_path="$repo_root/.githooks"
        current_hooks_path="$(git config --get core.hooksPath || true)"
        if [[ -z "$current_hooks_path" ]]; then
          git config core.hooksPath "$hooks_path"
        elif [[ "$current_hooks_path" != "$hooks_path" ]]; then
          git config core.hooksPath "$hooks_path"
        fi
      fi
    '';
  };

  shellHook = ''
    export ROOT_DIR="$PWD";
    export SECRETS="$ROOT_DIR/secrets/tofu-tokens/tokens.json.age"
    export AGE_KEY="$ROOT_DIR/secrets/rekeyed/master.age"
    export TF_STATE="$ROOT_DIR/secrets/tofu-tokens/tfstate.age"

    # Ensure path to githooks is defined
    ensure-git-hooks

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
