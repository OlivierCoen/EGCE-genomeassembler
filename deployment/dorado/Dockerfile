FROM ubuntu:24.04

ARG VERSION=1.0.0

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN curl "https://cdn.oxfordnanoportal.com/software/analysis/dorado-${VERSION}-linux-x64.tar.gz" -o /opt/dorado-${VERSION}-linux-x64.tar.gz && \
    tar -xzf /opt/dorado-${VERSION}-linux-x64.tar.gz && \
    chmod +x /opt/dorado-${VERSION}-linux-x64/bin/dorado

ENV PATH="/opt/dorado-${VERSION}-linux-x64/bin:${PATH}"


RUN dorado --version
