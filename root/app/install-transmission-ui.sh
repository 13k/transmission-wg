#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

INSTALL_DIR="${INSTALL_DIR:-"/opt/transmission-ui"}"
FLOOD_URL="https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz"
COMBUSTION_URL="https://github.com/Secretmapper/combustion/archive/release.tar.gz"
KETTU_URL="https://github.com/endor/kettu/archive/master.tar.gz"
WEB_CONTROL_RELEASE_URL="https://api.github.com/repos/ronggang/transmission-web-control/releases/latest"

install_flood() {
  local dir="${INSTALL_DIR}/flood-for-transmission"

  mkdir -p "$dir"

  wget -qO- "$FLOOD_URL" | tar -xz --strip-components=1 -C "$dir"
}

install_combustion() {
  local dir="${INSTALL_DIR}/combustion"

  mkdir -p "$dir"

  wget -qO- "$COMBUSTION_URL" | tar -xz --strip-components=1 -C "$dir"
}

install_kettu() {
  local dir="${INSTALL_DIR}/kettu"

  mkdir -p "$dir"

  wget -qO- "$KETTU_URL" | tar -xz --strip-components=1 -C "$dir"
}

install_web_control() {
  local url
  local dir="${INSTALL_DIR}/transmission-web-control"

  mkdir -p "$dir"

  url="$(curl -sf "$WEB_CONTROL_RELEASE_URL" | jq --raw-output ".tarball_url")"

  curl -sfL "$url" | tar --strip-components=2 -xz -C "$dir"

  ln -s "/usr/share/transmission/web/index.html" "${dir}/index.original.html"
  ln -s "/usr/share/transmission/web/"{style,images,javascript} "$dir"
}

{
  set -x

  mkdir -p "$INSTALL_DIR"
  install_flood
  install_combustion
  install_kettu
  install_web_control
}
