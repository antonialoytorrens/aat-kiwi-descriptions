FROM debian:forky-slim AS ci

ARG SONAR_SCANNER_CLI=8.0.1.6346
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/sonar-scanner/bin:${PATH}

RUN apt-get update && \
    apt-get -yq full-upgrade && \
    apt-get -yq install --no-install-recommends \
        kiwi rsync make kiwi-systemdeps fdisk libxml2-utils xz-utils \
        ca-certificates curl unzip default-jre-headless git jq shellcheck \
    && rm -rf /var/lib/apt/lists/*

ADD https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_CLI}-linux-x64.zip /tmp/sonar-scanner.zip
RUN unzip -q /tmp/sonar-scanner.zip -d /opt \
    && mv /opt/sonar-scanner-${SONAR_SCANNER_CLI}-linux-x64 /opt/sonar-scanner \
    && rm -f /tmp/sonar-scanner.zip

RUN useradd --create-home --shell /bin/bash builder \
	&& mkdir -p /workspace \
	&& chown builder:builder /workspace

USER builder
WORKDIR /workspace
CMD ["bash"]
