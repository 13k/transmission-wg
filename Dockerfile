# syntax=docker/dockerfile:1

ARG WG_CONFIG_PREFIX="/config"
ARG TRANSMISSION_CONFIG_PREFIX="/var/lib/transmission"
ARG TRANSMISSION_WEB_PREFIX="/var/lib/transmission-web"

FROM alpine:3.15 as transmission-web-build

ARG TRANSMISSION_WEB_PREFIX

RUN \
	set -exu \
	&& apk add --no-cache --upgrade \
		curl \
		jq \
		gzip \
		tar

RUN \
	set -exu \
	&& dir="${TRANSMISSION_WEB_PREFIX:?}/flood-for-transmission" \
	&& mkdir -p "$dir" \
	&& curl -fsSL "https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="${TRANSMISSION_WEB_PREFIX:?}/combustion" \
	&& mkdir -p "$dir" \
	&& curl -fsSL "https://github.com/Secretmapper/combustion/archive/release.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="${TRANSMISSION_WEB_PREFIX:?}/kettu" \
	&& mkdir -p "$dir" \
	&& curl -fsSL "https://github.com/endor/kettu/archive/master.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="${TRANSMISSION_WEB_PREFIX:?}/transmission-web-control" \
	&& mkdir -p "$dir" \
	&& url="$(\
		curl -fsSL "https://api.github.com/repos/ronggang/transmission-web-control/releases/latest" | \
		jq -r ".tarball_url" \
	)" \
	&& curl -sfL "$url" | \
		tar --strip-components=2 -xz -C "$dir" \
	&& ln -s "/usr/share/transmission/web/index.html" "${dir}/index.original.html" \
	&& ln -s "/usr/share/transmission/web/style" "$dir" \
	&& ln -s "/usr/share/transmission/web/images" "$dir" \
	&& ln -s "/usr/share/transmission/web/javascript" "$dir"

FROM linuxserver/wireguard:latest

ARG WG_CONFIG_PREFIX
ARG TRANSMISSION_CONFIG_PREFIX
ARG TRANSMISSION_WEB_PREFIX

ENV \
	S6_CMD_WAIT_FOR_SERVICES="1" \
	WG_CONFIG_PREFIX="${WG_CONFIG_PREFIX:?}" \
	WG_CONFIG="${WG_CONFIG_PREFIX:?}/wg0.conf" \
	TRANSMISSION_CONFIG_PREFIX="${TRANSMISSION_CONFIG_PREFIX:?}" \
	TRANSMISSION_WEB_PREFIX="${TRANSMISSION_WEB_PREFIX:?}" \
	PROVIDERS_PREFIX="${TRANSMISSION_CONFIG_PREFIX:?}/providers" \
	TRANSMISSION_HOME="${TRANSMISSION_CONFIG_PREFIX:?}/transmission" \
	TRANSMISSION_LOG="stdout" \
	TRANSMISSION_WEB_UI="flood-for-transmission" \
	HEALTH_CHECK_HOST="one.one.one.one" \
	PROVIDER="" \
	LOCAL_NETWORK=""

RUN \
	set -exu \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		bash \
		dnsutils \
		jq \
		transmission-cli \
		transmission-daemon \
		tzdata \
		wget

RUN \
	set -exu \
	&& curl -sfLo "/etc/apt/trusted.gpg.d/nordvpn_public.asc" "https://repo.nordvpn.com/gpg/nordvpn_public.asc" \
	&& echo "deb https://repo.nordvpn.com/deb/nordvpn/debian stable main" >"/etc/apt/sources.list.d/nordvpn.list" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends nordvpn

RUN \
	set -exu \
	&& url="$( \
		curl -sfL "https://gitlab.com/api/v4/projects/ddb_db%2fpiawgcli/releases" | \
		jq -r 'map(select(.upcoming_release | not)) | .[0].assets.links | map(select(.name | contains("linux/amd64"))) | .[0].direct_asset_url' \
	)" \
	&& curl -sfLo "/usr/bin/piawgcli" "$url" \
	&& chmod a+x "/usr/bin/piawgcli"

RUN \
	set -exu \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

COPY --from=transmission-web-build "${TRANSMISSION_WEB_PREFIX:?}" "${TRANSMISSION_WEB_PREFIX:?}"
COPY root/ /

VOLUME "${TRANSMISSION_CONFIG_PREFIX:?}"

HEALTHCHECK --interval=1m CMD "/app/healthcheck"

EXPOSE 9091
