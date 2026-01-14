# Design

Local and Kubernetes deployments might work for the contracting agency that build FETCH.
They do not work outside of the LoC or agency environment and it is unclear how it could possibly work even inside.

Fortunately, it is easy to host FETCH on a single server using docker-compose and caddy.
Because FETCH is using industry standard technologies running it locally using fastapi and quasar is also easy.

## Table of Contents

* [Running Locally](./developer_setup.md)
* [Deploying to a single server](./server.md)
* [Deploying to Kubernetes](./kubernetes.md.md)
