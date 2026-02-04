#!/usr/bin/env bash
set -euo pipefail

tfstate_setup() {
  ROOT_DIR="$(git rev-parse --show-toplevel)"
  TFSTATE="$ROOT_DIR/terraform.tfstate"
  SECRET="$ROOT_DIR/secrets/tofu-tokens/tfstate.age"
  CHECKSUM="$ROOT_DIR/.tfstate.sha256"
  MASTER_ID="$ROOT_DIR/secrets/master-identity.nix"
}

tfstate_pubkey() {
  if [[ ! -f "$MASTER_ID" ]]; then
    echo "${1:-hook}: missing $MASTER_ID; cannot locate age recipient" >&2
    return 1
  fi

  pubkey="$(sed -nE 's/.*pubkey = "([^"]+)".*/\1/p' "$MASTER_ID" | head -n 1)"
  if [[ -z "$pubkey" ]]; then
    echo "${1:-hook}: could not extract pubkey from $MASTER_ID" >&2
    return 1
  fi

  echo "$pubkey"
}

tfstate_checksum() {
  sha256sum "$TFSTATE" | awk '{print $1}'
}

tfstate_stored_checksum() {
  if [[ -f "$CHECKSUM" ]]; then
    awk '{print $1}' "$CHECKSUM"
  fi
}

tfstate_encrypt_and_stage() {
  local pubkey="$1"
  local tmp=""
  cleanup() {
    if [[ -n "${tmp:-}" ]]; then
      rm -f "$tmp"
    fi
  }
  trap cleanup EXIT
  tmp="$(mktemp "${SECRET}.tmp.XXXXXX")"

  age -r "$pubkey" -o "$tmp" "$TFSTATE"
  mv "$tmp" "$SECRET"
  sha256sum "$TFSTATE" > "$CHECKSUM"
  git add "$SECRET" "$CHECKSUM"
}
