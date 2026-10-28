FROM docker.io/library/debian:trixie
RUN apt-get update \
 && apt-get install -y --no-install-recommends aapt default-jdk-headless ca-certificates \
 && rm -rf /var/lib/apt/lists/*
