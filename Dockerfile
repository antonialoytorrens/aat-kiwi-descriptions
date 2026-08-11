FROM debian:forky-slim

RUN    apt-get update && \
    apt-get -yq full-upgrade && \
    apt-get -yq install --no-install-recommends \
        kiwi rsync make kiwi-systemdeps fdisk xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
