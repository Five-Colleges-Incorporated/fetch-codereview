# Developer Setup

> [!CAUTION]
> The inventory_service tests runs `docker system prune -af` and `docker volume prune -fa`.
> Do not run these tests if you use Docker for any other purpose than FETCH development.

#### The good
Industry standard tools and practices apply here.
You can just use the quasar and uvicorn/fastapi documentation and get a running development environment.

Seeding the database is a great way to quickly get started testing.

fetch-vue lints cleanly with the given rules.

#### The ok but notable

The seed data is LoC specific. There is a huge amount of seed data here which makes customizing it more difficult.

Some slight changes are required to be made to the fetch-vue and fetch-inventory_service repositories to get them running "out of the box".

There's many bash scripts that do "stuff" and they aren't documented.
These aren't actually necessary to running FETCH locally.

The fetch-database project isn't really required for local development.

The fetch-vue eslint rules are narrow and lax.
Enabling vue3-essential, vue3-recommended, and eslint-plugin-pinia is recommended

The versions of black, isort, and autopep8 are not pinned which could lead to inconsistent rules between developers and CI environments.
These libraries are also not installed except for notes at the end of the README.

Java is a runtime dependency for inventory_service even though it is only used for Schema Spy in local/dev environments.

#### Areas of improvement

The fetch-local repository feels fundamentally broken. I couldn't get it working at all.
Maybe it worked at some point or in the original implementers environment.

fetch-vue does not have a configured code formatter (prettier is standard for javascript).
The vscode config file has prettier settings but not everyone uses vscode and this isn't mentioned in the documentation.

