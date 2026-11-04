FROM debian:forky-slim AS ci

ENV DEBIAN_FRONTEND=noninteractive

# Repositori custom propi
ADD http://master.debci.antonialoytorrens.com/key.gpg \
	/etc/apt/keyrings/master.debci.antonialoytorrens.com.gpg
RUN chmod 644 /etc/apt/keyrings/master.debci.antonialoytorrens.com.gpg \
	&& printf 'deb [signed-by=/etc/apt/keyrings/master.debci.antonialoytorrens.com.gpg] http://master.debci.antonialoytorrens.com/debian trixie main\n' \
		> /etc/apt/sources.list.d/master.debci.antonialoytorrens.com.list \
	&& apt-get update \
	&& apt-get -yq full-upgrade \
	&& apt-get -yq install --no-install-recommends \
		kiwi rsync make kiwi-systemdeps fdisk libxml2-utils xz-utils \
		ca-certificates curl git jq shellcheck \
		sonar-scanner \
	&& rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash builder \
	&& mkdir -p /workspace \
	&& chown builder:builder /workspace

USER builder
WORKDIR /workspace
CMD ["bash"]
