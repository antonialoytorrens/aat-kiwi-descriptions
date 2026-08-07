FROM debian:forky

#RUN echo 'deb [trusted=yes] http://dports.antonialoytorrens.com/aat-linux-repository/debian trixie main' \
#        > /etc/apt/sources.list.d/aat.list && \
RUN    apt-get update && \
    apt-get -yq full-upgrade && \
    apt-get -yq install --no-install-recommends \
        kiwi rsync make python3 libxml2-utils shellcheck ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
