# syntax=docker/dockerfile:1

FROM registry.hub.docker.com/library/node:22 AS builder
RUN npm -g install @quasar/cli

WORKDIR /app
COPY package*.json /app
RUN npm install

COPY ./ /app

RUN ls && quasar build -m pwa

FROM registry.hub.docker.com/library/caddy:alpine
RUN <<CADDYFILE
printf '{$DOMAIN} {
    root * /var/www
    file_server
}' >> /etc/caddy/Caddyfile
CADDYFILE
COPY --from=builder /app/dist/pwa /var/www
