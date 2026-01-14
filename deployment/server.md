# Deploying FETCH to raw servers

## Prerequisites

### Inventory Service

* Environment Agnostic Docker Container
* CORS (required for hosting api/pwa on separate urls)
* HTTPS (required for CORS)
* Reverse Proxy (required for https)
* Load balancer (required for multiple workers)

### Quasar PWA

* Environment Agnostic Docker Container (not actually a prereq see below)
* HTTPS (required for PWA)
* Web Server (required for https)

## Notes

The Dockerfile called "prod" in the Inventory Service has some issues.
Having separate dockerfiles for separate environments is [generally considered an anti-pattern](https://shipyard.build/blog/dockerfile-for-dev-ci-production/).
There's a .env file copied into the container, this means the image file now contains secrets and is itself a secret.
The image file is also sensitive as an attacker could run the image and access the secrets.

In the prod image git/Java/SchemaSpy/dotviz are all installed despite not being used in production.
This unneccessarily and drastically increases the image size and potential attack surface.

The Production pwa image has the same issues around certs as local development.
There is no way this is how the production image is built for the Library of Congress.
Many of the same issues preventing the dev image from being used are present here with cert generated during image build.

For the PWA, the .env file is also copied into it with the same issues as the Inventory Service.
There is an additional complication encountered with quasar build compiling in the values of $VITE_INV_SERVCE_API
This makes sense because it's being compiled into a static site and not running through something like express.
It does make docker a poor choice for deploying the pwa.

## Choices made

Caddy is a modern alternative to nginx which automates https certificate acquisition/rotation with Letsencrypt.

Docker Compose is a simple way to run Docker Containers allowing horizontal scaling on a single host and service restarts upon crashing.

One large EC2 instance was setup to simplify deployment.
RDS was used for the database to automate maintenance/backups/security etc and also scale separately.
It could be run using docker-compose on the same EC2 instance as the other services.

The PWA was not dockerized so as not to hardcode any build time parameters.

## Setup Steps

1. Create an EC2 instance
1. Create an RDS database, allowing connections from EC2
1. SSH into the EC2 instance and [install docker compose](https://stackoverflow.com/a/72156137)
1. Create a Public ECR registry for the inventory service image (this is why we're not building secrets into the image)
1. Follow ECR steps to build/publish the inventory_service images
1. Create two dns records pointing to the ip address of the EC2 instance
1. Follow Quasar steps to build the PWA targeting the production inventory service
1. Create a database inside the RDS instance
1. Create a .env file on the server based on the template with values filled in
1. Use scp to copy the Caddyfile, docker-compose file, and static PWA files to the server
1. Run docker-compose up -d
1. (Optional) Scale to multiple services by running docker-compose up --scale inventory_service=2+
1. (Optional) Seed the data as in developer setup, note you have to use the python executable from the .venv and run it in the app's parent folder
