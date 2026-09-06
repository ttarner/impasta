FROM --platform=linux/amd64 ubuntu:22.04 AS builder

ADD https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz flutter_linux.tar.xz

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
apt-get clean

ENV DEBIAN_FRONTEND=dialog

RUN echo "64df4273de625433c7ba41967932b782f5f9abf3199db8330782d64508379344  flutter_linux.tar.xz" | sha256sum -c - && \
    tar -xf flutter_linux.tar.xz -C /usr/local && \
    rm -f flutter_linux.tar.xz
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN git config --global --add safe.directory /usr/local/flutter && \
    flutter config --no-cli-animations && \
    flutter config --enable-web

RUN mkdir /app/
WORKDIR /app/

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web

FROM caddy:2-alpine

COPY --from=builder /app/build/web /srv
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 9000

