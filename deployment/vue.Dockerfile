# syntax=docker/dockerfile:1

FROM registry.hub.docker.com/library/node:22 AS builder
RUN npm -g install @quasar/cli

WORKDIR /app
COPY package*.json /app
RUN npm install

COPY ./ /app


ARG VITE_ENV
ENV VITE_ENV=${VITE_ENV}
ARG VITE_INV_SERVCE_API
ENV VITE_INV_SERVCE_API=${VITE_INV_SERVCE_API}
RUN <<DOTENV
printf "VITE_ENV=$VITE_ENV
VITE_INV_SERVCE_API=$VITE_INV_SERVCE_API
" >> /app/env/.env
DOTENV
RUN quasar build -m pwa

FROM registry.hub.docker.com/library/caddy:alpine
RUN <<CADDYFILE
printf '{$DOMAIN} {
	root * /var/www
	file_server
	try_files {path} {path}/ /index.html
}' >> /etc/caddy/Caddyfile
CADDYFILE
COPY --from=builder /app/dist/pwa /var/www
