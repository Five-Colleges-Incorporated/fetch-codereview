# Developer Setup

## fetch-fetch-local

> This is the starting point for working with FETCH locally as a developer.

Immediately there are issues with the installation instructions.

> 1. Setup an ssh key in gitlab
> 2. Install homebrew: https://brew.sh/
> 3. Install a newer version of git: $ brew install git
> 4. Install docker desktop
> 5. Configure docker desktop to allow 8g of memory, and 200g of disk space.

Gitlab is the remote source control and build platform used during the development of FETCH.
The source code is now stored in GitHub.

Homebrew is mac specific and not required for installing git.
See [Getting Started - Installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for installing git for your system.
Alternatively a git GUI, [like github desktop](https://desktop.github.com/download/), may be used.

Docker Desktop is not free software.
There are [restrictions on who can use Docker Desktop without a license](https://docs.docker.com/subscription/desktop-license/).

While assuming that a developer has 8gb of memory and 200gb of disk space is safe in 2025 it _is_ an assumption.

> Now run ./scripts/install.sh

This script will not run as it makes assumptions about vnps(?) and urls of source control.

This script also hardcodes the local path to clone repositories, making a hard assumption about the user's file system.

I've cloned these repositories under a fetch directory the git command line.
```bash
mkdir fetch
git clone https://github.com/LibraryOfCongress/fetch-automation.git fetch/automation
git clone https://github.com/LibraryOfCongress/fetch-database.git fetch/database
git clone https://github.com/LibraryOfCongress/fetch-fetch-local.git fetch/fetch-local
git clone https://github.com/LibraryOfCongress/fetch-inventory_service.git fetch/inventory_service
git clone https://github.com/LibraryOfCongress/fetch-vue.git fetch/vue
```

Note that the name of the resulting directory is different than the name of the repository, there is one fewer `fetch-`.

> docker compose up

This command runs out of the box and appears to start services.

> Inventory Service API: http://127.0.0.1:8001/
> Inventory Service API Cache: http://127.0.0.1:6379/
> Web App: http://127.0.0.1:8080/
> PG Admin: http://127.0.0.1:5050/

Of these local urls, only the pg admin url is correct. The Web App is port 8000 and the api only exposes a single port of 8001.
Navigating to 127.0.0.1:8000 loads the FETCH login screen.

> Local login user: admin@fetch.example.com Local login pass: admin

These credentials do not work out of the box. The api request is being sent to 127.0.0.1:8000 because the $VITE_INV_SERVCE_API value is not set.
Creating a new .env file called fetch/vue/env/.env.local with the following content allows the local frontend to connect to the local backend.
```
VITE_ENV='local'
VITE_INV_SERVCE_API='https://127.0.0.1:8001'
```

HTTPS does not work which prevents calls to the backend from being successful.
Service workers can also not be registered.

Local FETCH uses mkcert inside the vue container to generate a self-signed cert.
The inventory_service also uses a self-signed cert.
There isn't a simple way to get these certs into the cert store of the host computer so Chrome can use them.
Starting chrome using the `--ignore-certificate-errors` flag is possibly the easiest way to get bast the ssl issues.
I also tried using `docker cp` to copy the .pem files out of the container to install them in the host's certificate store which works but is messy.

Once started, FETCH is using Access-Control-Allow-Origin * header to get around CORS.
Since late 2020 this has only been allowed on localhost.
It's about here that I gave up on running FETCH local.

## fetch-vue