fetch-vue has failing tests out of the box.
The test coverage for fetch-vue is incredibly narrow which means development relies on slow manual testing.
[@testing-library/vue](https://testing-library.com/docs/vue-testing-library/intro/) is the industry standard for testing the behavior of vue code without having to run the application.

Testing the application on mobile as a PWA appears to require a paid service called ngrok.
The instructions for setting this up are vague.

The tooling and setup around the inventory_service is dated.
There has been a huge amount of upheaval in the past 2-3 years around this ecosystem and it should be updated and made consistent.

fetch-inventory_service has failing tests out of the box.
Black, isort, autopep8, flake8, and mypy do not lint/format cleanly out of the box.

#### A quick note about docker desktop and podman

The installation instructions say to install Docker Desktop.
Docker Desktop is not free software.
There are [restrictions on who can use Docker Desktop without a license](https://docs.docker.com/subscription/desktop-license/).

Podman is an open source alternative.
In fact, helper scripts in these repositories use Podman with no mention of installing or configuring it.

## Running FETCH locally

### fetch-local

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

While assuming that a developer has 8gb of memory and 200gb of disk space is reasonably safe in 2025 it _is_ an assumption.

> Now run ./scripts/install.sh

This script will not run as it makes assumptions about vpns(?) and urls of source control.

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
>
> Inventory Service API Cache: http://127.0.0.1:6379/
>
> Web App: http://127.0.0.1:8080/
>
> PG Admin: http://127.0.0.1:5050/

Of these local urls, only the pg admin url is correct. The Web App is port 8000 (and https) and the api only exposes a single port of 8001.
Navigating to 127.0.0.1:8000 loads the FETCH login screen.

> Local login user: admin@fetch.example.com Local login pass: admin

The api request is being sent to 127.0.0.1:8000 because the $VITE_INV_SERVCE_API (sic) value is not set.
Creating a new .env file called fetch/vue/env/.env.local with the following content allows the local frontend to connect to the local backend.
```
VITE_ENV='local'
VITE_INV_SERVCE_API='https://localhost:8001'
```

The given credentials do not work.
I tried using the pgadmin instance that was started to see if I could find the credentials in the database.
It was not pre-configured to connect to the docker-compose database and I couldn't figure out how to connect to it.
Weirdly I _was_ able to make requests to the inventory_service api but it looks like the database had not been seeded.

Local FETCH uses mkcert inside the vue container to generate a self-signed cert.
I really have no idea how the inventory_service gets an ssl cert.
There isn't a simple way to get these certs into the cert store of the host computer so Chrome can use them.
Starting chrome using the `--ignore-certificate-errors` flag is possibly the easiest way to get bast the ssl issues.

Service workers can also not be registered cannot be registered due to ssl issues.

It's about here that I gave up on running FETCH using the fetch-fetch-local repository.

### Non fetch-local setup

Trying to run FETCH locally with a "push button" process didn't exactly go smoothly.
I'm not sure if it is even that desired, as it removes the Hot Module Reload capabilities of Quasar/Vue that are part of modern javascript development.
The next approach to FETCH local is to setup the frontend and backend to run without docker using the underlying technologies.

I mostly disregarded the READMEs and documentation at this point to see if it would even be possible.

#### fetch-vue

I used mkcert to generate certs and place them in the .cert directory.
quasar.conf.js had to be edited to uncomment out reading the cert files.

I added a .env.local file with values for the backend inventory_service
```
VITE_ENV='local'
VITE_INV_SERVCE_API='http://localhost:8001'
```

Running normal npm/quasar commands started the frontend.

```
npm install 
npm run quasar:local
```

#### fetch-database

Actually just one docker command really.
```
docker run \
    --name fetch-pg \
    -p 15432:5432 \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=inventory_service \
    -d postgres:latest
```

If desired you can add a volume to persist data.

#### fetch-inventory_service

Every inventory_service image installs java into the container in order to run schema spy.
Even production where schema spy is not run.
Running the inventory_service locally without java install kills the api.
I hacked in a SCHEMA_SPY setting to allow the inventory service to start.

I added a .env file with the docker database credentials in the repository root.
```
SCHEMA_SPY=False
DATABASE_URL="postgresql://postgres:postgres@localhost:15432/inventory_service"
MIGRATION_URL="postgresql://postgres:postgres@localhost:15432/inventory_service".
```

The app start to come up after installing dependencies and running it.

```
poetry install
uvicorn app.main:app --host localhost --port 8001 --reload
```

After the server starts and runs the migrations I ran the seed script manually in a python interpreter.

Taken from helper.sh:
```python
# create the database connection
from app import main

from app.seed.seed_fake_data import seed_fake_data
seed_fake_data()
```

Very surprisingly this took 10-15 minutes to finish running.
There are also now generated seed files that are not .gitignored.

#### Tying it all together

At this point, I was able to run both the front and back ends and login to FETCH.
Permissions had not been assigned beyond the administrator.
I created some simple permissions groups and assigned permissions to them.
I was then able to perform an accession, verify, and shelf job.
Critically the code running is local and supports hot reload after changes.

## Developer Setup

Now that I've at least run FETCH locally I'm going to go through the rest of the setup instructions.

### fetch-database

> The fetch-local build makes use of the images in this repository via a compose file. Simply running the build from fetch-local will be sufficient for day to day use.

The images in this repository are basically the upstream postgres image with some additional environment variable set.

> Rebuilding the database container and refreshing (wiping) the database can be achieved with the helper scripts also in fetch-local, or from Inventory or Vue apps which also use scripts in fetch-local. Using the scripts in Inventory or Vue apps is the best choice, as those will also take care of rebuilding the schema.

The referenced helper scripts here utilize the fetch-fetch-local compose project (which doesn't work) and podman (which as no installation/configuration instructions).

This project feels superfluous to both the developer experience but also the FETCH project as a whole.

### fetch-vue

#### Quick installation

> You will need podman and brew installed for this version to work on your pc.

Brew is mac specific. This is the first mention of podman I've seen in documentation.

> Head to the fetch-local repo and follow instructions up to the 'run' step to get a fully working FETCH Application.

This has been established to not work well.

#### Manual Installation

There's no mention of nodejs version or how to install npm.
For reference, I dug node version 22 out of the package.json file to install.

> Install the dependencies

This is the only mention of yarn in the entire documentation.
I used npm for this.
Notably in the .npmrc it mentions [pnpm, a fast disk space efficient package manager](https://pnpm.io/) but there is no other reference to pnpm.

> Start the app in your desired development mode

This starts the app!

> Successfully running PWA mode with https via localhost

This gets into the troubles encountered with fetch-local around certs.
There are reasonably good recommendations here around mkcert but it is a tool I've used before and understand.
Critically though, this documentation isn't relevant anymore.
Somehow the code to use the mkcert generated certs was commented out in quasar.local.conf and had to be restored to work.

Running chrome without checking certs also works but is quite kludgy.
It's unknown if this would actually work in all IT environments.

> Make sure you have pre-commit installed or the auto linting wont work. To install pre-commit run the following

Mac specific instructions and no link to the pre-commit library.
Running these lint instructions does work.

> Run unit tests using the following commands

These commands run out of the box but there are failing tests on the main branch.

> Building and Testing The PWA App On Mobile / Desktop

I was able to build the quasar project.
Running quasar serve requires the @quasar/cli package which was not installed.
After serving the application I could not load the page on desktop.
There is no documentation to setup ngrok and it isn't something I'm familiar with though it appears to be a paid service.

I do not have an android development setup so I was also unable to test on mobile.

### fetch-inventory_service

No python version is given.
I used 3.11.4 from the .python-version file.

> This project's environment and dependencies are managed with Poetry.

The instructions for installing poetry are different than [Poetry's instructions](https://python-poetry.org/docs/main/) for installing Poetry.

> Configure poetry to store .venv inside project structure (this is .gitignored).

This is optional but doesn't harm anything and works.

> First install pyenv, and add it to your PATH

I'm not sure what the purpose of this is as pyenv isn't used in the remainder of the README.
Poetry itself also manages virtual environments.
I did not install pyenv as I use another tool for virtual environments.

> Now create a local virtual environment.
> Activate the environment and verify everything looks right.

All python dependencies installed.

> ./helper.sh build local
> ./helper.sh build-db - Rebuilds the inventory-database container.
> ./helper.sh rebuild-db - Wipes the inventory-database volume and re-seeds fake data.

These basically ignore all setup of poetry/python we just did and builds a container with the inventory_service.

> Editor Configuration

Only PyCharm and VSCode are mentioned.
This is probably fine as they are the most common and anyone not using them probably has their own setup.
I did not attempt to follow them as I use a different editor.
I was able to setup formatting/linting/language features for this project.
Interestingly the two ide setups install different packages? One uses yapf and the other uses isort?

There's no mention of pre-commit setup like in the vue repository.
The .pre-commit-config.yaml file has mypy and flake8 which are not installed or configured anywhere.
Running

There's no mention of how to run the tests.
Running `python -m pytest` results in a lot of test failures and it takes a very long time to run.
Interestingly, they assume the user has the docker executable installed.
