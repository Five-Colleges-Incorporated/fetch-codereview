# Deploying FETCH to raw servers

## Prerequisites

### Inventory Service 

* Environment Agnostic Docker Container
* CORS (required for hosting api/pwa on separate servers)
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
There's a .env file copied into the container, this means the image file is now a secret and specific to production.
The image file is also sensitive as an attacker could run the image and access the secrets.

In the prod image git/Java/SchemaSpy/dotviz are all installed despite not being used in production.
This unneccessarily and drastically increases the image size and potential attack surface.

For the PWA, the .env file is also copied into it with the same issues as the Inventory Service.
There are additional issues with the Production image regarding ssl certs.
Many of the same issues preventing the dev image from being used are present here with cert generated during image build.

A complication encountered with the PWA fetch app is that quasar build compiles in the values of environment variables at build time.
We want these values at runtime, not compiled into the dockerfile.

## Choices made

Caddy is a modern alternative to nginx which automates https certificate acquisition/rotation with Letsencrypt.

Docker Compose is a simple way to run Docker Containers allowing horizontal scaling on a single host and service restarts upon crashing.

Two separate EC2 instances were setup allowing for scaling the pwa and inventory service separately.
RDS was used for the database to automate maintenance/backups/security etc and also scale separately.
This could all be hosted on a single EC2 instance with a reverse proxy setup to direct traffic to the inventory service or pwa as necessary.

The PWA was dockerized with the environment hardcoded to simplify ssl handling and deployment.
It is not recommended to dockerize this application and instead use different static hosting method.

## Setup Steps (for inventory service)

1. Create an EC2 instance
1. Create an RDS database, allowing connections from EC2
1. SSH into the EC2 instance and [install docker compose](https://stackoverflow.com/a/72156137)
1. Create Public ECR registries for inventory service images (this is why we're not building secrets into the image)
1. Follow ECR steps to build/deploy images. Note the inventory-service-caddy image uses the same Dockerfile with a --target caddy flag.
1. Create a dns records pointing to the ip address of the EC2 instance
1. Create a database inside the RDS instance
1. Create a .env file on the server based on the template with values filled in
1. Use scp to copy the docker-compose file to the server
1. Run docker-compose up -d
1. (Optional) Scale to multiple services by running docker-compose up --scale inventory_service=2+
1. (Optional) Seed the data as in developer setup, note you have to use the python executable from the .venv and run it in the app's parent folder

## Setup Steps (for pwa)
1. Create an EC2 instance
1. SSH into the EC2 instance and install docker compose
1. Create a Public ECR registry for pwa image
1. Follow ECR steps to build/deploy image
1. Create a dns records pointing to the ip address of the EC2 instance
1. Create a .env file on the server based on the template with values filled in
1. Use scp to copy the docker-compose file to the server
1. Run docker-compose up -d
