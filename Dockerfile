# Based on https://github.com/haugene/docker-transmission-openvpn/blob/d7e7a24fbb384df866c2e9ae0e31104895dd26ea/Dockerfile

FROM lscr.io/linuxserver/wireguard

VOLUME /config
VOLUME /data

COPY root/ /

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
		wget \
	&& bash "/app/install-transmission-ui.sh" \
	&& bash "/app/install-piawg.sh" \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

ENV \
	PROVIDER="" \
	TRANSMISSION_HOME="/config/transmission" \
	TRANSMISSION_LOG="default" \
	TRANSMISSION_WEB_UI="kettu" \
	HEALTH_CHECK_HOST="one.one.one.one" \
	LOCAL_NETWORK=""

HEALTHCHECK --interval=1m CMD "/app/healthcheck"

EXPOSE 9091
