# Deploying FETCH to Kubernetes

# Prerequisites

See [the single server prerequisites](./server.md) for comments on the prerequisites.

# Notes

See [the single server notes](./server.md) for comments on the Inventory Service dockerfiles.


# Issues
No automation, just the most bare bones of kubernetes primitives.

Would expect a helm release such as [bitwarden](https://bitwarden.com/help/self-host-with-helm).

There does seem to be some automation around creating a k8s cluster and haproxy but no documentation and it is not enterprise grade.
Note, k8s is being held to a higher standard than single server deployments.

There's no mention of the database in a k8s setup or how to connect to it.

SSL is externally provisioned rather than automatically.

The inventory service is utilizing a kubernetes technology called NodePorts.
This is generally not recommended for production applications.

The PWA portion makes even less sense to deploy on Kubernetes than a single server.
It should be deployed using something like Cloudfront and S3.
