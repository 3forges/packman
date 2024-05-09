FROM debian:bookworm-slim

RUN apt-get update -y && \
    apt-get install -y curl \
    jq \
    bash \
    ethtool \
    tcpdump \
    nmap \
    iputils-ping \
    iproute2 \
    traceroute

ARG PLUMBER_HOME=/usr/plumber
ENV PLUMBER_HOME=$PLUMBER_HOME
RUN mkdir -p /usr/plumber/data && mkdir -p /usr/plumber/ops
VOLUME /usr/plumber/data

WORKDIR /usr/plumber/ops
ENTRYPOINT [ "/bin/bash" ]
