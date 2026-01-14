# Deploying FETCH to Kubernetes

After 3 days of trying I was unable to deploy FETCH to k8s.
This is partially due to a skill gap on my part but also due to a lack of documentation/automation in FETCH.
Deploying FETCH to a single server was similarly missing documentation but was simple enough to figure out.
Kubernetes is not simple.

# Prerequisites

See [the single server prerequisites](./server.md) for comments on the prerequisites.

# Notes

See [the single server notes](./server.md) for comments on the Inventory Service dockerfiles.

Overall there isn't a lot to comment on that is k8s specific because there isn't a lot here.

# Issues
There is no high level automation, just the most bare bones of kubernetes primitives.
I would expect a helm release such as [bitwarden](https://bitwarden.com/help/self-host-with-helm).

There does seem to be some automation around creating a k8s cluster and haproxy but no documentation and it is not enterprise grade.
Note, k8s is being held to a higher standards than single server deployments.

There's no mention of the database in a k8s setup or how to connect to it.

The inventory service is utilizing a kubernetes technology called NodePorts.
This is generally not recommended for production applications.

The PWA portion makes even less sense to deploy on Kubernetes than a single server.
It should be deployed using something like Cloudfront and S3.
