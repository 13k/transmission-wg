# Based on https://github.com/haugene/docker-transmission-openvpn/blob/d7e7a24fbb384df866c2e9ae0e31104895dd26ea/Dockerfile

FROM ghcr.io/linuxserver/wireguard

VOLUME /config
VOLUME /data

RUN \
    set -eux ; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
        bash \
        dnsutils \
        jq \
        transmission-cli transmission-daemon \
        tzdata \
        wget ; \
    mkdir -p /opt/transmission-ui ; \
    wget -qO- "https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz" | tar xz -C /opt/transmission-ui ; \
    wget -qO- "https://github.com/Secretmapper/combustion/archive/release.tar.gz" | tar xz -C /opt/transmission-ui ; \
    wget -qO- "https://github.com/endor/kettu/archive/master.tar.gz" | tar xz -C /opt/transmission-ui ; \
    mv /opt/transmission-ui/kettu-master /opt/transmission-ui/kettu ; \
    mkdir /opt/transmission-ui/transmission-web-control ; \
    ( \
        asset_url="$(curl -sf 'https://api.github.com/repos/ronggang/transmission-web-control/releases/latest' | jq --raw-output '.tarball_url')" ; \
        curl -sfL "$asset_url" | tar -C /opt/transmission-ui/transmission-web-control/ --strip-components=2 -xz ; \
    ) ; \
    ln -s /usr/share/transmission/web/style /opt/transmission-ui/transmission-web-control ; \
    ln -s /usr/share/transmission/web/images /opt/transmission-ui/transmission-web-control ; \
    ln -s /usr/share/transmission/web/javascript /opt/transmission-ui/transmission-web-control ; \
    ln -s /usr/share/transmission/web/index.html /opt/transmission-ui/transmission-web-control/index.original.html ; \
    ( \
        asset_url="$(curl -sf 'https://gitlab.com/api/v4/projects/ddb_db%2fpiawgcli/releases' | jq --raw-output 'map(select(.upcoming_release | not)) | .[0].assets.links | map(select(.name | contains("linux/amd64"))) | .[0].direct_asset_url')" ; \
        curl -sfLo "/usr/bin/piawgcli" "$asset_url" ; \
        chmod a+x "/usr/bin/piawgcli" ; \
    ) ; \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* ;

ENV \
    PROVIDER="" \
    TRANSMISSION_HOME="/config/transmission" \
    TRANSMISSION_LOG="default" \
    TRANSMISSION_WEB_UI="kettu" \
    HEALTH_CHECK_HOST="one.one.one.one" \
    LOCAL_NETWORK=""

HEALTHCHECK --interval=1m CMD "/app/healthcheck"

COPY root/ /

EXPOSE 9091
