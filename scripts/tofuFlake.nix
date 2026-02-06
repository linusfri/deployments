{ pkgs, ... }:
let
  exportVars = pkgs.writeShellScriptBin "export-vars" ''
    TF_DIR="$ROOT_DIR/opentofu"
    STATE_FILE="$ROOT_DIR/terraform.tfstate"
    TMP="$(mktemp)"
    GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  '';

  cleanup = pkgs.writeShellScriptBin "cleanup" ''
    export-vars

    if [[ -n "$GIT_ROOT" ]]; then
      git -C "$GIT_ROOT" reset -q -- "$STATE_FILE" >/dev/null 2>&1 || true
    fi
    
    rm -f "$STATE_FILE" "$TMP"
  '';

  fetchTofuState = pkgs.writeShellScriptBin "fetch-tofu-state" ''
    export-vars

    trap cleanup EXIT

    TF_DIR="$ROOT_DIR/opentofu"
    STATE_FILE="$ROOT_DIR/terraform.tfstate"
    TMP="$(mktemp)"
    GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

    if [[ ! -d "$TF_DIR" ]]; then
      echo "Missing OpenTofu dir: $TF_DIR" >&2
      exit 1
    fi

    (cd "$TF_DIR" && tofu state pull > "$TMP")
    mv "$TMP" "$STATE_FILE"

    if [[ -n "$GIT_ROOT" ]]; then
      git -C "$GIT_ROOT" add -f "$STATE_FILE" >/dev/null 2>&1 || true
    fi
  '';

  tofuFlake = pkgs.writeShellScriptBin "tofuflake" ''
    set -euo pipefail

    fetch-tofu-state

    terraflake "$@"
  '';

  tofuAge = pkgs.writeShellScriptBin "tofuage" ''
    set -euo pipefail

    fetch-tofu-state

    agenix "$@"
  '';
in
{
  inherit
    exportVars
    cleanup
    fetchTofuState
    tofuFlake
    tofuAge
    ;
}
