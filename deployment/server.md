# Deploying FETCH to raw servers

## Prerequisites

### Inventory Service 

* Environment Agnostic Docker Container
* CORS (required for hosting api/pwa on separate servers)
* HTTPS (required for CORS)
* Reverse Proxy (required for https)
* Load balancer (required for multiple workers)

### Quasar PWA

* Environment Agnostic Docker Container
* HTTPS (required for PWA)
* Web Server (required for https)

## Notes

The Dockerfile called "prod" in the Inventory Service has some issues.
Having separate dockerfiles for separate environments is [generally considered an anti-pattern](https://shipyard.build/blog/dockerfile-for-dev-ci-production/).
There's a .env file copied into the container, this means the image file is now a secret and specific to production.
The image file is also sensitive as an attacker could run the image and access the secrets.

In the prod image git/Java/SchemaSpy/dotviz are all installed despite not being used in production.
This unneccessarily and drastically increases the image size and potential attack surface.

For the PWA, the .env file is also copied into it with the same issues as the Inventory Service.
There are additional issues with the Production image regarding ssl certs.
Many of the same issues preventing the dev image from being used are present here with cert generated during image build.

## Choices made

Caddy for Web Server / Reverse Proxy / Load Balancer
Letsencrypt for ssl certificates
Docker Compose for hosting
RDS for database
