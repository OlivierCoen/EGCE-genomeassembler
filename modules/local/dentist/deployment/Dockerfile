FROM debian:bookworm

ARG VERSION=v4.0.0.x86_64

RUN apt-get update \
    && apt-get install -y wget

WORKDIR /opt

RUN wget https://github.com/a-ludi/dentist/releases/download/v4.0.0/dentist.${VERSION}.tar.gz \
    && tar -xzf dentist.${VERSION}.tar.gz

ENV PATH="/opt/dentist.${VERSION}/bin:${PATH}"

WORKDIR /tmp


