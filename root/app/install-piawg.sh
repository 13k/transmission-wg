#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

PREFIX="${PREFIX:-"/usr"}"
BINDIR="${PREFIX}/bin"
BIN_PATH="${BINDIR}/piawgcli"

RELEASE_URL="https://gitlab.com/api/v4/projects/ddb_db%2fpiawgcli/releases"
RELEASE_JQ='
  map(select(.upcoming_release | not)) |
  .[0].assets.links |
  map(select(.name | contains("linux/amd64"))) |
  .[0].direct_asset_url
'

install_piawg() {
  url="$(curl -sf "$RELEASE_URL" | jq --raw-output "$RELEASE_JQ")"
  curl -sfLo "$BIN_PATH" "$url"
  chmod a+x "$BIN_PATH"
}

{
  set -x

  install_piawg
}
