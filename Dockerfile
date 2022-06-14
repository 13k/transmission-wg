# Based on https://github.com/haugene/docker-transmission-openvpn/blob/d7e7a24fbb384df866c2e9ae0e31104895dd26ea/Dockerfile

FROM linuxserver/wireguard:latest

ENV \
	S6_CMD_WAIT_FOR_SERVICES="1" \
	CONFIG_DIR="/var/lib/transmission"

ENV \
	PROVIDER="" \
	WG_CONFIG="/config/wg0.conf" \
	TRANSMISSION_HOME="${CONFIG_DIR}/transmission" \
	TRANSMISSION_LOG="default" \
	TRANSMISSION_WEB_UI="kettu" \
	HEALTH_CHECK_HOST="one.one.one.one" \
	LOCAL_NETWORK=""

VOLUME "$CONFIG_DIR"

HEALTHCHECK --interval=1m CMD "/app/healthcheck"

EXPOSE 9091

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
	&& dir="/opt/transmission-ui/flood-for-transmission" \
	&& mkdir -p "$dir" \
	&& wget -qO- "https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="/opt/transmission-ui/combustion" \
	&& mkdir -p "$dir" \
	&& wget -qO- "https://github.com/Secretmapper/combustion/archive/release.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="/opt/transmission-ui/kettu" \
	&& mkdir -p "$dir" \
	&& wget -qO- "https://github.com/endor/kettu/archive/master.tar.gz" | \
		tar -xz --strip-components=1 -C "$dir"

RUN \
	set -exu \
	&& dir="/opt/transmission-ui/transmission-web-control" \
	&& mkdir -p "$dir" \
	&& url="$(\
		curl -sfL "https://api.github.com/repos/ronggang/transmission-web-control/releases/latest" | \
		jq --raw-output ".tarball_url" \
	)" \
	&& curl -sfL "$url" | \
		tar --strip-components=2 -xz -C "$dir" \
	&& ln -s "/usr/share/transmission/web/index.html" "${dir}/index.original.html" \
	&& ln -s "/usr/share/transmission/web/style" "$dir" \
	&& ln -s "/usr/share/transmission/web/images" "$dir" \
	&& ln -s "/usr/share/transmission/web/javascript" "$dir"

RUN \
	set -exu \
	&& curl -sfLo "/etc/apt/trusted.gpg.d/nordvpn_public.asc" "https://repo.nordvpn.com/gpg/nordvpn_public.asc" \
	&& echo "deb https://repo.nordvpn.com/deb/nordvpn/debian stable main" >"/etc/apt/sources.list.d/nordvpn.list" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends nordvpn

RUN \
	set -exu \
	&& url="$(\
		curl -sfL "https://gitlab.com/api/v4/projects/ddb_db%2fpiawgcli/releases" | \
		jq --raw-output 'map(select(.upcoming_release | not)) | .[0].assets.links | map(select(.name | contains("linux/amd64"))) | .[0].direct_asset_url' \
	)" \
	&& curl -sfLo "/usr/bin/piawgcli" "$url" \
	&& chmod a+x "/usr/bin/piawgcli"

RUN \
	set -exu \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

COPY root/ /
